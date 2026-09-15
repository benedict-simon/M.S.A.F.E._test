"""Checks whether a photo shows meat at all before it ever reaches
inference.py's fresh/spoiled classifier. That model only has two classes —
"fresh" and "spoiled" — so it will force one of those two labels onto ANY
photo it's given, including a person, a random object, or a logo.

Uses CLIP zero-shot classification instead of training anything of our
own: CLIP is a general-purpose model already pretrained on a huge, varied
set of image/text pairs, so it can compare a photo against plain-language
descriptions ("a photo of meat" vs "a logo or drawing", etc.) without ever
having seen this app's dataset. The model downloads once on first use and
is cached in memory after that (@lru_cache), same pattern as inference.py's
YOLO model.
"""

from functools import lru_cache

import open_clip
import torch
from PIL import Image

# Deliberately does NOT try to distinguish "raw" from "spoiled" here — that
# call belongs to inference.py's actual trained classifier, which is far
# better at it. Asking CLIP to spot only "raw" meat backfired: badly
# discolored/decayed spoiled meat doesn't match "raw uncooked meat" well
# and was getting rejected here before ever reaching the real classifier —
# actively harmful for a food-safety app whose whole job is catching
# spoiled meat. This only needs to answer "is this meat at all?".
#
# The "meat" label is built per-request using the species the user already
# selected on the meat-type screen (see scan.py) rather than a generic "a
# photo of meat" — very tight macro crops of raw meat texture (some of this
# app's own dataset photos are zoomed in enough to lose all recognizable
# shape) were otherwise scoring too low for CLIP to confidently call them
# "meat" at all. "a photo of chicken" scores much better on those than the
# generic phrasing, since we already know it's chicken.
_OTHER_LABELS = [
    "a photo of cooked or prepared food",
    "a photo of a person, animal, or plant",
    "a logo, icon, drawing, or illustration",
    "a photo of an object that is not food",
]
_MEAT_LABEL_INDEX = 0

# Tried splitting "person, animal, or plant" into a dedicated "human skin,
# a hand, an arm, or a face" label to catch skin photos specifically (skin
# tone genuinely resembles raw meat color/texture) — but that stole enough
# probability mass to start falsely rejecting this app's own hardest real
# meat photos (extreme macro crops of chicken skin, which — unsurprisingly
# — also visually resembles skin). Reverted: a food-safety app blocking
# legitimate spoiled-meat detection is worse than occasionally letting a
# hand/skin photo through, which a user will immediately recognize as
# wrong. If you want to revisit this trade-off, the removed label is
# preserved here in this comment for reference.

# Calibrated against this app's own dataset, not guessed: ran all 240
# sampled real photos (40 each of beef/chicken/pork x fresh/spoiled) through
# this gate to measure the actual false-rejection cost of each threshold:
#   0.12 (old): 1.2% of real photos rejected (3/240)
#   0.15:       1.7% (4/240)
#   0.18:       2.9% (7/240)
#   0.20:       3.8% (9/240)
#   0.22:       4.2% (10/240)
#   0.25:       7.1% (17/240)  <- chosen
# 0.25 was picked specifically because a real non-meat photo scanned during
# testing scored 0.22 and was wrongly accepted — needed a threshold above
# that to catch it, accepting the higher false-rejection cost. Some genuine
# beef/chicken photos scored as low as 0.049-0.063 — even lower than a flat
# skin-tone test block that scored 0.14 — so no threshold eliminates false
# accepts on skin/plastic-like objects without cutting into real photos
# too. Pork separates much better (lowest real score 0.246) but beef/
# chicken overlap heavily with non-meat scores. See
# scripts/calibrate_meat_gate.py to re-run this measurement if the model,
# labels, or dataset change.
#
# Known limitation, accepted deliberately: this still won't catch every
# non-meat object — a real plastic object tested across 8 captures scored
# anywhere from 0.06 to 0.25 in earlier testing, and skin tone genuinely
# resembles raw meat color/texture closely enough that no threshold cleanly
# separates them from hard real meat crops. A false-accept result is
# visually obviously wrong to the user, while a false-rejection blocks the
# app's actual safety purpose — so when in doubt this errs toward accepting.
_MIN_MEAT_PROBABILITY = 0.25

# Tried the larger ViT-L-14/openai checkpoint hoping richer features would
# separate human skin from meat texture better — it did (skin dropped to
# ~0.05), but it broke something worse: real beef photos scored 0.02-0.09,
# indistinguishable from random non-meat objects. Beef is a core, common
# case, not an edge case — reverted to ViT-B-32. Swapping models doesn't
# cleanly fix this, it just relocates which case is hard.
_MODEL_NAME = "ViT-B-32"
_PRETRAINED = "openai"


class MeatGateException(Exception):
    pass


@lru_cache(maxsize=1)
def _load_model():
    try:
        model, _, preprocess = open_clip.create_model_and_transforms(
            _MODEL_NAME, pretrained=_PRETRAINED
        )
        tokenizer = open_clip.get_tokenizer(_MODEL_NAME)
    except Exception as e:
        raise MeatGateException(f"Couldn't load the raw-meat check model: {e}") from e
    model.eval()
    return model, preprocess, tokenizer


@lru_cache(maxsize=8)
def _text_features_for(meat_type: str):
    model, _, tokenizer = _load_model()
    labels = [f"a photo of {meat_type}, raw or spoiled", *_OTHER_LABELS]
    text_tokens = tokenizer(labels)
    with torch.no_grad():
        text_features = model.encode_text(text_tokens)
        text_features /= text_features.norm(dim=-1, keepdim=True)
    return text_features


def looks_like_raw_meat(image: Image.Image, meat_type: str = "meat") -> tuple[bool, float]:
    """Returns (is_meat, probability). probability is CLIP's confidence that
    "a photo of {meat_type}, raw or spoiled" best matches this image out of
    the candidate labels — a rough "is this meat at all" sanity check, not
    a freshness judgment (that's inference.py's job)."""
    model, preprocess, _ = _load_model()
    text_features = _text_features_for(meat_type.strip().lower() or "meat")

    image_input = preprocess(image).unsqueeze(0)
    with torch.no_grad():
        image_features = model.encode_image(image_input)
        image_features /= image_features.norm(dim=-1, keepdim=True)
        similarity = (100.0 * image_features @ text_features.T).softmax(dim=-1)

    meat_probability = float(similarity[0][_MEAT_LABEL_INDEX])
    return meat_probability >= _MIN_MEAT_PROBABILITY, meat_probability

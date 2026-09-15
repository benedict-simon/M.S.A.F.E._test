"""Stage 5: evaluate the trained model against the held-out test split.

Runs app/models/yolov8_msafe.pt directly (no HTTP server needed) against every
image in dataset/annotated/test/, which the model never saw during training or
validation. Reports overall and per-species accuracy/precision/recall/F1, plus
a confusion matrix and a list of every misclassified file for manual review.

"Spoiled" is treated as the positive class throughout — this is a food-safety
tool, so a false "Fresh" (a spoiled sample missed) is the failure mode that
actually matters most; see dataset/README.md's class-mapping rationale.

Run from backend/: python scripts/evaluate_model.py
"""

import sys
from collections import defaultdict
from pathlib import Path

from PIL import Image

BACKEND_DIR = Path(__file__).resolve().parent.parent

sys.path.insert(0, str(BACKEND_DIR))

from app.services import inference  # noqa: E402

TEST_DIR = BACKEND_DIR / "dataset" / "annotated" / "test"
CLASSES = ["fresh", "spoiled"]


def species_of(filename: str) -> str:

    return filename.split("_")[0]


def confusion_metrics(tp: int, tn: int, fp: int, fn: int) -> dict:
    total = tp + tn + fp + fn
    accuracy = (tp + tn) / total if total else 0.0
    precision = tp / (tp + fp) if (tp + fp) else 0.0
    recall = tp / (tp + fn) if (tp + fn) else 0.0
    f1 = (2 * precision * recall / (precision + recall)) if (precision + recall) else 0.0
    return {"accuracy": accuracy, "precision": precision, "recall": recall, "f1": f1}


def print_report(label: str, tp: int, tn: int, fp: int, fn: int) -> None:
    total = tp + tn + fp + fn
    m = confusion_metrics(tp, tn, fp, fn)
    print(f"\n--- {label} (n={total}) ---")
    print(f"Accuracy:  {m['accuracy']:.1%}")
    print(f"Precision (spoiled): {m['precision']:.1%}")
    print(f"Recall (spoiled):    {m['recall']:.1%}")
    print(f"F1 (spoiled):        {m['f1']:.1%}")
    print("Confusion matrix (rows = actual, cols = predicted):")
    print(f"                 pred fresh   pred spoiled")
    print(f"  actual fresh   {tn:<12}{fp}")
    print(f"  actual spoiled {fn:<12}{tp}")


def main() -> None:
    if not TEST_DIR.exists():
        print(f"{TEST_DIR} not found — run scripts/build_annotated_split.py first.")
        return

    # Confirms the model actually loads before scanning hundreds of images.
    try:
        inference._load_model()
    except inference.InferenceServiceException as e:
        print(f"Could not load the model: {e}")
        return

    overall = {"tp": 0, "tn": 0, "fp": 0, "fn": 0}
    per_species = defaultdict(lambda: {"tp": 0, "tn": 0, "fp": 0, "fn": 0})
    misclassified = []

    image_paths = []
    for cls in CLASSES:
        class_dir = TEST_DIR / cls
        if not class_dir.exists():
            continue
        image_paths.extend((p, cls) for p in sorted(class_dir.glob("*")))

    if not image_paths:
        print(f"No test images found under {TEST_DIR}.")
        return

    print(f"Evaluating {len(image_paths)} test images...")
    for i, (path, actual_cls) in enumerate(image_paths, 1):
        actual_spoiled = actual_cls == "spoiled"
        species = species_of(path.name)

        try:
            image = Image.open(path).convert("RGB")
            is_fresh, confidence = inference.classify(image)
        except Exception as e:
            print(f"  [{i}/{len(image_paths)}] SKIPPED {path.name}: {e}")
            continue

        predicted_spoiled = not is_fresh

        bucket = "tp" if actual_spoiled and predicted_spoiled else \
            "tn" if not actual_spoiled and not predicted_spoiled else \
            "fp" if not actual_spoiled and predicted_spoiled else "fn"

        overall[bucket] += 1
        per_species[species][bucket] += 1

        if predicted_spoiled != actual_spoiled:
            misclassified.append(
                f"{path.relative_to(BACKEND_DIR)} — actual={actual_cls}, "
                f"predicted={'spoiled' if predicted_spoiled else 'fresh'}, confidence={confidence:.1%}"
            )

        if i % 25 == 0 or i == len(image_paths):
            print(f"  [{i}/{len(image_paths)}] processed")

    print_report("OVERALL", **overall)
    for species in sorted(per_species):
        print_report(species.upper(), **per_species[species])

    print(f"\n--- Misclassified images ({len(misclassified)}) ---")
    if misclassified:
        for line in misclassified:
            print(f"  {line}")
    else:
        print("  None — perfect score on the test set.")


if __name__ == "__main__":
    main()

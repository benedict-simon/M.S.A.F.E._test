import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from PIL import Image
from app.services import image_analysis, inference

random.seed(0)
TRAIN_SPOILED = Path(__file__).resolve().parent.parent / "dataset" / "annotated" / "train" / "spoiled"

model = inference._load_model()
print("Model class mapping (model.names):", model.names)

files = [f for f in TRAIN_SPOILED.iterdir() if f.name.startswith("beef_spoiled_")]
files = random.sample(files, min(600, len(files)))
scored = []
for f in files:
    try:
        with Image.open(f) as img:
            img = img.convert("RGB")
            b = image_analysis.analyze_image(img).brightness_pct
            scored.append((b, f))
    except Exception:
        pass
scored.sort(key=lambda x: x[0])

print(f"\nTotal beef_spoiled_* in annotated/train: {len(scored)}")
print("\n=== 15 darkest beef_spoiled_* photos from the ACTUAL training split ===")
wrong = 0
for brightness, f in scored[:15]:
    with Image.open(f) as img:
        img = img.convert("RGB")
        is_fresh, conf = inference.classify(img)
    verdict = "FRESH (WRONG)" if is_fresh else "spoiled (correct)"
    if is_fresh:
        wrong += 1
    print(f"  brightness={brightness:5.1f}%  conf={conf:.2f}  {verdict}  {f.name}")
print(f"\n{wrong}/15 misclassified as Fresh")

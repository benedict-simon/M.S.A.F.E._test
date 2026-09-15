import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from PIL import Image
from app.services import image_analysis, inference

DATASET = Path(__file__).resolve().parent.parent / "dataset" / "raw" / "beef" / "spoiled"

random.seed(0)
files = sorted(DATASET.iterdir())
sample = random.sample(files, min(600, len(files)))

scored = []
for f in sample:
    try:
        with Image.open(f) as img:
            img = img.convert("RGB")
            findings = image_analysis.analyze_image(img)
            scored.append((findings.brightness_pct, f))
    except Exception as e:
        print(f"skip {f.name}: {e}")

scored.sort(key=lambda x: x[0])  # darkest first

print(f"Sampled: {len(scored)} spoiled beef photos")
print("\n=== 20 darkest sampled spoiled beef photos: classifier verdict ===")
wrong = 0
for brightness, f in scored[:20]:
    with Image.open(f) as img:
        img = img.convert("RGB")
        is_fresh, conf = inference.classify(img)
    verdict = "FRESH (WRONG)" if is_fresh else "spoiled (correct)"
    if is_fresh:
        wrong += 1
    print(f"  brightness={brightness:5.1f}%  conf={conf:.2f}  {verdict}  {f.name}")

print(f"\n{wrong}/20 darkest sampled spoiled beef photos misclassified as Fresh")

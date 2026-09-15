import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from PIL import Image
from app.services import meat_gate

random.seed(0)
DATASET = Path(__file__).resolve().parent.parent / "dataset" / "raw"

results = {}
for meat_type in ["beef", "chicken", "pork"]:
    scores = []
    for condition in ["fresh", "spoiled"]:
        folder = DATASET / meat_type / condition
        files = sorted(folder.iterdir())
        sample = random.sample(files, min(40, len(files)))
        for f in sample:
            try:
                img = Image.open(f).convert("RGB")
            except Exception:
                continue
            _, prob = meat_gate.looks_like_raw_meat(img, meat_type=meat_type)
            scores.append((prob, f.name))
    scores.sort()
    results[meat_type] = scores

print("=== Real meat photo probability distribution (lowest 15 per type) ===")
all_scores = []
for meat_type, scores in results.items():
    vals = [s for s, _ in scores]
    all_scores.extend(vals)
    print(f"\n{meat_type}: n={len(vals)} min={min(vals):.3f} p1={sorted(vals)[max(0,len(vals)//100)]:.3f} p5={sorted(vals)[len(vals)//20]:.3f} median={sorted(vals)[len(vals)//2]:.3f}")
    for prob, name in scores[:15]:
        print(f"  {prob:.3f}  {name}")

print(f"\nOverall min across all real meat photos: {min(all_scores):.3f}")
print(f"Overall p1: {sorted(all_scores)[max(0,len(all_scores)//100)]:.3f}")
print(f"How many would be rejected at threshold 0.22: {sum(1 for s in all_scores if s < 0.22)} / {len(all_scores)}")
print(f"How many would be rejected at threshold 0.18: {sum(1 for s in all_scores if s < 0.18)} / {len(all_scores)}")
print(f"How many would be rejected at threshold 0.15: {sum(1 for s in all_scores if s < 0.15)} / {len(all_scores)}")

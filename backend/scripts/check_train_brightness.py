import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from PIL import Image
from app.services import image_analysis

random.seed(0)
TRAIN = Path(__file__).resolve().parent.parent / "dataset" / "annotated" / "train"


def sample_brightness(folder: Path, prefix: str, n: int = 150):
    files = [f for f in folder.iterdir() if f.name.startswith(prefix)]
    sample = random.sample(files, min(n, len(files)))
    vals = []
    for f in sample:
        try:
            with Image.open(f) as img:
                img = img.convert("RGB")
                vals.append(image_analysis.analyze_image(img).brightness_pct)
        except Exception:
            pass
    return vals


for meat in ["beef", "chicken", "pork"]:
    fresh_vals = sample_brightness(TRAIN / "fresh", f"{meat}_fresh_")
    spoiled_vals = sample_brightness(TRAIN / "spoiled", f"{meat}_spoiled_")
    fresh_vals.sort()
    spoiled_vals.sort()
    print(f"\n=== {meat} (train split) ===")
    print(f"fresh   n={len(fresh_vals)}  min={fresh_vals[0]:.1f}  p25={fresh_vals[len(fresh_vals)//4]:.1f}  "
          f"median={fresh_vals[len(fresh_vals)//2]:.1f}  p75={fresh_vals[3*len(fresh_vals)//4]:.1f}  max={fresh_vals[-1]:.1f}")
    print(f"spoiled n={len(spoiled_vals)}  min={spoiled_vals[0]:.1f}  p25={spoiled_vals[len(spoiled_vals)//4]:.1f}  "
          f"median={spoiled_vals[len(spoiled_vals)//2]:.1f}  p75={spoiled_vals[3*len(spoiled_vals)//4]:.1f}  max={spoiled_vals[-1]:.1f}")
    dark_fresh = sum(1 for v in fresh_vals if v < 45)
    dark_spoiled = sum(1 for v in spoiled_vals if v < 45)
    print(f"photos with brightness<45%: fresh={dark_fresh}/{len(fresh_vals)}  spoiled={dark_spoiled}/{len(spoiled_vals)}")

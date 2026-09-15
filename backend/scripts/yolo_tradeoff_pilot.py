"""Empirical pilot comparison for the YOLO version trade-off (see the
manuscript's "YOLO Version Selection for Classification-Based Freshness
Detection" section).

For each candidate classification checkpoint, this script measures the same
three metrics used in the quantitative trade-off:

  - Accuracy   -- Top-1 classification accuracy on a held-out validation
                  subset of M.S.A.F.E.'s own dataset (not ImageNet).
  - Parameters -- parameter count of the loaded model, in millions.
  - Speed      -- inference time per image (ms), measured during validation.

This is a PILOT run, not full-scale training: it fine-tunes each pretrained
checkpoint on a small, balanced subset (default 1,000 images/class train,
200 images/class val) for a small number of epochs, so it completes in
reasonable time on CPU. The point is to check whether the pattern seen in
Ultralytics' published ImageNet benchmarks (Table 12.1) also holds on
M.S.A.F.E.'s own meat freshness photos specifically -- not to replace the
full training pipeline in notebooks/train_yolov8_colab.ipynb.

Limitation: YOLOv5s-cls is NOT included here. Its classification checkpoint
was trained under the old standalone `yolov5` repo and is not loadable by
the modern `ultralytics` package this project (and this script) depends on
-- loading it raises "NOT forwards compatible with YOLOv8". Getting a real
YOLOv5-cls number requires a separate environment running the legacy
https://github.com/ultralytics/yolov5 repo's own classify/train.py.

Run from backend/: python scripts/yolo_tradeoff_pilot.py
"""

import json
import random
import shutil
import time
from pathlib import Path

from ultralytics import YOLO

BACKEND_DIR = Path(__file__).resolve().parent.parent
TRAIN_SRC = BACKEND_DIR / "dataset" / "augmented" / "train"
VAL_SRC = BACKEND_DIR / "dataset" / "annotated" / "val"
PILOT_DIR = BACKEND_DIR / "dataset" / "_yolo_tradeoff_pilot"  # scratch, gitignored
RESULTS_FILE = BACKEND_DIR / "scripts" / "yolo_tradeoff_pilot_results.json"

CANDIDATES = ["yolov8s-cls.pt", "yolo11s-cls.pt"]
CLASSES = ["fresh", "spoiled"]

N_TRAIN_PER_CLASS = 1000
N_VAL_PER_CLASS = 200
EPOCHS = 5
IMGSZ = 128
BATCH = 32
SEED = 42


def build_pilot_subset() -> Path:
    """Copies a balanced random subset of the real dataset into an
    ImageFolder-style train/val layout that Ultralytics classification
    training expects."""
    rng = random.Random(SEED)
    if PILOT_DIR.exists():
        shutil.rmtree(PILOT_DIR)

    for split, src_root, n_per_class in [
        ("train", TRAIN_SRC, N_TRAIN_PER_CLASS),
        ("val", VAL_SRC, N_VAL_PER_CLASS),
    ]:
        for cls in CLASSES:
            src_dir = src_root / cls
            dest_dir = PILOT_DIR / split / cls
            dest_dir.mkdir(parents=True, exist_ok=True)
            files = list(src_dir.iterdir())
            chosen = rng.sample(files, min(n_per_class, len(files)))
            for f in chosen:
                shutil.copy2(f, dest_dir / f.name)
    return PILOT_DIR


def evaluate_candidate(checkpoint: str, data_root: Path) -> dict:
    model = YOLO(checkpoint)

    t0 = time.time()
    model.train(
        data=str(data_root),
        epochs=EPOCHS,
        imgsz=IMGSZ,
        batch=BATCH,
        workers=2,
        cache=False,
        patience=0,
        plots=False,
        verbose=False,
        exist_ok=True,
        project=str(BACKEND_DIR / "scripts" / "_pilot_runs"),
        name=checkpoint.replace(".pt", ""),
    )
    train_time_sec = time.time() - t0

    n_val_images = sum(1 for _ in (data_root / "val").rglob("*") if _.is_file())

    t1 = time.time()
    val = model.val(data=str(data_root), imgsz=IMGSZ, split="val", verbose=False)
    val_time_sec = time.time() - t1

    n_params_m = sum(p.numel() for p in model.model.parameters()) / 1e6

    return {
        "top1_accuracy_pct": round(float(val.top1) * 100, 2),
        "top5_accuracy_pct": round(float(val.top5) * 100, 2),
        "parameters_M": round(n_params_m, 2),
        "train_time_sec": round(train_time_sec, 1),
        "inference_speed_ms_per_image": round((val_time_sec / n_val_images) * 1000, 2),
    }


def main() -> None:
    data_root = build_pilot_subset()
    print(f"Pilot dataset built at {data_root} "
          f"({N_TRAIN_PER_CLASS}/class train, {N_VAL_PER_CLASS}/class val)")

    results = {}
    for checkpoint in CANDIDATES:
        print(f"\n=== {checkpoint} ===")
        results[checkpoint] = evaluate_candidate(checkpoint, data_root)
        print(json.dumps(results[checkpoint], indent=2))

    RESULTS_FILE.write_text(json.dumps(results, indent=2))
    print(f"\nSaved results to {RESULTS_FILE}")


if __name__ == "__main__":
    main()

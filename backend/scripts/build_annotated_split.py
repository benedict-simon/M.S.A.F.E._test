"""Stage 2: split dataset/raw/ into train/val/test in YOLOv8 classification format.

Input:  dataset/raw/<species>/<fresh|spoiled>/*.jpg
Output: dataset/annotated/<train|val|test>/<fresh|spoiled>/*.jpg

Species folders are combined into one Fresh/Spoiled classifier — the app already
knows the meat type from the user's screen selection before a scan, so the model
only needs to answer fresh-or-spoiled. Splitting is stratified per (species, class)
pair so each split keeps roughly the same species/class balance as the whole set,
rather than e.g. test ending up mostly beef by chance.

Run from backend/: python scripts/build_annotated_split.py
"""

import random
import shutil
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = BACKEND_DIR / "dataset" / "raw"
ANNOTATED_DIR = BACKEND_DIR / "dataset" / "annotated"

TRAIN_RATIO = 0.80
VAL_RATIO = 0.10
# Remainder (0.10) goes to test.

SEED = 42
CLASSES = ["fresh", "spoiled"]


def species_folders() -> list[Path]:
    if not RAW_DIR.exists():
        return []
    return [p for p in RAW_DIR.iterdir() if p.is_dir()]


def main() -> None:
    species_dirs = species_folders()
    if not species_dirs:
        print("dataset/raw/ is empty — run scripts/prepare_dataset.py first.")
        return

    rng = random.Random(SEED)
    for split in ("train", "val", "test"):
        for cls in CLASSES:
            (ANNOTATED_DIR / split / cls).mkdir(parents=True, exist_ok=True)

    counts = {"train": 0, "val": 0, "test": 0}
    for species_dir in species_dirs:
        for cls in CLASSES:
            class_dir = species_dir / cls
            if not class_dir.exists():
                continue
            images = sorted(class_dir.glob("*"))
            rng.shuffle(images)

            n = len(images)
            n_train = int(n * TRAIN_RATIO)
            n_val = int(n * VAL_RATIO)
            split_images = {
                "train": images[:n_train],
                "val": images[n_train : n_train + n_val],
                "test": images[n_train + n_val :],
            }

            for split, imgs in split_images.items():
                for img in imgs:
                    dest = ANNOTATED_DIR / split / cls / f"{species_dir.name}_{img.name}"
                    shutil.copy2(img, dest)
                    counts[split] += 1

    print(f"train: {counts['train']} images")
    print(f"val:   {counts['val']} images")
    print(f"test:  {counts['test']} images")
    print("\nWritten to dataset/annotated/. Next: python scripts/augment_dataset.py")


if __name__ == "__main__":
    main()

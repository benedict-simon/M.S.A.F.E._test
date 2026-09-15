"""Stage 3: augment the training split with Albumentations.

Input:  dataset/annotated/train/<fresh|spoiled>/*.jpg
Output: dataset/augmented/train/<fresh|spoiled>/*.jpg  (originals + variants)

Only the training split is touched — val/test must stay exactly as
build_annotated_split.py produced them, or the model would effectively be
evaluated on images it was partly trained on.

Color is deliberately NOT scrambled here. Discoloration is one of the actual
spoilage cues this model needs to learn (that's the whole point of a visual
freshness classifier) — an aggressive hue/color-shift augmentation would teach
the model to distrust the one signal it most needs to trust. Augmentations here
are geometric (flip/rotate/crop) and lighting/camera-quality only (brightness,
contrast, blur, noise) to simulate different phones and lighting conditions
without touching what a "fresh" or "spoiled" color actually looks like.

Run from backend/: python scripts/augment_dataset.py
"""

import shutil
from pathlib import Path

import albumentations as A
import cv2

BACKEND_DIR = Path(__file__).resolve().parent.parent
ANNOTATED_DIR = BACKEND_DIR / "dataset" / "annotated"
AUGMENTED_DIR = BACKEND_DIR / "dataset" / "augmented"

CLASSES = ["fresh", "spoiled"]
VARIANTS_PER_IMAGE = 4
SEED = 42

transform = A.Compose(
    [
        A.HorizontalFlip(p=0.5),
        A.VerticalFlip(p=0.2),
        A.Rotate(limit=25, border_mode=cv2.BORDER_REFLECT_101, p=0.6),
        A.RandomResizedCrop(size=(640, 640), scale=(0.8, 1.0), p=0.5),
        # Lighting/camera variation only — no HueSaturationValue or RGBShift.
        A.RandomBrightnessContrast(brightness_limit=0.2, contrast_limit=0.2, p=0.6),
        A.GaussianBlur(blur_limit=(3, 5), p=0.15),
        A.GaussNoise(std_range=(0.02, 0.08), p=0.15),
    ],
    seed=SEED,
)


def augment_class(cls: str) -> tuple[int, int]:
    src_dir = ANNOTATED_DIR / "train" / cls
    dest_dir = AUGMENTED_DIR / "train" / cls
    dest_dir.mkdir(parents=True, exist_ok=True)

    if not src_dir.exists():
        return 0, 0

    originals = 0
    variants = 0
    for img_path in sorted(src_dir.iterdir()):
        if not img_path.is_file():
            continue

        # Keep the original alongside its augmented variants.
        shutil.copy2(img_path, dest_dir / img_path.name)
        originals += 1

        image = cv2.imread(str(img_path))
        if image is None:
            print(f"  ! skipped unreadable image: {img_path.name}")
            continue
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

        stem = img_path.stem
        suffix = img_path.suffix
        for i in range(VARIANTS_PER_IMAGE):
            augmented = transform(image=image)["image"]
            out_path = dest_dir / f"{stem}_aug{i}{suffix}"
            cv2.imwrite(str(out_path), cv2.cvtColor(augmented, cv2.COLOR_RGB2BGR))
            variants += 1

    return originals, variants


def main() -> None:
    if not (ANNOTATED_DIR / "train").exists():
        print("dataset/annotated/train/ not found — run scripts/build_annotated_split.py first.")
        return

    total_originals = 0
    total_variants = 0
    for cls in CLASSES:
        print(f"Augmenting {cls}...")
        originals, variants = augment_class(cls)
        total_originals += originals
        total_variants += variants
        print(f"  {originals} originals -> {originals + variants} total images")

    print(f"\ndataset/augmented/train: {total_originals} originals + {total_variants} augmented variants")
    print("val/test were left untouched in dataset/annotated/ — train against all three for YOLOv8.")


if __name__ == "__main__":
    main()

"""Stage 1: normalize the three downloaded Kaggle datasets into one layout.

Input:  dataset/sources/<beef|pork|chicken>/... (whatever folder structure
        each source ships with — see dataset/README.md for download instructions)
Output: dataset/raw/<species>/<fresh|spoiled>/*.jpg

Run from backend/: python scripts/prepare_dataset.py
"""

import re
import shutil
import sys
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parent.parent
SOURCES_DIR = BACKEND_DIR / "dataset" / "sources"
RAW_DIR = BACKEND_DIR / "dataset" / "raw"

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}

HALF_FRESH_MAPS_TO = "spoiled"

CLASS_ALIASES = {
    "fresh": "fresh",
    "segar": "fresh",
    "half-fresh": HALF_FRESH_MAPS_TO,
    "half_fresh": HALF_FRESH_MAPS_TO,
    "halffresh": HALF_FRESH_MAPS_TO,
    "medium": HALF_FRESH_MAPS_TO,
    "spoiled": "spoiled",
    "rotten": "spoiled",
    "stale": "spoiled",
    "bad": "spoiled",
    "busuk": "spoiled",
}

SPECIES_FOLDERS = ["beef", "pork", "chicken"]

SKIP_PATH_SUBSTRINGS = ["200x200", "300x300"]

FILENAME_PREFIX_RE = re.compile(r"^([A-Za-z]+(?:[-_][A-Za-z]+)*)[-_]\d")


def normalize_class_name(name: str) -> str | None:
    key = name.strip().lower().replace(" ", "_")
    return CLASS_ALIASES.get(key)


def classify_images(source_root: Path) -> dict[str, list[Path]]:
    """Returns {class: [image_path, ...]} for every recognizable image under
    source_root. Classifies primarily by the image's parent folder name
    (most sources); if that isn't a recognizable class name, falls back to a
    class prefix embedded in the filename itself — this is what makes flat
    Roboflow "multiclass" exports (FRESH-1-...jpg, HALF-FRESH-2-...jpg, no
    class folders at all) and mixed folders (.../busuk_segar/busuk_0001.jpg)
    work without a per-source special case."""
    found: dict[str, list[Path]] = {}
    for img in source_root.rglob("*"):
        if not img.is_file() or img.suffix.lower() not in IMAGE_EXTENSIONS:
            continue
        if any(skip in str(img) for skip in SKIP_PATH_SUBSTRINGS):
            continue

        mapped = normalize_class_name(img.parent.name)
        if mapped is None:
            match = FILENAME_PREFIX_RE.match(img.stem)
            prefix = match.group(1) if match else img.stem
            mapped = normalize_class_name(prefix)
        if mapped is not None:
            found.setdefault(mapped, []).append(img)

    return found


def copy_species(species: str) -> int:
    source_root = SOURCES_DIR / species
    if not source_root.exists():
        print(f"  skip {species}: dataset/sources/{species}/ not found")
        return 0

    classified = classify_images(source_root)
    if not classified:
        print(f"  ! {species}: no recognizable fresh/spoiled images under dataset/sources/{species}/")
        print("    Check the actual folder/file names and add aliases to CLASS_ALIASES if needed.")
        return 0

    copied = 0
    for cls, images in classified.items():
        dest = RAW_DIR / species / cls
        dest.mkdir(parents=True, exist_ok=True)
        for i, img in enumerate(sorted(images)):
            shutil.copy2(img, dest / f"{species}_{i:05d}{img.suffix.lower()}")
            copied += 1
        print(f"  {species}/{cls}: {len(images)} images")

    return copied


def main() -> None:
    if not SOURCES_DIR.exists():
        print("dataset/sources/ not found — download the sources listed in dataset/README.md first.")
        sys.exit(1)

    RAW_DIR.mkdir(parents=True, exist_ok=True)

    total = 0
    for species in SPECIES_FOLDERS:
        print(f"Processing {species}...")
        total += copy_species(species)

    print(f"\nDone — {total} images normalized into dataset/raw/")
    if total == 0:
        print("Nothing was copied. Check that dataset/sources/<species>/ exists and contains class folders.")


if __name__ == "__main__":
    main()

# M.S.A.F.E. Training Dataset Pipeline

Combines three Kaggle datasets into one Fresh/Spoiled dataset covering chicken,
pork, and beef, then augments it for YOLOv8 training.

No single public dataset covers all three species with a clean Fresh/Spoiled split,
so this pipeline stitches together sources that don't agree on classes. Read the
**class mapping** section before running anything — it documents a judgment call
that directly affects what the model learns.

## Contents

1. [Download the sources](#1-download-the-sources)
2. [Class mapping — read this before running anything](#2-class-mapping--read-this-before-running-anything)
3. [Run the pipeline](#3-run-the-pipeline)
4. [Notes: where Label Studio fits](#notes-where-label-studio-fits)

## 1. Download the sources

All three need only a free Kaggle account and API key (`~/.kaggle/kaggle.json` —
see kaggle.com/settings). Never commit that key.

| Species | Kaggle Dataset                                               | Classes                      | Notes                                    |
|---------|--------------------------------------------------------------|------------------------------|------------------------------------------|
| Chicken | [calvinsama/fresh-and-rotten-poultry-meat-datasets][chicken] | Fresh / Spoiled              | Chicken-specific, verified               |
| Pork    | [vinayakshanawad/meat-freshness-image-dataset][pork]         | Fresh / Half-Fresh / Spoiled | Species not confirmed¹                   |
| Beef    | [mexwell/locbeef-beef-quality-image-dataset][beef]           | Fresh / Rotten               | Beef-specific, verified, already 2-class |

[chicken]: https://www.kaggle.com/datasets/calvinsama/fresh-and-rotten-poultry-meat-datasets
[pork]: https://www.kaggle.com/datasets/vinayakshanawad/meat-freshness-image-dataset
[beef]: https://www.kaggle.com/datasets/mexwell/locbeef-beef-quality-image-dataset

¹ **Species not confirmed from the listing** — verify the actual images are pork once downloaded
before trusting this as pork coverage; the dataset's public description doesn't state species clearly.

```bash
kaggle datasets download -d calvinsama/fresh-and-rotten-poultry-meat-datasets -p dataset/sources/chicken --unzip
kaggle datasets download -d vinayakshanawad/meat-freshness-image-dataset -p dataset/sources/pork --unzip
kaggle datasets download -d mexwell/locbeef-beef-quality-image-dataset -p dataset/sources/beef --unzip
```

## 2. Class mapping — read this before running anything

The app scope is binary: **Fresh** or **Spoiled**. The pork source uses a third
"Half-Fresh" class that the other two don't have. This pipeline maps
`Half-Fresh → Spoiled`, not `Half-Fresh → Fresh`.

**Why:** this is a food-safety tool. A false "Fresh" on meat that's actually
starting to turn is the worse failure mode than an over-cautious "Spoiled" on meat
that's still borderline-fine. When in doubt, the model should err toward flagging,
not clearing.

If you disagree with this policy, change `HALF_FRESH_MAPS_TO` in
`scripts/prepare_dataset.py` before running it — don't hand-edit the output, since
re-running the script will overwrite it.

## 3. Run the pipeline

```bash
cd backend
pip install -r requirements.txt

# Stage 1: normalize all sources into dataset/raw/<species>/<class>/
python scripts/prepare_dataset.py

# Stage 2: split into train/val/test and lay out in YOLO classification format
python scripts/build_annotated_split.py

# Stage 3: augment the training split only (val/test must stay untouched —
# augmenting them would let the model "cheat" on evaluation)
python scripts/augment_dataset.py
```

Resulting layout:

```
dataset/
  sources/     # what you downloaded — gitignored, never committed
  raw/         # stage 1 output: <species>/<class>/*.jpg, normalized, unsplit
  annotated/   # stage 2 output: train/val/test split, YOLO classification format
  augmented/   # stage 3 output: annotated/train + Albumentations variants
```

`dataset/augmented/train` + `dataset/annotated/val` + `dataset/annotated/test` is
what `notebooks/train_yolov8_colab.ipynb` trains against.

## Notes: where Label Studio fits

These three sources already come pre-labeled, so Label Studio isn't needed for this
initial batch — it's for later, when you add your own photographed pork/beef/chicken
to improve on whatever gap this bootstrap dataset leaves (e.g. Philippine wet-market
conditions specifically, which none of these sources were shot in). When that time
comes, export new annotations from Label Studio in YOLO format directly into
`dataset/raw/<species>/<class>/` and re-run stages 2–3.

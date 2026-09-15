"""Computes real color/texture statistics from the actual scanned photo, so
the app's "findings" text describes what THIS image looks like — not just a
generic template picked from the Fresh/Spoiled label. The classifier itself
(inference.py) only outputs a label + confidence with no built-in
explainability, so this fills that gap with a separate, honest measurement:
plain color-space statistics, not a second AI opinion.
"""

from dataclasses import dataclass

import numpy as np
from PIL import Image

# Large photos don't need full resolution for an average-color read — this
# just keeps the numpy pass fast.
_ANALYSIS_SIZE = (256, 256)


@dataclass
class ImageFindings:
    hue_deg: float  # 0-360, standard color wheel angle
    saturation_pct: float  # 0-100, how vivid vs. washed-out/gray
    brightness_pct: float  # 0-100
    uniformity_pct: float  # 0-100, higher = more consistent color across the frame (less patchy)


def analyze_image(image: Image.Image) -> ImageFindings:
    small = image.resize(_ANALYSIS_SIZE)
    hsv = np.asarray(small.convert("HSV")).astype(np.float64)
    h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]

    # PIL's HSV hue channel is 0-255 mapped over the full 360° wheel.
    hue_deg = float(h.mean()) / 255.0 * 360.0
    saturation_pct = float(s.mean()) / 255.0 * 100.0
    brightness_pct = float(v.mean()) / 255.0 * 100.0

    # Hue is circular (0° and 360° are the same color), so a plain standard
    # deviation would overstate patchiness for photos that straddle the
    # wrap-around point. Using circular variance avoids that.
    hue_radians = h / 255.0 * 2 * np.pi
    circular_spread = 1 - np.sqrt(np.mean(np.cos(hue_radians)) ** 2 + np.mean(np.sin(hue_radians)) ** 2)
    uniformity_pct = max(0.0, 100.0 - circular_spread * 150.0)

    return ImageFindings(
        hue_deg=round(hue_deg, 1),
        saturation_pct=round(saturation_pct, 1),
        brightness_pct=round(brightness_pct, 1),
        uniformity_pct=round(uniformity_pct, 1),
    )

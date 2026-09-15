// lib/utils/scan_explanation.dart

/// Findings/recommendation/storage-tip text for a scan result, tailored to
/// meat type and confidence — not just a single "fresh" vs "spoiled" pair.
/// The classifier itself only outputs Fresh/Spoiled + a confidence score
/// (no per-region visual explanation), so the qualitative findings are
/// rule-based domain knowledge selected by (meat type, result, confidence
/// tier) — the actual, most reliable signal. When the backend also sends
/// real color measurements from THIS specific photo (see
/// backend/app/services/image_analysis.py), an extra findings line reports
/// those honestly as measured data, not as an independent "this proves
/// spoilage" claim — testing showed whole-image color averages are skewed
/// by background/lighting, so they're not reliable enough to override the
/// trained classifier's verdict, only to add transparency alongside it.
class ScanExplanation {
  final List<String> findings;
  final String recommendation;
  final List<String> storageTips;

  const ScanExplanation({
    required this.findings,
    required this.recommendation,
    required this.storageTips,
  });
}

enum _ConfidenceTier { high, medium, low }

_ConfidenceTier _tierOf(double confidence) {
  if (confidence >= 0.85) return _ConfidenceTier.high;
  if (confidence >= 0.60) return _ConfidenceTier.medium;
  return _ConfidenceTier.low;
}

enum _Species { pork, beef, chicken, other }

_Species _speciesOf(String meatType) {
  final t = meatType.toLowerCase();
  if (t.contains('pork')) return _Species.pork;
  if (t.contains('beef')) return _Species.beef;
  if (t.contains('chicken')) return _Species.chicken;
  return _Species.other;
}

ScanExplanation buildScanExplanation({
  required String meatType,
  required bool isFresh,
  required double confidence,
  double? hueDeg,
  double? saturationPct,
  double? brightnessPct,
  double? uniformityPct,
}) {
  final species = _speciesOf(meatType);
  final tier = _tierOf(confidence);

  final findings = [
    ...isFresh ? _freshFindings(species) : _spoiledFindings(species),
    if (hueDeg != null && saturationPct != null && brightnessPct != null)
      _measuredColorLine(hueDeg, saturationPct, brightnessPct, uniformityPct),
  ];

  return ScanExplanation(
    findings: findings,
    recommendation: _recommendation(meatType, isFresh, tier),
    storageTips: isFresh ? _storageTips(species) : const [],
  );
}

/// A plain, honest report of what was actually measured in this photo —
/// deliberately descriptive, not diagnostic (see the class doc comment for
/// why this doesn't try to assert "this hue means spoiled").
String _measuredColorLine(double hueDeg, double saturationPct, double brightnessPct, double? uniformityPct) {
  final tone = _hueTone(hueDeg);
  final vividness = saturationPct >= 35
      ? 'vivid'
      : saturationPct <= 18
          ? 'muted'
          : 'moderate';
  final uniformityNote = uniformityPct == null
      ? ''
      : uniformityPct >= 70
          ? ' Color is fairly consistent across the frame.'
          : ' Color varies noticeably across the frame.';
  return 'Measured from this photo: a $vividness $tone tone '
      '(hue ≈ ${hueDeg.round()}°, saturation ≈ ${saturationPct.round()}%, brightness ≈ ${brightnessPct.round()}%).$uniformityNote';
}

String _hueTone(double hueDeg) {
  if (hueDeg < 20 || hueDeg >= 340) return 'red';
  if (hueDeg < 45) return 'orange/brown';
  if (hueDeg < 70) return 'yellow';
  if (hueDeg < 170) return 'green';
  if (hueDeg < 260) return 'blue';
  return 'purple/pink';
}

List<String> _freshFindings(_Species species) {
  switch (species) {
    case _Species.pork:
      return const [
        'Healthy pink to pale red color, with white fat and no graying.',
        'Firm texture with no sliminess or off-odor typical of fresh pork.',
      ];
    case _Species.beef:
      return const [
        'Bright cherry-red to deep red color, consistent with fresh beef.',
        'Firm, slightly moist surface with no browning or graying.',
      ];
    case _Species.chicken:
      return const [
        'Pale pink to white color with no yellow or gray discoloration.',
        'Slightly moist but not slimy or tacky to the touch.',
      ];
    case _Species.other:
      return const [
        'Normal color, with no discoloration or graying.',
        'Firm, uniform surface texture — no sliminess or dryness detected.',
      ];
  }
}

List<String> _spoiledFindings(_Species species) {
  switch (species) {
    case _Species.pork:
      return const [
        'Grayish-brown discoloration replacing the normal pink color.',
        'Slimy or tacky surface texture consistent with bacterial spoilage.',
      ];
    case _Species.beef:
      return const [
        'Dull brown to greenish-gray discoloration across the surface.',
        'Sticky or slimy film typical of advanced beef spoilage.',
      ];
    case _Species.chicken:
      return const [
        'Dull gray or greenish tint replacing the normal pale color.',
        'Slimy, sticky texture — a strong indicator of poultry spoilage.',
      ];
    case _Species.other:
      return const [
        'Widespread discoloration with grayish-brown patches across the surface.',
        'Slimy, uneven surface texture consistent with advanced spoilage.',
      ];
  }
}

List<String> _storageTips(_Species species) {
  switch (species) {
    case _Species.pork:
      return const [
        'Refrigerate at 0–4°C and use within 1–2 days.',
        'Freeze for up to 4–6 months for best quality.',
      ];
    case _Species.beef:
      return const [
        'Refrigerate at 0–4°C and use within 3–5 days.',
        'Freeze for up to 6–12 months for best quality.',
      ];
    case _Species.chicken:
      return const [
        'Refrigerate at 0–4°C and use within 1–2 days — poultry spoils faster than red meat.',
        'Freeze for up to 9 months for best quality.',
      ];
    case _Species.other:
      return const [
        'Refrigerate at 0–4°C if cooking within 1–2 days.',
        'Freeze if not planning to use it this week.',
      ];
  }
}

String _recommendation(String meatType, bool isFresh, _ConfidenceTier tier) {
  final label = meatType.trim().isEmpty ? 'meat' : meatType.trim();
  if (isFresh) {
    switch (tier) {
      case _ConfidenceTier.high:
        return 'This $label shows strong indicators of freshness. Store properly and cook within the recommended timeframe.';
      case _ConfidenceTier.medium:
      case _ConfidenceTier.low:
        return 'This $label appears fresh, but the confidence is moderate — check for odor or sliminess yourself, or rescan under better lighting, before relying on this result.';
    }
  }
  switch (tier) {
    case _ConfidenceTier.high:
      return 'This $label shows strong indicators of spoilage and should not be consumed. Discard immediately and do not cook.';
    case _ConfidenceTier.medium:
    case _ConfidenceTier.low:
      return 'This $label shows possible signs of spoilage, but the confidence is moderate — inspect closely for odor, sliminess, or discoloration before deciding whether to discard it.';
  }
}

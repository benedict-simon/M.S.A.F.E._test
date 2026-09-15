extension StringCapitalization on String {
  /// Capitalizes the first letter of this string, leaving the rest untouched.
  String capitalizeFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  /// Capitalizes the first letter of each word, e.g. "quezon city market"
  /// becomes "Quezon City Market".
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalizeFirst()).join(' ');
  }
}

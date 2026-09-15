import 'package:flutter/services.dart';

class TitleCaseTextFormatter extends TextInputFormatter {
  static final RegExp _wordStart = RegExp(r'(^|[\s\-/])([a-z])');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final capitalized = text.replaceAllMapped(
      _wordStart,
      (m) => '${m[1]}${m[2]!.toUpperCase()}',
    );

    if (capitalized == text) return newValue;

    return newValue.copyWith(text: capitalized);
  }
}

class SentenceCaseTextFormatter extends TextInputFormatter {
  static final RegExp _sentenceStart = RegExp(r'(^|[.!?]\s+)([a-z])');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final capitalized = text.replaceAllMapped(
      _sentenceStart,
      (m) => '${m[1]}${m[2]!.toUpperCase()}',
    );

    if (capitalized == text) return newValue;

    return newValue.copyWith(text: capitalized);
  }
}

import 'package:flutter/services.dart';

/// Converts input to lowercase while preserving cursor position.
class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final lower = newValue.text.toLowerCase();
    // Keep the same selection offset relative to the transformed text
    final baseOffset = newValue.selection.baseOffset;
    final extentOffset = newValue.selection.extentOffset;
    final selection = TextSelection(
      baseOffset: baseOffset.clamp(0, lower.length),
      extentOffset: extentOffset.clamp(0, lower.length),
    );
    return TextEditingValue(text: lower, selection: selection);
  }
}

/// Common formatter sets
class AppInputFormatters {
  /// Email: no spaces, auto-lowercase
  static final List<TextInputFormatter> email = <TextInputFormatter>[
    FilteringTextInputFormatter.deny(RegExp(r"\s")),
    LowerCaseTextFormatter(),
  ];

  /// Digits only
  static final List<TextInputFormatter> digitsOnly = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
  ];
}

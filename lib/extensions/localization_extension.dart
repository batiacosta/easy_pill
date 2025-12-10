import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/localization_provider.dart';

extension LocalizationExtension on BuildContext {
  // Simple shorthand: context.tr('key')
  String tr(String key, [Map<String, String>? params]) {
    return watch<LocalizationProvider>().tr(key, params);
  }
}

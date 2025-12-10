import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/localization_provider.dart';

extension LocalizationExtension on BuildContext {
  // Use in build methods (will rebuild on language change)
  String tr(String key, [Map<String, String>? params]) {
    return watch<LocalizationProvider>().tr(key, params);
  }

  // Use in event handlers like onPressed, callbacks, etc. (won't rebuild)
  String trStatic(String key, [Map<String, String>? params]) {
    return read<LocalizationProvider>().tr(key, params);
  }
}

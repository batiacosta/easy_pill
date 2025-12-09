import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'localization_provider.dart';

extension LocalizationExtension on BuildContext {
  LocalizationProvider get localization =>
      read<LocalizationProvider>();

  String getString(String key) =>
      read<LocalizationProvider>().getString(key);

  String getStringWithParams(String key, Map<String, String> params) =>
      read<LocalizationProvider>().getStringWithParams(key, params);
}

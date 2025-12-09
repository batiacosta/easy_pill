import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

class LocalizationProvider with ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  void setLocale(Locale newLocale) {
    if (!AppLocalization.supportedLocales.contains(newLocale)) {
      return;
    }
    _locale = newLocale;
    notifyListeners();
  }

  void setLanguageCode(String languageCode) {
    setLocale(AppLocalization.getLocaleFromLanguageCode(languageCode));
  }

  String getString(String key) {
    return AppStrings.get(key, languageCode: languageCode);
  }

  String getStringWithParams(String key, Map<String, String> params) {
    return AppStrings.getWithParams(key,
        params: params, languageCode: languageCode);
  }
}

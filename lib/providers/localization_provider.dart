import 'package:flutter/material.dart';
import 'translations.dart';

class LocalizationProvider with ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
  ];

  String tr(String key, [Map<String, String>? params]) {
    String text = translations[_locale.languageCode]?[key] ?? key;
    
    // Replace parameters if provided
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        text = text.replaceAll('{$paramKey}', paramValue);
      });
    }
    
    return text;
  }

  void setLocale(Locale newLocale) {
    if (!supportedLocales.contains(newLocale)) {
      return;
    }
    _locale = newLocale;
    notifyListeners();
  }

  void setLanguageCode(String languageCode) {
    final locale = Locale(languageCode);
    setLocale(locale);
  }
}

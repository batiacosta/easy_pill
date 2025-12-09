import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
  ];

  late Map<String, String> _localizedStrings;

  Future<bool> load() async {
    final String jsonString =
        await DefaultAssetBundle.of(_context!).loadString(
      'lib/l10n/app_${locale.languageCode}.arb',
    );

    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    _localizedStrings = jsonMap.cast<String, String>();
    return true;
  }

  static BuildContext? _context;

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  String translateWithParams(String key, Map<String, String> params) {
    String value = _localizedStrings[key] ?? key;
    params.forEach((paramKey, paramValue) {
      value = value.replaceAll('{$paramKey}', paramValue);
    });
    return value;
  }

  // Greeting messages
  String get goodMorning => translate('good_morning');
  String get goodAfternoon => translate('good_afternoon');
  String get goodEvening => translate('good_evening');

  // Time references
  String get today => translate('today');
  String get tomorrow => translate('tomorrow');

  // Section titles
  String get todayPending => translate('today_pending');
  String get todayScheduled => translate('today_scheduled');

  // Actions
  String get markAsTaken => translate('mark_as_taken');
  String get taken => translate('taken');
  String get skipDose => translate('skip_dose');
  String get removeMedication => translate('remove_medication');
  String get cancel => translate('cancel');
  String get delete => translate('delete');

  // Messages
  String skipDoseConfirmation() => translate('skip_dose_confirmation');
  String removeMedicationConfirmation(String medication) =>
      translateWithParams('remove_medication_confirmation', {'medication': medication});
  String skipped(String medication) =>
      translateWithParams('skipped', {'medication': medication});
  String removedAllDoses(String medication) =>
      translateWithParams('removed_all_doses', {'medication': medication});

  // Other
  String get notifications => translate('notifications');
  String get addMedication => translate('add_medication');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .map((e) => e.languageCode)
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations.setContext(locale);
    final AppLocalizations appLocalizations = AppLocalizations(locale);
    await appLocalizations.load();
    return appLocalizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on AppLocalizations {
  static void setContext(Locale locale) {
    AppLocalizations._context = null;
  }
}

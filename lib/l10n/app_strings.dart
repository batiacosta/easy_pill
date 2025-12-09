import 'package:flutter/material.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'good_morning': 'Good Morning',
      'good_afternoon': 'Good Afternoon',
      'good_evening': 'Good Evening',
      'today': 'Today',
      'tomorrow': 'Tomorrow',
      'today_pending': 'Today - Pending',
      'today_scheduled': 'Today - Scheduled',
      'mark_as_taken': 'Mark as Taken',
      'taken': 'Taken',
      'skip_dose': 'Skip Dose',
      'remove_medication': 'Remove Medication',
      'skip_dose_confirmation': 'Are you sure you want to skip this scheduled dose?',
      'remove_medication_confirmation': 'Remove all scheduled doses of {medication}? This action cannot be undone.',
      'skipped': 'Skipped {medication}',
      'removed_all_doses': 'Removed all scheduled doses of {medication}',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'notifications': 'Notifications',
      'add_medication': 'Add Medication',
    },
    'es': {
      'good_morning': 'Buenos Días',
      'good_afternoon': 'Buenas Tardes',
      'good_evening': 'Buenas Noches',
      'today': 'Hoy',
      'tomorrow': 'Mañana',
      'today_pending': 'Hoy - Pendiente',
      'today_scheduled': 'Hoy - Programado',
      'mark_as_taken': 'Marcar como Tomado',
      'taken': 'Tomado',
      'skip_dose': 'Saltar Dosis',
      'remove_medication': 'Eliminar Medicamento',
      'skip_dose_confirmation': '¿Estás seguro de que deseas saltar esta dosis programada?',
      'remove_medication_confirmation': '¿Eliminar todas las dosis programadas de {medication}? Esta acción no se puede deshacer.',
      'skipped': 'Saltada {medication}',
      'removed_all_doses': 'Todas las dosis programadas de {medication} han sido eliminadas',
      'cancel': 'Cancelar',
      'delete': 'Eliminar',
      'notifications': 'Notificaciones',
      'add_medication': 'Agregar Medicamento',
    },
  };

  static String get(String key, {String languageCode = 'en'}) {
    return _strings[languageCode]?[key] ?? key;
  }

  static String getWithParams(String key,
      {required Map<String, String> params, String languageCode = 'en'}) {
    String value = _strings[languageCode]?[key] ?? key;
    params.forEach((paramKey, paramValue) {
      value = value.replaceAll('{$paramKey}', paramValue);
    });
    return value;
  }
}

class AppLocalization {
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
  ];

  static Locale getLocaleFromLanguageCode(String languageCode) {
    for (var locale in supportedLocales) {
      if (locale.languageCode == languageCode) {
        return locale;
      }
    }
    return const Locale('en');
  }

  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'es':
        return 'Español';
      case 'en':
      default:
        return 'English';
    }
  }
}

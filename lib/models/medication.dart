import 'package:flutter/material.dart';

enum ScheduleType { everyHours, fixedHours, everyDays }

class Medication {
  final int? id;
  final String name;
  final String? dosing;
  final int? pillCount; // null = infinite/ongoing
  final String? description;
  final ScheduleType scheduleType;
  final int? interval; // hours for everyHours, days for everyDays
  final List<TimeOfDay>? fixedTimes; // for fixedHours and everyDays
  final DateTime createdAt;
  final int notificationId; // Base ID for scheduling notifications

  Medication({
    this.id,
    required this.name,
    this.dosing,
    this.pillCount,
    this.description,
    required this.scheduleType,
    this.interval,
    this.fixedTimes,
    required this.notificationId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosing': dosing,
      'pill_count': pillCount,
      'description': description,
      'schedule_type': scheduleType.index,
      'interval': interval,
      'fixed_times': _encodeFixedTimes(fixedTimes),
      'created_at': createdAt.toIso8601String(),
      'notification_id': notificationId,
    };
  }

  // Create from database map
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      name: map['name'],
      dosing: map['dosing'],
      pillCount: map['pill_count'],
      description: map['description'],
      scheduleType: ScheduleType.values[map['schedule_type']],
      interval: map['interval'],
      fixedTimes: _decodeFixedTimes(map['fixed_times']),
      notificationId: map['notification_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  static String? _encodeFixedTimes(List<TimeOfDay>? times) {
    if (times == null || times.isEmpty) return null;
    return times.map((t) => '${t.hour}:${t.minute}').join(',');
  }

  static List<TimeOfDay>? _decodeFixedTimes(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    return encoded.split(',').map((time) {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }).toList();
  }

  Medication copyWith({
    int? id,
    String? name,
    String? dosing,
    int? pillCount,
    String? description,
    ScheduleType? scheduleType,
    int? interval,
    List<TimeOfDay>? fixedTimes,
    DateTime? createdAt,
    int? notificationId,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosing: dosing ?? this.dosing,
      pillCount: pillCount ?? this.pillCount,
      description: description ?? this.description,
      scheduleType: scheduleType ?? this.scheduleType,
      interval: interval ?? this.interval,
      fixedTimes: fixedTimes ?? this.fixedTimes,
      createdAt: createdAt ?? this.createdAt,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  @override
  String toString() => 'Medication(id: $id, name: $name, scheduleType: $scheduleType)';
}

import 'package:flutter/material.dart';
import 'package:easy_pill/models/medication.dart';

enum ConflictResolutionStrategy { merge, keepOnline, keepLocal }

class SyncConflict {
  final String medicationId;
  final Medication localMedication;
  final Medication remoteMedication;
  ConflictResolutionStrategy? resolutionStrategy;

  SyncConflict({
    required this.medicationId,
    required this.localMedication,
    required this.remoteMedication,
    this.resolutionStrategy,
  });

  /// Check if medications have different data (by comparing key fields)
  bool hasDifferences() {
    return localMedication.name != remoteMedication.name ||
        localMedication.dosing != remoteMedication.dosing ||
        localMedication.pillCount != remoteMedication.pillCount ||
        localMedication.description != remoteMedication.description ||
        localMedication.scheduleType != remoteMedication.scheduleType ||
        localMedication.interval != remoteMedication.interval ||
        _encodeFixedTimes(localMedication.fixedTimes) !=
            _encodeFixedTimes(remoteMedication.fixedTimes) ||
        _encodeTimeOfDay(localMedication.startTime) !=
            _encodeTimeOfDay(remoteMedication.startTime);
  }

  /// Get the resolved medication based on strategy
  Medication? getResolvedMedication() {
    switch (resolutionStrategy) {
      case ConflictResolutionStrategy.merge:
        // Merge: prefer remote for all fields (cloud is source of truth during merge)
        return remoteMedication;
      case ConflictResolutionStrategy.keepOnline:
        return remoteMedication;
      case ConflictResolutionStrategy.keepLocal:
        return localMedication;
      case null:
        return null;
    }
  }

  static String? _encodeTimeOfDay(TimeOfDay? time) {
    if (time == null) return null;
    return '${time.hour}:${time.minute}';
  }

  static String? _encodeFixedTimes(List<TimeOfDay>? times) {
    if (times == null || times.isEmpty) return null;
    return times.map((t) => '${t.hour}:${t.minute}').join(',');
  }
}

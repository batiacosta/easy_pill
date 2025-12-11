import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../models/scheduled_dose.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicationProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();
  
  List<Medication> _medications = [];
  Map<int, int> _todayDoseCounts = {};
  Set<String> _skippedDoseKeys = {};
  bool _isLoading = false;

  List<Medication> get medications => _medications;
  Map<int, int> get todayDoseCounts => _todayDoseCounts;
  bool get isLoading => _isLoading;

  // Get all scheduled doses for the next 31 days (excluding today)
  List<ScheduledDose> getScheduledDoses() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = now.add(const Duration(days: 31));
    final List<ScheduledDose> scheduledDoses = [];

    for (final medication in _medications) {
      scheduledDoses.addAll(_calculateScheduledDoses(medication, today, endDate));
    }

    // Filter out skipped doses
    scheduledDoses.removeWhere((dose) {
      final key = '${dose.medication.id}_${dose.scheduledTime.toIso8601String()}';
      return _skippedDoseKeys.contains(key);
    });

    // Sort by scheduled time
    scheduledDoses.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return scheduledDoses;
  }

  // Get all missed doses (doses before today that weren't taken or skipped)
  List<ScheduledDose> getMissedDoses() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));
    final List<ScheduledDose> missedDoses = [];

    for (final medication in _medications) {
      missedDoses.addAll(_calculateScheduledDoses(medication, thirtyDaysAgo, today));
    }

    // Filter out skipped doses and doses that were taken
    missedDoses.removeWhere((dose) {
      final key = '${dose.medication.id}_${dose.scheduledTime.toIso8601String()}';
      return _skippedDoseKeys.contains(key);
    });

    // Sort by scheduled time (newest first)
    missedDoses.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
    return missedDoses;
  }

  // Clear all missed doses by marking them as skipped
  Future<void> clearMissedDoses() async {
    final missedDoses = getMissedDoses();
    for (final dose in missedDoses) {
      await skipDose(dose.medication.id!, dose.scheduledTime);
    }
    notifyListeners();
    debugPrint('Cleared ${missedDoses.length} missed doses');
  }

  List<ScheduledDose> _calculateScheduledDoses(
    Medication medication,
    DateTime start,
    DateTime end,
  ) {
    final doses = <ScheduledDose>[];
    
    switch (medication.scheduleType) {
      case ScheduleType.everyHours:
        if (medication.interval == null) break;
        
        final now = DateTime.now();
        
        // Calculate first dose time based on startTime or current hour
        DateTime nextDose;
        if (medication.startTime != null) {
          // Use the specified start time
          var candidateTime = DateTime(now.year, now.month, now.day, medication.startTime!.hour, medication.startTime!.minute);
          // If start time has already passed today, start from tomorrow
          if (candidateTime.isBefore(now)) {
            candidateTime = candidateTime.add(const Duration(days: 1));
          }
          nextDose = candidateTime;
        } else {
          // Default: use current time as the starting point
          nextDose = now;
        }
        
        int doseCount = 0;
        
        while (nextDose.isBefore(end)) {
          nextDose = nextDose.add(Duration(hours: medication.interval!));
          if (nextDose.isAfter(start) && nextDose.isBefore(end)) {
            if (medication.pillCount == null || doseCount < medication.pillCount!) {
              doses.add(ScheduledDose(
                medication: medication,
                scheduledTime: nextDose,
              ));
              doseCount++;
            }
          }
        }
        break;

      case ScheduleType.fixedHours:
        if (medication.fixedTimes == null) break;
        int doseCount = 0;
        
        final now = DateTime.now();
        
        for (int day = 0; day < 31; day++) {
          final targetDate = start.add(Duration(days: day));
          if (targetDate.isAfter(end)) break;
          
          for (final time in medication.fixedTimes!) {
            if (medication.pillCount != null && doseCount >= medication.pillCount!) break;
            
            final scheduledDate = DateTime(
              targetDate.year,
              targetDate.month,
              targetDate.day,
              time.hour,
              time.minute,
            );
            
            // Only include doses that are in the future (after now)
            if (scheduledDate.isAfter(now) && scheduledDate.isBefore(end)) {
              doses.add(ScheduledDose(
                medication: medication,
                scheduledTime: scheduledDate,
              ));
              doseCount++;
            }
          }
        }
        break;

      case ScheduleType.everyDays:
        if (medication.interval == null || medication.fixedTimes == null) break;
        int doseCount = 0;
        
        final now = DateTime.now();
        
        for (int cycle = 0; cycle < 31; cycle++) {
          final targetDate = start.add(Duration(days: medication.interval! * cycle));
          if (targetDate.isAfter(end)) break;
          
          for (final time in medication.fixedTimes!) {
            if (medication.pillCount != null && doseCount >= medication.pillCount!) break;
            
            final scheduledDate = DateTime(
              targetDate.year,
              targetDate.month,
              targetDate.day,
              time.hour,
              time.minute,
            );
            
            // Only include doses that are in the future (after now)
            if (scheduledDate.isAfter(now) && scheduledDate.isBefore(end)) {
              doses.add(ScheduledDose(
                medication: medication,
                scheduledTime: scheduledDate,
              ));
              doseCount++;
            }
          }
        }
        break;
    }
    
    return doses;
  }

  // Load all medications from database
  Future<void> loadMedications() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _medications = await _dbService.getAllMedications();
      _todayDoseCounts = await _dbService.getTodayDoseCounts();
      _skippedDoseKeys = await _dbService.getAllSkippedDoseKeys();
      debugPrint('Loaded ${_medications.length} medications');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading medications: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new medication
  Future<Medication> addMedication(Medication medication) async {
    try {
      // Generate a unique notification ID based on timestamp
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final newMedication = medication.copyWith(notificationId: notificationId);
      
      // Save to database
      final id = await _dbService.insertMedication(newMedication);
      final savedMedication = newMedication.copyWith(id: id);
      
      // Schedule notifications
      await _scheduleNotificationsForMedication(savedMedication);
      
      // Add to local list
      _medications.insert(0, savedMedication);
      _todayDoseCounts[savedMedication.id!] = 0;
      notifyListeners();
      
      // Upload to Firestore if user is authenticated
      await _syncMedicationToFirestore(savedMedication);
      
      debugPrint('Medication added: ${savedMedication.name}');
      return savedMedication;
    } catch (e) {
      debugPrint('Error adding medication: $e');
      rethrow;
    }
  }

  // Delete medication
  Future<void> deleteMedication(int medicationId) async {
    try {
      // Find medication
      final medication = _medications.firstWhere((m) => m.id == medicationId);
      
      // Cancel notifications
      await _notificationService.cancelNotification(medication.notificationId);
      
      // Delete from database
      await _dbService.deleteMedication(medicationId);
      
      // Delete from Firestore if user is authenticated
      await _deleteMedicationFromFirestore(medication);
      
      // Remove from list
      _medications.removeWhere((m) => m.id == medicationId);
      _todayDoseCounts.remove(medicationId);
      notifyListeners();
      
      debugPrint('Medication deleted: ${medication.name}');
    } catch (e) {
      debugPrint('Error deleting medication: $e');
      rethrow;
    }
  }

  // Record dose taken and recalculate notifications
  Future<void> recordDoseTaken(int medicationId) async {
    try {
      // Record in database
      await _dbService.recordDoseTaken(medicationId);
      
      // Find the medication
      final medicationIndex = _medications.indexWhere((m) => m.id == medicationId);
      if (medicationIndex != -1) {
        // Recalculate notifications for this medication
        await _rescheduleNotificationsForMedication(_medications[medicationIndex]);
        final currentCount = _todayDoseCounts[medicationId] ?? 0;
        _todayDoseCounts[medicationId] = currentCount + 1;
        notifyListeners();
      }
      
      debugPrint('Dose recorded for medication ID: $medicationId');
    } catch (e) {
      debugPrint('Error recording dose: $e');
      rethrow;
    }
  }

  // Schedule notifications for a medication
  Future<void> _scheduleNotificationsForMedication(Medication medication) async {
    try {
      switch (medication.scheduleType) {
        case ScheduleType.everyHours:
          if (medication.interval == null || medication.interval! <= 0) {
            debugPrint('Skipping scheduleEveryHours: missing/invalid interval for ${medication.name}');
            return;
          }
          await _notificationService.scheduleEveryHours(
            id: medication.notificationId,
            medicationName: medication.name,
            hours: medication.interval!,
            dosing: medication.dosing,
            totalDoses: medication.pillCount,
            startTime: medication.startTime,
          );
          break;
        case ScheduleType.fixedHours:
          final times = medication.fixedTimes;
          if (times == null || times.isEmpty) {
            debugPrint('Skipping scheduleFixedHours: no times for ${medication.name}');
            return;
          }
          await _notificationService.scheduleFixedHours(
            id: medication.notificationId,
            medicationName: medication.name,
            times: times,
            dosing: medication.dosing,
            totalDoses: medication.pillCount,
          );
          break;
        case ScheduleType.everyDays:
          final times = medication.fixedTimes;
          if (medication.interval == null || medication.interval! <= 0) {
            debugPrint('Skipping scheduleEveryDays: missing/invalid interval for ${medication.name}');
            return;
          }
          if (times == null || times.isEmpty) {
            debugPrint('Skipping scheduleEveryDays: no times for ${medication.name}');
            return;
          }
          await _notificationService.scheduleEveryDays(
            id: medication.notificationId,
            medicationName: medication.name,
            days: medication.interval!,
            times: times,
            dosing: medication.dosing,
            totalDoses: medication.pillCount,
          );
          break;
      }
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
      rethrow;
    }
  }

  // Reschedule notifications for a medication (used after marking dose as taken)
  Future<void> _rescheduleNotificationsForMedication(Medication medication) async {
    try {
      // Cancel existing notifications
      await _notificationService.cancelNotification(medication.notificationId);
      
      // Reschedule for the remaining doses
      await _scheduleNotificationsForMedication(medication);
      
      debugPrint('Rescheduled notifications for: ${medication.name}');
    } catch (e) {
      debugPrint('Error rescheduling notifications: $e');
      rethrow;
    }
  }

  // Get today's dose count for a medication
  Future<int> getTodaysDoseCount(int medicationId) async {
    try {
      return await _dbService.getTodaysDoseCount(medicationId);
    } catch (e) {
      debugPrint('Error getting today dose count: $e');
      rethrow;
    }
  }

  // Update medication
  Future<void> updateMedication(Medication medication) async {
    try {
      // Update in database
      await _dbService.updateMedication(medication);
      
      // Update in local list
      final index = _medications.indexWhere((m) => m.id == medication.id);
      if (index != -1) {
        _medications[index] = medication;
        
        // Reschedule notifications
        await _rescheduleNotificationsForMedication(medication);
        
        // Sync to Firestore if user is authenticated
        await _syncMedicationToFirestore(medication);
        
        notifyListeners();
        debugPrint('Medication updated: ${medication.name}');
      }
    } catch (e) {
      debugPrint('Error updating medication: $e');
      rethrow;
    }
  }

  // Skip a dose
  Future<void> skipDose(int medicationId, DateTime scheduledTime) async {
    try {
      await _dbService.skipDose(medicationId, scheduledTime);
      
      // Add to skipped set
      final key = '${medicationId}_${scheduledTime.toIso8601String()}';
      _skippedDoseKeys.add(key);
      
      notifyListeners();
      debugPrint('Dose skipped for medication ID: $medicationId at $scheduledTime');
    } catch (e) {
      debugPrint('Error skipping dose: $e');
      rethrow;
    }
  }

  // Helper: Sync medication to Firestore if authenticated
  Future<void> _syncMedicationToFirestore(Medication medication) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestoreService.uploadMedication(medication);
        debugPrint('Medication synced to Firestore: ${medication.name}');
      }
    } catch (e) {
      debugPrint('Error syncing to Firestore: $e');
      // Don't throw - local operation should succeed even if sync fails
    }
  }

  // Helper: Delete medication from Firestore if authenticated
  Future<void> _deleteMedicationFromFirestore(Medication medication) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestoreService.deleteMedication(medication);
        debugPrint('Medication deleted from Firestore: ${medication.name}');
      }
    } catch (e) {
      debugPrint('Error deleting from Firestore: $e');
      // Don't throw - local operation should succeed even if sync fails
    }
  }

  // Reschedule notifications for all medications (used after sync/auth changes)
  Future<void> rescheduleAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
      for (final med in _medications) {
        await _scheduleNotificationsForMedication(med);
      }
      debugPrint('Rescheduled notifications for all medications');
    } catch (e) {
      debugPrint('Error rescheduling all notifications: $e');
    }
  }

  // Refresh medications from database (for syncing)
  Future<void> refreshMedications() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _medications = await _dbService.getAllMedications();
      _todayDoseCounts = await _dbService.getTodayDoseCounts();
      _skippedDoseKeys = await _dbService.getAllSkippedDoseKeys();
      debugPrint('Refreshed ${_medications.length} medications');
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing medications: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Replace local medications with remote ones (used after login/sync)
  Future<void> replaceWithRemote(List<Medication> remoteMeds) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Clear local data
      await _notificationService.cancelAllNotifications();
      await _dbService.clearAllMedicationsData();

      // Insert remote meds locally and schedule notifications
      _medications = [];
      for (final med in remoteMeds) {
        final newId = await _dbService.insertMedication(med);
        final saved = med.copyWith(id: newId);
        _medications.add(saved);
      }

      _todayDoseCounts = await _dbService.getTodayDoseCounts();
      _skippedDoseKeys = await _dbService.getAllSkippedDoseKeys();

      // Reschedule notifications for all
      await rescheduleAllNotifications();

      debugPrint('Replaced local medications with ${remoteMeds.length} remote meds');
    } catch (e) {
      debugPrint('Error replacing with remote meds: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}


import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class MedicationProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  
  List<Medication> _medications = [];
  Map<int, int> _todayDoseCounts = {};
  bool _isLoading = false;

  List<Medication> get medications => _medications;
  Map<int, int> get todayDoseCounts => _todayDoseCounts;
  bool get isLoading => _isLoading;

  // Load all medications from database
  Future<void> loadMedications() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _medications = await _dbService.getAllMedications();
      _todayDoseCounts = await _dbService.getTodayDoseCounts();
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

  @override
  void dispose() {
    super.dispose();
  }
}

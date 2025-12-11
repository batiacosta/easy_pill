import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/medication.dart';
import '../models/sync_conflict.dart';
import '../services/firestore_service.dart';

enum SyncState { idle, syncing, conflict, synced, error }

class SyncProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final Connectivity _connectivity = Connectivity();

  SyncState _syncState = SyncState.idle;
  List<SyncConflict> _conflicts = [];
  String? _errorMessage;

  // Getters
  SyncState get syncState => _syncState;
  List<SyncConflict> get conflicts => _conflicts;
  String? get errorMessage => _errorMessage;
  bool get hasSyncConflicts => _conflicts.isNotEmpty;

  /// Check if device has internet connection
  Future<bool> checkInternet() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  /// Check for conflicts between local and remote medications
  List<SyncConflict> _detectConflicts(
    List<Medication> local,
    List<Medication> remote,
  ) {
    final conflicts = <SyncConflict>[];

    // Check for medications in both local and remote with different data
    for (final localMed in local) {
      final localId = localMed.id?.toString() ?? localMed.notificationId.toString();
      final remoteMed = remote.firstWhere(
        (m) => (m.id?.toString() ?? m.notificationId.toString()) == localId,
        orElse: () => Medication(
          name: '',
          scheduleType: ScheduleType.everyDays,
          notificationId: 0,
        ),
      );

      if (remoteMed.name.isNotEmpty && localMed.toMap() != remoteMed.toMap()) {
        conflicts.add(SyncConflict(
          medicationId: localId,
          localMedication: localMed,
          remoteMedication: remoteMed,
        ));
      }
    }

    return conflicts;
  }

  /// Perform full sync: download remote, detect conflicts, return conflicts if any
  Future<bool> performSync(
    List<Medication> localMedications,
    String userId,
  ) async {
    try {
      _syncState = SyncState.syncing;
      _errorMessage = null;
      notifyListeners();

      // Download remote medications
      final remoteMedications = await _firestoreService.downloadMedications();

      // Detect conflicts
      _conflicts = _detectConflicts(localMedications, remoteMedications);

      if (_conflicts.isNotEmpty) {
        _syncState = SyncState.conflict;
        notifyListeners();
        return false; // Conflicts detected, need user resolution
      }

      // No conflicts - upload local to remote
      await _firestoreService.uploadAllMedications(localMedications);

      _syncState = SyncState.synced;
      notifyListeners();
      return true; // Sync successful
    } catch (e) {
      _syncState = SyncState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Resolve a single conflict with user's chosen strategy
  Future<Medication?> resolveConflict(
    String medicationId,
    ConflictResolutionStrategy strategy,
  ) async {
    try {
      final conflictIndex = _conflicts.indexWhere((c) => c.medicationId == medicationId);
      if (conflictIndex == -1) return null;

      _conflicts[conflictIndex].resolutionStrategy = strategy;
      return _conflicts[conflictIndex].getResolvedMedication();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Apply resolution for all conflicts and sync to Firestore
  Future<bool> applyConflictResolutions(
    List<Medication> localMedications,
  ) async {
    try {
      _syncState = SyncState.syncing;
      notifyListeners();

      // Build resolved medications list
      final resolved = <Medication>[];

      for (final med in localMedications) {
        final medId = med.id?.toString() ?? med.notificationId.toString();
        final conflict = _conflicts.firstWhere(
          (c) => c.medicationId == medId,
          orElse: () => SyncConflict(
            medicationId: medId,
            localMedication: Medication(
              name: '',
              scheduleType: ScheduleType.everyDays,
              notificationId: 0,
            ),
            remoteMedication: Medication(
              name: '',
              scheduleType: ScheduleType.everyDays,
              notificationId: 0,
            ),
          ),
        );

        if (conflict.medicationId.isEmpty) {
          // No conflict, keep as is
          resolved.add(med);
        } else if (conflict.resolutionStrategy == ConflictResolutionStrategy.keepLocal) {
          // Keep local
          resolved.add(med);
        } else {
          // Merge or Keep Online - use resolved
          final resolvedMed = conflict.getResolvedMedication();
          if (resolvedMed != null) {
            resolved.add(resolvedMed);
          }
        }
      }

      // Upload resolved to Firestore
      await _firestoreService.uploadAllMedications(resolved);

      _conflicts.clear();
      _syncState = SyncState.synced;
      notifyListeners();
      return true;
    } catch (e) {
      _syncState = SyncState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear sync state
  void clearSyncState() {
    _syncState = SyncState.idle;
    _conflicts.clear();
    _errorMessage = null;
    notifyListeners();
  }

  /// Manual sync trigger
  Future<void> triggerSync(List<Medication> localMedications) async {
    final hasInternet = await checkInternet();
    if (!hasInternet) {
      _errorMessage = 'No internet connection';
      _syncState = SyncState.error;
      notifyListeners();
      return;
    }

    await performSync(localMedications, '');
  }
}

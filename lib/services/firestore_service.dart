import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/medication.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;

  factory FirestoreService() {
    return _instance;
  }

  FirestoreService._internal() {
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
  }

  /// Upload a medication to Firestore
  Future<void> uploadMedication(Medication medication) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final medicationId = medication.id?.toString() ?? medication.notificationId.toString();
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medications')
          .doc(medicationId);

      await docRef.set({
        'id': medicationId,
        'name': medication.name,
        'dosing': medication.dosing,
        'pillCount': medication.pillCount,
        'description': medication.description,
        'scheduleType': medication.scheduleType.index,
        'interval': medication.interval,
        'fixedTimes': medication.fixedTimes != null
            ? medication.fixedTimes!.map((t) => '${t.hour}:${t.minute}').join(',')
            : null,
        'startTime': medication.startTime != null
            ? '${medication.startTime!.hour}:${medication.startTime!.minute}'
            : null,
        'createdAt': medication.createdAt.toIso8601String(),
        'notificationId': medication.notificationId,
        'lastSyncedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: false));
    } catch (e) {
      rethrow;
    }
  }

  /// Upload all medications to Firestore
  Future<void> uploadAllMedications(List<Medication> medications) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final batch = _firestore.batch();
      final userMedsRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medications');

      for (final med in medications) {
        final medicationId = med.id?.toString() ?? med.notificationId.toString();
        final docRef = userMedsRef.doc(medicationId);

        batch.set(docRef, {
          'id': medicationId,
          'name': med.name,
          'dosing': med.dosing,
          'pillCount': med.pillCount,
          'description': med.description,
          'scheduleType': med.scheduleType.index,
          'interval': med.interval,
          'fixedTimes': med.fixedTimes != null
              ? med.fixedTimes!.map((t) => '${t.hour}:${t.minute}').join(',')
              : null,
          'startTime': med.startTime != null
              ? '${med.startTime!.hour}:${med.startTime!.minute}'
              : null,
          'createdAt': med.createdAt.toIso8601String(),
          'notificationId': med.notificationId,
          'lastSyncedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: false));
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Download medications from Firestore for current user
  Future<List<Medication>> downloadMedications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medications')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _medicationFromFirestoreData(data);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a medication from Firestore
  Future<void> deleteMedication(Medication medication) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final medicationId = medication.id?.toString() ?? medication.notificationId.toString();
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medications')
          .doc(medicationId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete all medications for current user
  Future<void> deleteAllMedications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medications')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Helper: Convert Firestore data to Medication object
  Medication _medicationFromFirestoreData(Map<String, dynamic> data) {
    return Medication(
      id: int.tryParse(data['id'].toString()),
      name: data['name'] ?? '',
      dosing: data['dosing'],
      pillCount: data['pillCount'],
      description: data['description'],
      scheduleType: ScheduleType.values[data['scheduleType'] ?? 0],
      interval: data['interval'],
      fixedTimes: _decodeFixedTimes(data['fixedTimes']),
      startTime: _decodeTimeOfDay(data['startTime']),
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      notificationId: data['notificationId'] ?? 0,
    );
  }

  /// Helper: Decode TimeOfDay from storage
  TimeOfDay? _decodeTimeOfDay(dynamic encoded) {
    if (encoded == null || encoded.toString().isEmpty) return null;
    try {
      final parts = encoded.toString().split(':');
      if (parts.length != 2) return null;
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  /// Helper: Decode List<TimeOfDay> from storage
  List<TimeOfDay>? _decodeFixedTimes(dynamic encoded) {
    if (encoded == null || encoded.toString().isEmpty) return null;
    try {
      return encoded.toString().split(',').map((time) {
        final parts = time.split(':');
        if (parts.length != 2) return null;
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).whereType<TimeOfDay>().toList();
    } catch (e) {
      return null;
    }
  }
}

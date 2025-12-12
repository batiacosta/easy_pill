import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  FirebaseAuth? _auth;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _firebaseInitialized = false;
  final FirestoreService _firestoreService = FirestoreService();

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isFirebaseEnabled => _firebaseInitialized;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    try {
      _auth = FirebaseAuth.instance;
      _firebaseInitialized = true;
      // Listen to auth state changes
      _auth!.authStateChanges().listen((User? user) {
        _user = user;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Firebase Auth not available: $e');
      _firebaseInitialized = false;
    }
  }

  // Sign up with email and password
  Future<bool> signUp(String email, String password, String displayName) async {
    if (!_firebaseInitialized || _auth == null) {
      _errorMessage = 'Firebase is not configured. Please run: flutterfire configure';
      notifyListeners();
      return false;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      UserCredential userCredential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();
      _user = _auth!.currentUser;

      // Create user document in Firestore
      if (_user != null) {
        await _createUserDocument(_user!.uid, displayName, email);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    if (!_firebaseInitialized || _auth == null) {
      _errorMessage = 'Firebase is not configured. Please run: flutterfire configure';
      notifyListeners();
      return false;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (_auth != null) {
      await _auth!.signOut();
    }
    _user = null;
    notifyListeners();
  }

  // Delete current user account
  Future<bool> deleteAccount() async {
    if (!_firebaseInitialized || _auth == null) {
      _errorMessage = 'Firebase is not configured. Please run: flutterfire configure';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final currentUser = _auth!.currentUser;
      if (currentUser == null) {
        _isLoading = false;
        _errorMessage = 'No authenticated user';
        notifyListeners();
        return false;
      }

      final uid = currentUser.uid;

      // Delete user-related Firestore data while authenticated
      try {
        await _firestoreService.deleteAllMedications();
      } catch (e) {
        debugPrint('Error deleting Firestore medications: $e');
      }

      try {
        final firestore = FirebaseFirestore.instance;
        final userDocRef = firestore.collection('users').doc(uid);
        await userDocRef.delete();

        // Verify deletion and retry once if still present
        final snapshot = await userDocRef.get();
        if (snapshot.exists) {
          await userDocRef.delete();
        }
      } catch (e) {
        debugPrint('Error deleting Firestore user doc: $e');
      }

      // Delete auth user (may require recent login)
      await currentUser.delete();

      // Sign out locally to clear state
      await signOut();

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      if (e.code == 'requires-recent-login') {
        _errorMessage = 'Please reauthenticate to delete your account';
      } else {
        _errorMessage = _getErrorMessage(e.code);
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    if (!_firebaseInitialized || _auth == null) {
      _errorMessage = 'Firebase is not configured. Please run: flutterfire configure';
      notifyListeners();
      return false;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth!.sendPasswordResetEmail(email: email);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(String uid, String displayName, String email) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(uid).set({
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'createdAt': DateTime.now().toIso8601String(),
        'lastSyncedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('User document created successfully for $uid');
    } catch (e) {
      debugPrint('Error creating user document: $e');
      // Don't throw - user can still use the app even if Firestore fails
    }
  }

  // Get user-friendly error messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password is too weak';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseAuthService {
  // Password reset is managed by Firebase only. Backend is not called for password changes.
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _fbTokenKey = 'firebase_id_token';

  Future<UserCredential> registerWithEmailPassword(
    String email,
    String password,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final token = await cred.user?.getIdToken();
    if (token != null) await _saveToken(token);
    return cred;
  }

  Future<UserCredential> loginWithEmailPassword(
    String email,
    String password,
  ) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final token = await cred.user?.getIdToken();
    if (token != null) await _saveToken(token);
    return cred;
  }

  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fbTokenKey);
  }

  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      // Try to read cached token
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fbTokenKey);
    }
    final token = await user.getIdToken(true);
    if (token != null) await _saveToken(token);
    return token;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fbTokenKey, token);
  }

  bool get isSignedIn => _auth.currentUser != null;

  String? get currentUid => _auth.currentUser?.uid;
  String? get currentEmail => _auth.currentUser?.email;

  /// Sends a Firebase password reset email to [email].
  ///
  /// Validates that [email] is non-empty. On failure, throws an [Exception]
  /// with a clear message derived from the underlying [FirebaseAuthException]
  /// or a generic error message.
  Future<void> sendPasswordResetEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      throw Exception('Email must not be empty');
    }

    try {
      await _auth.sendPasswordResetEmail(email: trimmed);
    } on FirebaseAuthException catch (e) {
      // Surface Firebase errors as exceptions with meaningful messages.
      throw Exception(e.message ?? 'Failed to send password reset email');
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }
}

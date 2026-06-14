import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/app_user.dart';

// ── Secret teacher registration code ──────────────────────
// Change this to any secret your college decides on.
// Store it here for the prototype; in production move it to
// Firebase Remote Config so you can change it without an app update.
const String kTeacherSecretCode = 'TEACHER2024';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');

  // ── Current Firebase user ──────────────────────────────
  User? get currentFirebaseUser => _auth.currentUser;

  // ── Stream of auth state changes ──────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Fetch AppUser profile from Realtime DB ─────────────
  Future<AppUser?> fetchUserProfile(String uid) async {
    final snap = await _usersRef.child(uid).get();
    if (!snap.exists || snap.value == null) return null;
    return AppUser.fromMap(uid, snap.value as Map);
  }

  // ── Sign In ────────────────────────────────────────────
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final profile = await fetchUserProfile(cred.user!.uid);
    if (profile == null) throw Exception('User profile not found.');
    return profile;
  }

  // ── Register Teacher (requires secret code) ────────────
  Future<AppUser> registerTeacher({
    required String name,
    required String email,
    required String password,
    required String secretCode,
  }) async {
    // Validate secret code first — before creating any account
    if (secretCode.trim().toUpperCase() != kTeacherSecretCode) {
      throw Exception(
        'Invalid teacher code. Please contact your administrator.',
      );
    }

    // Create Firebase Auth account
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    // Update display name
    await cred.user!.updateDisplayName(name.trim());

    // Save role to Realtime Database
    final user = AppUser(
      uid: cred.user!.uid,
      email: email.trim(),
      name: name.trim(),
      role: 'teacher',
      createdAt: DateTime.now(),
    );
    await _usersRef.child(cred.user!.uid).set(user.toMap());
    return user;
  }

  // ── Sign Out ───────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Password Reset ─────────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Map Firebase error codes to friendly messages ──────
  static String friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

import 'package:examis_ai/theming/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:examis_ai/provider/history_provider.dart';
import 'package:examis_ai/provider/assessment_provider.dart';
import 'package:examis_ai/pages/auth/login_page.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String _userName = "Teacher";
  String? _avatarUrl;

  // 🚀 NEW: Local Storage Variables
  int _storageUsedBytes = 0;
  int _storageLimitBytes = 52428800; // Default 50MB

  String? get avatarUrl => _avatarUrl;

  bool get isLoading => _isLoading;

  String get userName => _userName;

  int get storageUsedBytes => _storageUsedBytes;

  int get storageLimitBytes => _storageLimitBytes;

  AuthProvider() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.signedIn) {
        fetchUserProfile(); // Made this public!
      } else if (event == AuthChangeEvent.signedOut) {
        _userName = "Teacher";
        _storageUsedBytes = 0;
      }
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select(
              'full_name, avatar_url, storage_used_bytes, storage_limit_bytes',
            )
            .eq('id', user.id)
            .single();

        _userName = response['full_name'] ?? "User";
        _avatarUrl = response['avatar_url'];
        _storageUsedBytes = response['storage_used_bytes'] ?? 0;
        _storageLimitBytes = response['storage_limit_bytes'] ?? 52428800;

        notifyListeners();
      }
    } catch (e) {
      print("Error loading profile: $e");
    }
  }

  void adjustStorageLocal(int byteDifference) {
    _storageUsedBytes += byteDifference;
    if (_storageUsedBytes < 0) _storageUsedBytes = 0;
    notifyListeners();
  }

  Future<bool> signUp(
    BuildContext context, {
    required String fullName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      await _supabase.auth.signOut();

      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _showError(context, e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _showError(context, "An unexpected error occurred.");
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signIn(
    BuildContext context, {
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      await fetchUserProfile();
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _showError(context, e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _showError(context, "An unexpected error occurred.");
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut(BuildContext context) async {
    if (!context.mounted) return;
    context.read<HistoryProvider>().clearData();
    context.read<AssessmentProvider>().clearData();

    await _supabase.auth.signOut();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<bool> updateProfile(
    BuildContext context, {
    required String newName,
    String? newPassword,
  }) async {
    _setLoading(true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("No user logged in.");
      await _supabase
          .from('profiles')
          .update({'full_name': newName})
          .eq('id', userId);

      await _supabase.auth.updateUser(
        UserAttributes(data: {'full_name': newName}),
      );

      if (newPassword != null && newPassword.isNotEmpty) {
        await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      }

      await fetchUserProfile();

      _setLoading(false);
      return true;
    } catch (e) {
      _showError(context, "Failed to update profile.");
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteAccount(BuildContext context) async {
    _setLoading(true);
    try {
      await _supabase.rpc('delete_user');
      await signOut(context);
      _setLoading(false);
      return true;
    } catch (e) {
      print(e);
      _showError(context, "Failed to delete account.");
      _setLoading(false);
      return false;
    }
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<bool> submitFeedback(BuildContext context, String message) async {
    _setLoading(true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("No user logged in.");

      await _supabase.from('feedback').insert({
        'user_id': userId,
        'message': message,
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _showError(context, "Failed to send feedback. Please try again.");
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(BuildContext context, String email) async {
    _setLoading(true);
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      _setLoading(false);

      if (!context.mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Recovery code sent! Check your email."),
          backgroundColor: AppColors.success,
        ),
      );
      return true;
    } on AuthException catch (e) {
      _showError(context, e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _showError(context, "An unexpected error occurred.");
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyRecoveryCode(
    BuildContext context,
    String email,
    String code,
  ) async {
    _setLoading(true);
    try {
      await _supabase.auth.verifyOTP(
        type: OtpType.recovery,
        token: code,
        email: email,
      );
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _showError(context, e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _showError(context, "Invalid code or an unexpected error occurred.");
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updatePassword(BuildContext context, String newPassword) async {
    _setLoading(true);
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      _setLoading(false);
      return true;
    } catch (e) {
      _showError(context, "Failed to update password.");
      _setLoading(false);
      return false;
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    _setLoading(true);
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        scopes: 'email profile https://www.googleapis.com/auth/drive.file',
        redirectTo: 'examisai://login-callback/',
      );
      _setLoading(false);
    } on AuthException catch (e) {
      _showError(context, e.message);
      _setLoading(false);
    } catch (e) {
      _showError(context, "An unexpected error occurred with Google Sign-In.");
      _setLoading(false);
    }
  }
}

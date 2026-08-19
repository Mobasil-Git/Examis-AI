import 'package:examisai/data/app_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repository/auth_repository.dart';
import '../utils/theme/app_colors.dart';
import '../utils/utils.dart';
import '../data/local/shared_pref_manager.dart';
import 'history_view_model.dart';
import 'assessment_view_model.dart';
import '../utils/routes/route_names.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final _supabase = Supabase.instance.client;
  final SharedPrefManager _prefManager = SharedPrefManager();

  bool _isLoading = false;
  String _userName = "Teacher";
  String? _avatarUrl;

  int _storageUsedBytes = 0;
  int _storageLimitBytes = 52428800;

  String _tier = 'free';
  String? _customApiKey;

  String? get avatarUrl => _avatarUrl;
  bool get isLoading => _isLoading;
  String get userName => _userName;
  int get storageUsedBytes => _storageUsedBytes;
  int get storageLimitBytes => _storageLimitBytes;
  String get tier => _tier;
  String? get customApiKey => _customApiKey;

  // Crucial Lock Logic - Safe check for custom API key
  bool get isAppUnlocked => _tier == 'premium' || (_tier == 'free' && _customApiKey != null && _customApiKey!.isNotEmpty == true);

  AuthViewModel() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.signedIn) {
        fetchUserProfile();
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
      final response = await _authRepo.fetchUserProfile();
      _userName = response['full_name'] ?? "User";
      _avatarUrl = response['avatar_url'];
      _storageUsedBytes = response['storage_used_bytes'] ?? 0;
      _storageLimitBytes = response['storage_limit_bytes'] ?? 52428800;

      _tier = response['tier'] ?? 'free';
      await _prefManager.saveUserTier(_tier);

      _customApiKey = await _prefManager.getCustomApiKey();

      notifyListeners();
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  Future<void> updateTier(String newTier) async {
    _tier = newTier;
    notifyListeners();
    await _prefManager.saveUserTier(newTier);
    try {
      await _authRepo.updateUserTier(newTier);
    } catch (e) {
      debugPrint("Failed to sync tier to Supabase: $e");
    }
  }

  Future<void> updateCustomApiKey(String newKey) async {
    _customApiKey = newKey;
    notifyListeners();
    await _prefManager.saveCustomApiKey(newKey);
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
      await _authRepo.signUp(email, password, fullName);
      await _authRepo.signOut();
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
      await _authRepo.signIn(email, password);
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
    context.read<HistoryViewModel>().clearData();
    context.read<AssessmentViewModel>().clearData();

    await _authRepo.signOut();

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.login,
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
      await _authRepo.updateProfile(newName, newPassword);
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
      await _authRepo.deleteAccount();
      await signOut(context);
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint(e.toString());
      _showError(context, "Failed to delete account.");
      _setLoading(false);
      return false;
    }
  }

  Future<bool> submitFeedback(BuildContext context, String message) async {
    _setLoading(true);
    try {
      await _authRepo.submitFeedback(message);
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
      await _authRepo.resetPassword(email);
      _setLoading(false);
      if (!context.mounted) return false;

      Utils.showSnackBar(context, "Recovery code sent! Check your email.", AppColors.success);
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

  Future<bool> verifyRecoveryCode(BuildContext context, String email, String code) async {
    _setLoading(true);
    try {
      await _authRepo.verifyRecoveryCode(email, code);
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
      await _authRepo.updatePassword(newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _showError(context, "Failed to update password.");
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle(BuildContext context) async {
    _setLoading(true);
    try {
      debugPrint('ViewModel: Triggering Google Sign-In...');
      final response = await _authRepo.signInWithGoogle();
      await fetchUserProfile();

      debugPrint('ViewModel: Sign-In returned successfully.');
      _setLoading(false);

      return response.user != null;
    } catch (e) {
      debugPrint('ViewModel: Caught error during Google Sign-In: $e');
      _setLoading(false);

      if (e is InvalidInputException && e.toString().contains('canceled')) {
        debugPrint('ViewModel: Interpreted as user cancelation. Ignoring silently.');
        return false;
      }

      if (!context.mounted) return false;

      debugPrint('ViewModel: Showing error snackbar to user.');
      _showError(context, e.toString());
      return false;
    }
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    Utils.showSnackBar(context, message, AppColors.error);
  }
}
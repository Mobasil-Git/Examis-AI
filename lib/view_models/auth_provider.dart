import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repository/auth_repository.dart';
import '../data/local/shared_pref_manager.dart';
import '../data/app_exceptions.dart';
import '../utils/theme/app_colors.dart';
import '../utils/utils.dart';

class AppAuthState {
  final bool isLoading;
  final String userName;
  final String? avatarUrl;
  final int storageUsedBytes;
  final int storageLimitBytes;
  final String? customApiKey;

  const AppAuthState({
    this.isLoading = false,
    this.userName = "Teacher",
    this.avatarUrl,
    this.storageUsedBytes = 0,
    this.storageLimitBytes = 52428800,
    this.customApiKey,
  });

  bool get isAppUnlocked => customApiKey != null && customApiKey!.isNotEmpty;

  AppAuthState copyWith({
    bool? isLoading,
    String? userName,
    String? avatarUrl,
    int? storageUsedBytes,
    int? storageLimitBytes,
    String? customApiKey,
  }) {
    return AppAuthState(
      isLoading: isLoading ?? this.isLoading,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      storageUsedBytes: storageUsedBytes ?? this.storageUsedBytes,
      storageLimitBytes: storageLimitBytes ?? this.storageLimitBytes,
      customApiKey: customApiKey ?? this.customApiKey,
    );
  }
}

class AuthNotifier extends Notifier<AppAuthState> {
  final AuthRepository _authRepo = AuthRepository();
  final _supabase = Supabase.instance.client;
  final SharedPrefManager _prefManager = SharedPrefManager();

  @override
  AppAuthState build() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.signedIn) {
        fetchUserProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        state = const AppAuthState(userName: "Teacher", storageUsedBytes: 0);
      }
    });
    return const AppAuthState();
  }

  void _setLoading(bool value) => state = state.copyWith(isLoading: value);

  Future<void> fetchUserProfile() async {
    try {
      final response = await _authRepo.fetchUserProfile();
      final key = await _prefManager.getCustomApiKey();
      state = state.copyWith(
        userName: response['full_name'] ?? "User",
        avatarUrl: response['avatar_url'],
        storageUsedBytes: response['storage_used_bytes'] ?? 0,
        storageLimitBytes: response['storage_limit_bytes'] ?? 52428800,
        customApiKey: key,
      );
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  Future<void> updateCustomApiKey(String newKey) async {
    state = state.copyWith(customApiKey: newKey);
    await _prefManager.saveCustomApiKey(newKey);
  }

  void adjustStorageLocal(int byteDifference) {
    final newUsed = (state.storageUsedBytes + byteDifference)
        .clamp(0, double.infinity)
        .toInt();
    state = state.copyWith(storageUsedBytes: newUsed);
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
      if (context.mounted) {
        Utils.showSnackBar(context, e.message, AppColors.error);
      }
    } catch (_) {
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          "An unexpected error occurred.",
          AppColors.error,
        );
      }
    }
    _setLoading(false);
    return false;
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
      if (context.mounted) {
        Utils.showSnackBar(context, e.message, AppColors.error);
      }
    } catch (_) {
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          "An unexpected error occurred.",
          AppColors.error,
        );
      }
    }
    _setLoading(false);
    return false;
  }

  Future<void> signOut() async {
    await _authRepo.signOut();
    state = const AppAuthState();
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
    } catch (_) {
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          "Failed to update profile.",
          AppColors.error,
        );
      }
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteAccount(BuildContext context) async {
    _setLoading(true);
    try {
      await _authRepo.deleteAccount();
      await signOut();
      _setLoading(false);
      return true;
    } catch (_) {
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          "Failed to delete account.",
          AppColors.error,
        );
      }
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
    } catch (_) {
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          "Failed to send feedback.",
          AppColors.error,
        );
      }
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(BuildContext context, String email) async {
    _setLoading(true);
    try {
      await _authRepo.resetPassword(email);
      _setLoading(false);
      if (context.mounted) {
        Utils.showSnackBar(context, "Recovery code sent!", AppColors.success);
      }
      return true;
    } on AuthException catch (e) {
      if (context.mounted) {
        Utils.showSnackBar(context, e.message, AppColors.error);
      }
    } catch (_) {
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          "An unexpected error occurred.",
          AppColors.error,
        );
      }
    }
    _setLoading(false);
    return false;
  }

  Future<bool> verifyRecoveryCode(
    BuildContext context,
    String email,
    String code,
  ) async {
    _setLoading(true);
    try {
      await _authRepo.verifyRecoveryCode(email, code);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      if (context.mounted) {
        Utils.showSnackBar(context, e.message, AppColors.error);
      }
    } catch (_) {
      if (context.mounted) {
        Utils.showSnackBar(context, "Invalid code.", AppColors.error);
      }
    }
    _setLoading(false);
    return false;
  }

  Future<bool> updatePassword(BuildContext context, String newPassword) async {
    _setLoading(true);
    try {
      await _authRepo.updatePassword(newPassword);
      _setLoading(false);
      return true;
    } catch (_) {
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          "Failed to update password.",
          AppColors.error,
        );
      }
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle(BuildContext context) async {
    _setLoading(true);
    try {
      final response = await _authRepo.signInWithGoogle();
      await fetchUserProfile();
      _setLoading(false);
      return response.user != null;
    } catch (e) {
      _setLoading(false);
      if (e is InvalidInputException && e.toString().contains('canceled')) {
        return false;
      }
      if (context.mounted) {
        Utils.showSnackBar(context, e.toString(), AppColors.error);
      }
      return false;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AppAuthState>(() {
  return AuthNotifier();
});

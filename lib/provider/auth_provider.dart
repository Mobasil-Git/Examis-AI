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
  String _userName = "Teacher"; // Default fallback name
  String? _avatarUrl;
  String? get avatarUrl => _avatarUrl;

  bool get isLoading => _isLoading;

  String get userName => _userName;

  AuthProvider() {
    // Keep the listener for app restarts and logouts
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      // THE FIX: We added "|| event == AuthChangeEvent.signedIn" here!
      // Now, when Google snaps back into the app, it instantly triggers the profile fetch.
      if (event == AuthChangeEvent.initialSession || event == AuthChangeEvent.signedIn) {
        _fetchUserProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _userName = "Teacher";
      }
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // --- Fetch Profile Data ---
  Future<void> _fetchUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Fetch BOTH name and avatar_url from the database
        final response = await Supabase.instance.client
            .from('profiles') // Use your table name
            .select('full_name, avatar_url') // Select both columns!
            .eq('id', user.id)
            .single();

        _userName = response['full_name'] ?? "User";
        _avatarUrl = response['avatar_url']; // Save the URL!

        notifyListeners();
      }
    } catch (e) {
      print("Error loading profile: $e");
    }
  }

  // --- Sign Up ---
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

      // FIX 1: Instantly log them out so they can manually log in on the next screen!
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

  // --- Log In ---
  Future<bool> signIn(
    BuildContext context, {
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);

      // FIX 2: Wait for the name to be fetched BEFORE going to the dashboard!
      await _fetchUserProfile();

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

  // --- Log Out ---
  // --- Log Out ---
  Future<void> signOut(BuildContext context) async {
    if (!context.mounted) return;

    // 1. WIPE THE SLATE CLEAN!
    // Instantly delete the current user's data from the app's memory
    context.read<HistoryProvider>().clearData();
    context.read<AssessmentProvider>().clearData();

    // 2. Tell Supabase to securely end the session
    await _supabase.auth.signOut();

    // 3. Force navigate them back to the Login Page
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false, // Destroys the routing history so they can't hit "back"
      );
    }
  }

  // ... existing code (signUp, signIn, signOut, etc.) ...

  // --- Update Profile & Password ---
  Future<bool> updateProfile(
    BuildContext context, {
    required String newName,
    String? newPassword,
  }) async {
    _setLoading(true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("No user logged in.");

      // 1. Update the name in your public.profiles table
      await _supabase
          .from('profiles')
          .update({'full_name': newName})
          .eq('id', userId);

      // 2. Update the hidden auth metadata to match
      await _supabase.auth.updateUser(
        UserAttributes(data: {'full_name': newName}),
      );

      // 3. If they typed a new password, update it!
      if (newPassword != null && newPassword.isNotEmpty) {
        await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      }

      // 4. Refresh the local name so the UI updates instantly
      await _fetchUserProfile();

      _setLoading(false);
      return true; // Success
    } catch (e) {
      _showError(context, "Failed to update profile.");
      _setLoading(false);
      return false;
    }
  }

  // --- Delete Account ---
  Future<bool> deleteAccount(BuildContext context) async {
    _setLoading(true);
    try {
      // Calls the secure SQL function we just created
      await _supabase.rpc('delete_user');

      // Log them out locally
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

  // --- Submit Feedback ---
  Future<bool> submitFeedback(BuildContext context, String message) async {
    _setLoading(true); // Re-using your loading state!
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("No user logged in.");

      // Insert the message into the new feedback table
      await _supabase.from('feedback').insert({
        'user_id': userId,
        'message': message,
      });

      _setLoading(false);
      return true; // Success!
    } catch (e) {
      _showError(context, "Failed to send feedback. Please try again.");
      _setLoading(false);
      return false;
    }
  }

  // --- 1. Send the Recovery Code ---
  Future<bool> resetPassword(BuildContext context, String email) async {
    _setLoading(true);
    try {
      // This still triggers the recovery email, but now it sends the {{ .Token }}!
      await _supabase.auth.resetPasswordForEmail(email);

      _setLoading(false);

      if (!context.mounted) return false;

      // Updated success message
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

  // --- 2. Verify the 6-Digit Code ---
  Future<bool> verifyRecoveryCode(
    BuildContext context,
    String email,
    String code,
  ) async {
    _setLoading(true);
    try {
      // This verifies the 6-digit code
      await _supabase.auth.verifyOTP(
        type: OtpType.recovery,
        token: code,
        email: email,
      );

      _setLoading(false);

      // Note: If this succeeds, Supabase automatically logs the user in!
      // They are now authenticated and have permission to change their password.
      return true;
    } on AuthException catch (e) {
      _showError(context, e.message); // e.g., "Token has expired or is invalid"
      _setLoading(false);
      return false;
    } catch (e) {
      _showError(context, "Invalid code or an unexpected error occurred.");
      _setLoading(false);
      return false;
    }
  }

  // --- Update Password ONLY (Safe for Password Reset Flow) ---
  Future<bool> updatePassword(BuildContext context, String newPassword) async {
    _setLoading(true);
    try {
      // This ONLY updates the auth password, leaving the profiles table completely untouched.
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));

      _setLoading(false);
      return true;
    } catch (e) {
      _showError(context, "Failed to update password.");
      _setLoading(false);
      return false;
    }
  }

  // --- Google Sign-In ---
  Future<void> signInWithGoogle(BuildContext context) async {
    _setLoading(true);
    try {
      // This tells Supabase to launch the Google login flow
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // Optional but recommended: Ask for their profile image too!
        scopes: 'email profile https://www.googleapis.com/auth/drive.file',
        redirectTo: 'examisai://login-callback/',
      );

      // Note: We don't navigate to the Dashboard here!
      // Supabase will automatically handle the redirect and update the session.
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

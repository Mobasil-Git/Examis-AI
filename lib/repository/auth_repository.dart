import 'package:examisai/data/app_exceptions.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  Exception _handleError(Object e) {
    final errorString = e.toString().toLowerCase();

    if (e is AuthException) {
      if (errorString.contains('invalid') || errorString.contains('expired')) {
        return UnauthorizedException(e.message);
      }
      return BadRequestException(e.message);
    }

    if (errorString.contains('socketexception') ||
        errorString.contains('failed host lookup')) {
      return NoInternetException('Please check your network connection.');
    } else if (errorString.contains('timeoutexception')) {
      return RequestTimeoutException('The request timed out.');
    }

    return FetchDataException('An unexpected error occurred.');
  }

  Future<AuthResponse> signUp(
    String email,
    String password,
    String fullName,
  ) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<Map<String, dynamic>> fetchUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("No user logged in.");

    return await _supabase
        .from('profiles')
        .select(
          'full_name, avatar_url, storage_used_bytes, storage_limit_bytes, tier',
        ) // Added 'tier'
        .eq('id', user.id)
        .single();
  }

  Future<void> updateUserTier(String tier) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("No user logged in.");
    await _supabase.from('profiles').update({'tier': tier}).eq('id', userId);
  }

  Future<void> updateProfile(String newName, String? newPassword) async {
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
  }

  Future<void> deleteAccount() async {
    await _supabase.rpc('delete_user');
  }

  Future<void> submitFeedback(String message) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("No user logged in.");

    await _supabase.from('feedback').insert({
      'user_id': userId,
      'message': message,
    });
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<AuthResponse> verifyRecoveryCode(String email, String code) async {
    return await _supabase.auth.verifyOTP(
      type: OtpType.recovery,
      token: code,
      email: email,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<AuthResponse> signInWithGoogle() async {
    try {
      debugPrint('--- STARTING GOOGLE SIGN IN ---');
      final signIn = GoogleSignIn.instance;

      debugPrint('1. Calling signIn.authenticate()...');
      final googleUser = await signIn.authenticate();

      debugPrint(
        '2. Authenticate successful. Selected User: ${googleUser.email}',
      );

      debugPrint('3. Fetching authentication tokens...');
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      debugPrint('4. Tokens fetched. ID Token present: ${idToken != null}');

      final List<String> googleScopes = [
        'email',
        'https://www.googleapis.com/auth/userinfo.profile',
      ];

      debugPrint('5. Requesting authorization for scopes...');
      final authorization =
          await googleUser.authorizationClient.authorizationForScopes(
            googleScopes,
          ) ??
          await googleUser.authorizationClient.authorizeScopes(googleScopes);

      debugPrint(
        '6. Scopes authorized. Access Token present: ${authorization.accessToken}',
      );

      if (idToken == null) throw const AuthException('No ID Token found.');

      debugPrint('7. Sending tokens to Supabase...');
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );
      if (googleUser.photoUrl != null && response.user != null) {
        try {
          final currentProfile = await _supabase
              .from('profiles')
              .select('avatar_url')
              .eq('id', response.user!.id)
              .maybeSingle();

          // Only apply Google photo if the user doesn't already have an avatar
          if (currentProfile != null && currentProfile['avatar_url'] == null) {
            await _supabase
                .from('profiles')
                .update({'avatar_url': googleUser.photoUrl})
                .eq('id', response.user!.id);
            debugPrint('Successfully synced Google profile picture.');
          }
        } catch (e) {
          debugPrint('Notice: Could not sync Google photo: $e');
        }
      }

      debugPrint('8. Supabase sign-in successful! User ID: ${response.user?.id}');
      return response;

    } on GoogleSignInException catch (e) {
      debugPrint('!!! GoogleSignInException Caught !!!');
      debugPrint('Error Code: ${e.code}');
      debugPrint('Error Message: ${e.description}');

      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw InvalidInputException('Sign-in canceled by user.');
      }
      throw FetchDataException(e.description ?? e.code.name);
    } catch (e, stackTrace) {
      debugPrint('!!! General Exception Caught in Repository !!!');
      debugPrint('Error: $e');
      debugPrint('Stacktrace: $stackTrace');
      throw _handleError(e);
    }
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SharedPrefManager {
  static const String _keyLastScreen = 'last_active_screen';
  static const String _keyLegalAcceptance = 'has_accepted_legal';
  static const String _keyIsFirstLaunch = 'is_first_launch';
  static const String _keyHasSeenTierSelection = 'has_seen_tier_selection';
  static const String _keyUserTier = 'user_tier';
  static const String _keyCustomApiKey = 'custom_api_key';

  final _secureStorage = const FlutterSecureStorage();

  Future<void> saveLastActiveScreen(String routeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastScreen, routeName);
  }

  Future<String?> getLastActiveScreen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastScreen);
  }

  Future<void> saveLegalAcceptance(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLegalAcceptance, value);
  }

  Future<bool> hasAcceptedLegal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLegalAcceptance) ?? false;
  }

  Future<bool> isFirstTimeLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsFirstLaunch) ?? true;
  }

  Future<void> completeFirstTimeLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsFirstLaunch, false);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastScreen);
  }

  Future<bool> hasSeenTierSelection() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenTierSelection) ?? false;
  }

  Future<void> completeTierSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenTierSelection, true);
  }

  Future<void> saveUserTier(String tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserTier, tier);
  }

  Future<String> getUserTier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserTier) ?? 'free';
  }

  Future<void> saveCustomApiKey(String apiKey) async {
    await _secureStorage.write(key: _keyCustomApiKey, value: apiKey);
  }

  Future<String?> getCustomApiKey() async {
    return await _secureStorage.read(key: _keyCustomApiKey);
  }

  Future<void> deleteCustomApiKey() async {
    await _secureStorage.delete(key: _keyCustomApiKey);
  }
}
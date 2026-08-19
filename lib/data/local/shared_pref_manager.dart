import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefManager {
  static const String _keyLastScreen = 'last_active_screen';
  static const String _keyLegalAcceptance = 'has_accepted_legal';
  static const String _keyIsFirstLaunch = 'is_first_launch';
  static const String _keyHasSeenTierSelection = 'has_seen_tier_selection';
  static const String _keyUserTier = 'user_tier';
  static const String _keyCustomApiKey = 'custom_api_key';

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

  // --- BYOK & Tier Methods ---
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomApiKey, apiKey);
  }

  Future<String?> getCustomApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCustomApiKey);
  }
}
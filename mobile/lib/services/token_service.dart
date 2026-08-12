import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _keyAccessToken = "rafiki_access_token";
  static const String _keyRefreshToken = "rafiki_refresh_token";
  static const String _keyParentName = "rafiki_parent_name";
  static const String _keyParentEmail = "rafiki_parent_email";

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String parentName,
    required String parentEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
    await prefs.setString(_keyParentName, parentName);
    await prefs.setString(_keyParentEmail, parentEmail);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  static Future<String?> getParentName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyParentName);
  }

  static Future<String?> getParentEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyParentEmail);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyParentName);
    await prefs.remove(_keyParentEmail);
  }
}

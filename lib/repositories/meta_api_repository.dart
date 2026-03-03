import 'package:shared_preferences/shared_preferences.dart';

class MetaApiRepository {
  static const _keyAccessToken = 'meta_access_token';
  static const _keyPhoneId = 'meta_phone_id';
  static const _keyBusinessId = 'meta_business_id';

  Future<void> saveCredentials({
    required String accessToken,
    required String phoneId,
    required String businessId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyPhoneId, phoneId);
    await prefs.setString(_keyBusinessId, businessId);
  }

  Future<Map<String, String?>> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'accessToken': prefs.getString(_keyAccessToken),
      'phoneId': prefs.getString(_keyPhoneId),
      'businessId': prefs.getString(_keyBusinessId),
    };
  }

  Future<bool> hasCredentials() async {
    final creds = await getCredentials();
    return creds['accessToken'] != null &&
        creds['phoneId'] != null &&
        creds['businessId'] != null;
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyPhoneId);
    await prefs.remove(_keyBusinessId);
  }
}

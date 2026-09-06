import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class SecureStorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveAuthToken(String token) async {
    await _prefs?.setString(AppConstants.keyAuthToken, token);
  }

  String? getAuthToken() {
    return _prefs?.getString(AppConstants.keyAuthToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _prefs?.setString(AppConstants.keyRefreshToken, token);
  }

  String? getRefreshToken() {
    return _prefs?.getString(AppConstants.keyRefreshToken);
  }

  Future<void> saveTenantId(String tenantId) async {
    await _prefs?.setString(AppConstants.keyCurrentTenantId, tenantId);
  }

  String? getTenantId() {
    return _prefs?.getString(AppConstants.keyCurrentTenantId);
  }

  Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs?.setBool(AppConstants.keyHasSeenOnboarding, value);
  }

  bool getHasSeenOnboarding() {
    return _prefs?.getBool(AppConstants.keyHasSeenOnboarding) ?? false;
  }

  Future<void> clearAll() async {
    await _prefs?.remove(AppConstants.keyAuthToken);
    await _prefs?.remove(AppConstants.keyRefreshToken);
    await _prefs?.remove(AppConstants.keyCurrentTenantId);
    await _prefs?.remove(AppConstants.keyUserSession);
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'models/login_request.dart';
import 'models/login_response.dart';
import 'services/auth_service.dart';

const _kIsLoggedIn = 'isLoggedIn';
const _kAuthResponse = 'auth_response_json';
const _kUserEmail = 'userEmail';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isInitialized = false;

  AuthData? _authData;
  String _userEmail = '';
  Map<String, dynamic> _authResponseData = {};

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  AuthData? get authData => _authData;
  String get userEmail => _userEmail;
  String get userName => _deriveDisplayName(_userEmail.isNotEmpty ? _userEmail : (_authData?.user.id ?? ''));
  String get userRole => _authData?.user.role ?? '';
  String get userId => _authData?.user.id ?? '';
  String get activeClinicId => _authData?.user.activeClinicId ?? _authData?.user.activeClinic?.clinicId ?? '';
  String get activeClinicName => _authData?.user.activeClinic?.clinicName ?? '';
  String get accessToken => _authData?.accessToken ?? '';
  Map<String, dynamic> get authResponseData => _authResponseData;

  AuthProvider() {
    _loadStoredAuth();
    ApiClient.instance.onForceLogout = () => logout(silent: true);
  }

  Future<void> _loadStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_kIsLoggedIn) ?? false;
    if (_isLoggedIn) {
      final jsonStr = prefs.getString(_kAuthResponse);
      _userEmail = prefs.getString(_kUserEmail) ?? '';
      if (jsonStr != null) {
        _parseAndApply(jsonDecode(jsonStr) as Map<String, dynamic>);
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  // ── Static organiser admin credentials (demo/dev only) ─────────────────────
  static const _kOrgAdminEmail = 'admin@thoughtgreenhealth.com';
  static const _kOrgAdminPassword = 'Admin@1234';

  static final Map<String, dynamic> _orgAdminStaticData = {
    'access_token': 'static_org_admin_token',
    'access_token_expires_at': '2099-01-01T00:00:00Z',
    'refresh_token': 'static_org_admin_refresh',
    'refresh_token_expires_at': '2099-01-01T00:00:00Z',
    'csrf_token': 'static_csrf',
    'active_device_count': 1,
    'requires_clinic_selection': false,
    'user': {
      'id': 'org-admin-static-001',
      'role': 'organiser_admin',
      'clinic_memberships': [],
      'active_clinic_id': null,
    },
  };

  /// Called directly from the login screen for static org admin credentials.
  /// Sets auth state and persists to SharedPreferences — no network call made.
  Future<void> loginAsOrgAdmin(String email) async {
    _authData = AuthData.fromJson(_orgAdminStaticData);
    _authResponseData = _orgAdminStaticData;
    _userEmail = email;
    _isLoggedIn = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsLoggedIn, true);
    await prefs.setString(_kUserEmail, _userEmail);
    await prefs.setString(_kAuthResponse, jsonEncode(_orgAdminStaticData));

    notifyListeners();
  }

  Future<String?> login(String identifier, String password) async {
    final email = identifier.trim().toLowerCase();

    // Static bypass: organiser admin credentials never hit the real API
    if (email == _kOrgAdminEmail && password == _kOrgAdminPassword) {
      _authData = AuthData.fromJson(_orgAdminStaticData);
      _authResponseData = _orgAdminStaticData;
      _userEmail = email;
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsLoggedIn, true);
      await prefs.setString(_kUserEmail, _userEmail);
      await prefs.setString(_kAuthResponse, jsonEncode(_orgAdminStaticData));

      notifyListeners();
      return null;
    }

    // All other credentials → real API
    try {
      final result = await AuthService.instance.login(
        LoginRequest(identifier: identifier, password: password),
      );

      _authData = result.authData;
      _authResponseData = result.rawData;
      _userEmail = email;
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsLoggedIn, true);
      await prefs.setString(_kUserEmail, _userEmail);
      await prefs.setString(_kAuthResponse, jsonEncode(result.rawData));
      await prefs.setString('access_token', _authData!.accessToken);
      await prefs.setString('refresh_token', _authData!.refreshToken);

      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> logout({bool silent = false}) async {
    if (!silent && _authData?.refreshToken != null && _authData!.refreshToken.isNotEmpty) {
      await AuthService.instance.logout(_authData!.refreshToken);
    }

    _isLoggedIn = false;
    _authData = null;
    _userEmail = '';
    _authResponseData = {};

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  void _parseAndApply(Map<String, dynamic> rawJsonMap) {
    _authResponseData = rawJsonMap;
    _authData = AuthData.fromJson(rawJsonMap);
  }

  String _deriveDisplayName(String identifier) {
    if (!identifier.contains('@')) return identifier;
    final local = identifier.split('@').first;
    return local.isNotEmpty ? '${local[0].toUpperCase()}${local.substring(1)}' : identifier;
  }
}

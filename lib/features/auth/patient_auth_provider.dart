import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_constants.dart';
import '../../core/network/api_exception.dart';
import 'models/patient_auth_models.dart';
import 'services/patient_auth_service.dart';

const _kIsLoggedIn = 'isLoggedIn';
const _kPatientData = 'patient_data_json';
const _kMobileNumber = 'patient_mobile';

class PatientAuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isInitialized = false;

  PatientLoginResponse? _loginData;
  String _mobileNumber = '';

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  PatientLoginResponse? get loginData => _loginData;
  String get mobileNumber => _mobileNumber;
  String get accessToken => _loginData?.tokens.accessToken ?? '';
  String get userId => _loginData?.principal.userId ?? '';
  String get orgId => _loginData?.principal.orgId ?? ApiConstants.defaultOrgId;
  String get userRole => _loginData?.principal.role ?? '';
  String get patientEmail => _loginData?.principal.email ?? '';
  String get patientName => _loginData?.principal.name ?? 'Guest User';

  PatientAuthProvider() {
    _loadStoredAuth();
    ApiClient.instance.onForceLogout = () => logout(silent: true);
  }

  Future<void> _loadStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_kIsLoggedIn) ?? false;
    if (_isLoggedIn) {
      final jsonStr = prefs.getString(_kPatientData);
      _mobileNumber = prefs.getString(_kMobileNumber) ?? '';
      if (jsonStr != null) {
        try {
          _loginData = PatientLoginResponse.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>,
          );
        } catch (_) {
          _isLoggedIn = false;
        }
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  // ── Step 1: Check mobile profile ──────────────────────────────────────────

  /// Returns null on success, error message on failure.
  Future<({String? error, CheckProfileResponse? data})> checkProfile(
    String mobile,
  ) async {
    try {
      final data = await PatientAuthService.instance.checkProfileVerified(
        mobile,
      );
      return (error: null, data: data);
    } on ApiException catch (e) {
      return (error: e.message, data: null);
    } catch (_) {
      return (error: 'Unexpected error. Please try again.', data: null);
    }
  }

  // ── Step 2: Verify OTP ────────────────────────────────────────────────────

  Future<String?> verifyOtp(String mobile, String otp) async {
    try {
      await PatientAuthService.instance.verifyOtp(mobile, otp);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'OTP verification failed. Please try again.';
    }
  }

  // ── Step 2b: Resend OTP ───────────────────────────────────────────────────

  Future<String?> resendOtp(String mobile) async {
    try {
      await PatientAuthService.instance.resendOtp(mobile);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Failed to resend OTP.';
    }
  }

  // ── Step 3: Patient Login ─────────────────────────────────────────────────

  Future<String?> login({
    required String mobile,
    required String password,
    required bool isFirstTimeLogin,
  }) async {
    try {
      final result = await PatientAuthService.instance.patientLogin(
        mobileNumber: mobile,
        password: password,
        isFirstTimeLogin: isFirstTimeLogin,
        orgId: ApiConstants.defaultOrgId,
      );

      _loginData = result;
      _mobileNumber = mobile;
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsLoggedIn, true);
      await prefs.setString(_kMobileNumber, mobile);
      await prefs.setString(
        _kPatientData,
        jsonEncode({
          'tokens': {
            'access_token': result.tokens.accessToken,
            'refresh_token': result.tokens.refreshToken,
          },
          'principal': {
            'user_id': result.principal.userId,
            'org_id': result.principal.orgId,
            'profile_id': result.principal.profileId,
            'email': result.principal.email,
            'name': result.principal.name,
            'role': result.principal.role,
            'status': result.principal.status,
            'session_id': result.principal.sessionId,
          },
        }),
      );
      await prefs.setString('access_token', result.tokens.accessToken);
      await prefs.setString('refresh_token', result.tokens.refreshToken);

      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout({bool silent = false}) async {
    _isLoggedIn = false;
    _loginData = null;
    _mobileNumber = '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }
}

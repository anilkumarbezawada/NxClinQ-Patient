import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../models/patient_auth_models.dart';

class PatientAuthService {
  PatientAuthService._();
  static final PatientAuthService instance = PatientAuthService._();

  /// POST /api/v1/patients/check_profile_verified
  Future<CheckProfileResponse> checkProfileVerified(String mobileNumber) async {
    final rawJson = await ApiClient.instance.post(
      ApiConstants.checkPatientProfile,
      data: {'mobile_number': mobileNumber},
      options: Options(headers: {'Authorization': null}),
    );
    final response = ApiResponse<CheckProfileResponse>.fromJson(
      rawJson,
      CheckProfileResponse.fromJson,
    );
    if (!response.success || response.data == null) {
      throw ApiException.fromApiError(
        code: response.error?.code ?? 'CHECK_ERROR',
        message: response.error?.message ?? 'Failed to verify mobile number.',
      );
    }
    return response.data!;
  }

  /// POST /api/v1/patients/verify_otp
  Future<void> verifyOtp(String mobileNumber, String otpCode) async {
    final rawJson = await ApiClient.instance.post(
      ApiConstants.verifyPatientOtp,
      data: {'mobile_number': mobileNumber, 'otp_code': otpCode},
      options: Options(headers: {'Authorization': null}),
    );
    final response = ApiResponse<Map<String, dynamic>>.fromJson(
      rawJson,
      (json) => json,
    );
    if (!response.success) {
      throw ApiException.fromApiError(
        code: response.error?.code ?? 'OTP_ERROR',
        message: response.error?.message ?? 'OTP verification failed.',
      );
    }
  }

  /// POST /api/v1/patients/resend_otp
  Future<void> resendOtp(String mobileNumber) async {
    final rawJson = await ApiClient.instance.post(
      ApiConstants.resendPatientOtp,
      data: {'mobile_number': mobileNumber},
      options: Options(headers: {'Authorization': null}),
    );
    final response = ApiResponse<Map<String, dynamic>>.fromJson(
      rawJson,
      (json) => json,
    );
    if (!response.success) {
      throw ApiException.fromApiError(
        code: response.error?.code ?? 'RESEND_ERROR',
        message: response.error?.message ?? 'Failed to resend OTP.',
      );
    }
  }

  /// POST /api/v1/patients/login
  Future<PatientLoginResponse> patientLogin({
    required String mobileNumber,
    required String password,
    required bool isFirstTimeLogin,
    required String orgId,
  }) async {
    final rawJson = await ApiClient.instance.post(
      ApiConstants.patientLogin,
      data: {
        'mobile_number': mobileNumber,
        'password': password,
        //'is_first_time_login': isFirstTimeLogin,
        'org_id': orgId,
      },
      options: Options(headers: {'Authorization': null}),
    );
    final response = ApiResponse<PatientLoginResponse>.fromJson(
      rawJson,
      PatientLoginResponse.fromJson,
    );
    if (!response.success || response.data == null) {
      throw ApiException.fromApiError(
        code: response.error?.code ?? 'LOGIN_ERROR',
        message: response.error?.message ?? 'Login failed. Please try again.',
      );
    }
    return response.data!;
  }
}

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class LoginResult {
  final AuthData authData;
  final Map<String, dynamic> rawData;
  const LoginResult({required this.authData, required this.rawData});
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Future<LoginResult> login(LoginRequest request) async {
    final rawJson = await ApiClient.instance.post(
      ApiConstants.login,
      data: request.toJson(),
      options: Options(headers: {'Authorization': null}),
    );

    final response = ApiResponse<AuthData>.fromJson(rawJson, AuthData.fromJson);

    if (!response.success || response.data == null) {
      throw ApiException.fromApiError(
        code: response.error?.code ?? 'AUTH_ERROR',
        message: response.error?.message ?? 'Login failed. Please check your credentials.',
      );
    }

    final rawData = rawJson['data'] as Map<String, dynamic>? ?? {};
    return LoginResult(authData: response.data!, rawData: rawData);
  }

  Future<void> logout(String refreshToken) async {
    try {
      final rawJson = await ApiClient.instance.post(
        ApiConstants.logout,
        data: {'refresh_token': refreshToken},
      );

      final response = ApiResponse<Map<String, dynamic>>.fromJson(
        rawJson,
        (json) => json,
      );

      if (!response.success && response.error != null) {
        if (response.error!.code == 'AUTH_REFRESH_INVALID') return;
        throw ApiException.fromApiError(
          code: response.error!.code,
          message: response.error!.message,
        );
      }
    } catch (_) {
      // Any failure during logout — just proceed with local logout
    }
  }
}

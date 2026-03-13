import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';
import 'api_exception.dart';
import 'network_checker.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  VoidCallback? onForceLogout;

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )
    ..interceptors.add(_authInterceptor())
    ..interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final statusCode = error.response?.statusCode;
        final errorCode = _extractErrorCode(error.response?.data);

        final isLoginEndpoint = error.requestOptions.path == ApiConstants.login;
        // Don't intercept 401s on the login endpoint itself; let them fail through
        // so the UI can show "Invalid credentials"
        final is401 = statusCode == 401 || errorCode == 'AUTH_UNAUTHORIZED' || errorCode == 'UNAUTHORIZED';
        final isRefreshEndpoint = error.requestOptions.path == ApiConstants.refreshToken;

        if (is401 && !isRefreshEndpoint && !isLoginEndpoint) {
          final refreshed = await _tryRefreshTokens();
          if (refreshed) {
            final retryResponse = await _retry(error.requestOptions);
            handler.resolve(retryResponse);
          } else {
            onForceLogout?.call();
            handler.next(error);
          }
        } else {
          handler.next(error);
        }
      },
    );
  }

  String? _extractErrorCode(dynamic data) {
    if (data is Map<String, dynamic>) {
      final err = data['error'];
      if (err is Map<String, dynamic>) {
        return err['code'] as String?;
      }
    }
    return null;
  }

  Future<bool> _tryRefreshTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) return false;

      final newAccessToken = data['access_token'] as String?;
      final newRefreshToken = data['refresh_token'] as String?;
      if (newAccessToken == null) return false;

      await prefs.setString('access_token', newAccessToken);
      if (newRefreshToken != null) {
        await prefs.setString('refresh_token', newRefreshToken);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: {
          ...requestOptions.headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await NetworkChecker.assertConnected();
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data ?? {};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await NetworkChecker.assertConnected();
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data ?? {};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    await NetworkChecker.assertConnected();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return response.data ?? {};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    await NetworkChecker.assertConnected();
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        path,
        data: data,
      );
      return response.data ?? {};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    await NetworkChecker.assertConnected();
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        path,
        data: data,
      );
      return response.data ?? {};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ApiException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return ApiException.timeout();
      case DioExceptionType.connectionError:
        return ApiException.noInternet();
      case DioExceptionType.badResponse:
        final responseData = e.response?.data;
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('error') && responseData['error'] is Map<String, dynamic>) {
            final errorBody = responseData['error'] as Map<String, dynamic>;
            return ApiException.fromApiError(
              code: errorBody['code'] as String? ?? 'SERVER_ERROR',
              message: errorBody['message'] as String? ?? 'An error occurred.',
              statusCode: e.response?.statusCode,
            );
          }
          // Fallback for flat structure
          return ApiException.fromApiError(
            code: responseData['code'] as String? ?? 'SERVER_ERROR',
            message: responseData['message'] as String? ?? 'An error occurred.',
            statusCode: e.response?.statusCode,
          );
        }
        return ApiException.serverError(
          'Server responded with status ${e.response?.statusCode}',
        );
      default:
        return ApiException.unknown();
    }
  }
}

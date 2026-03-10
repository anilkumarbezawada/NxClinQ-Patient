/// Central place for all API configuration constants.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://10.10.10.117:8000';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/api/v1/auth/login';
  static const String refreshToken = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';
}

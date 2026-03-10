/// Typed exception for every network/API failure the app can encounter.
class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  // ── Named constructors for common cases ───────────────────────────────────

  factory ApiException.noInternet() => const ApiException(
        code: 'NO_INTERNET',
        message: 'No internet connection. Please check your network and try again.',
      );

  factory ApiException.timeout() => const ApiException(
        code: 'TIMEOUT',
        message: 'The request timed out. Please try again.',
      );

  factory ApiException.serverError([String? detail]) => ApiException(
        code: 'SERVER_ERROR',
        message: detail ?? 'A server error occurred. Please try again later.',
        statusCode: 500,
      );

  factory ApiException.fromApiError({
    required String code,
    required String message,
    int? statusCode,
  }) =>
      ApiException(code: code, message: message, statusCode: statusCode);

  factory ApiException.unknown() => const ApiException(
        code: 'UNKNOWN',
        message: 'An unexpected error occurred.',
      );

  @override
  String toString() => 'ApiException[$code]: $message';
}

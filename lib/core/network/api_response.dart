/// Generic wrapper that mirrors the server envelope:
/// { "success": bool, "data": T | null, "error": ApiErrorBody | null, "request_id": String }
class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiErrorBody? error;
  final String? requestId;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.requestId,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? dataFromJson,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: (json['data'] != null && dataFromJson != null)
          ? dataFromJson(json['data'] as Map<String, dynamic>)
          : null,
      error: json['error'] != null
          ? ApiErrorBody.fromJson(json['error'] as Map<String, dynamic>)
          : null,
      requestId: json['request_id'] as String?,
    );
  }
}

/// The `error` body inside a failed API response.
class ApiErrorBody {
  final String code;
  final String message;
  final Map<String, dynamic> details;

  const ApiErrorBody({
    required this.code,
    required this.message,
    required this.details,
  });

  factory ApiErrorBody.fromJson(Map<String, dynamic> json) {
    return ApiErrorBody(
      code: json['code'] as String? ?? 'UNKNOWN',
      message: json['message'] as String? ?? 'An error occurred.',
      details: json['details'] as Map<String, dynamic>? ?? {},
    );
  }
}

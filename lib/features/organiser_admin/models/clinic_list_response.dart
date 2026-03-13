import 'org_dashboard_response.dart';

class ClinicListResponse {
  final bool success;
  final String? message;
  final List<OrgClinic> data;
  final String? error;
  final String? requestId;

  ClinicListResponse({
    required this.success,
    this.message,
    required this.data,
    this.error,
    this.requestId,
  });

  factory ClinicListResponse.fromJson(Map<String, dynamic> json) {
    return ClinicListResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => OrgClinic.fromJson(e))
              .toList() ??
          [],
      error: json['error'],
      requestId: json['request_id'],
    );
  }
}

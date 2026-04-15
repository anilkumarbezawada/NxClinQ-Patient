class LeadListResponse {
  final bool success;
  final String? message;
  final List<LeadInfo> data;
  final String? error;
  final String? requestId;

  LeadListResponse({
    required this.success,
    this.message,
    required this.data,
    this.error,
    this.requestId,
  });

  factory LeadListResponse.fromJson(Map<String, dynamic> json) {
    return LeadListResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => LeadInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      error: json['error'] as String?,
      requestId: json['request_id'] as String?,
    );
  }
}

class LeadInfo {
  final String leadId;
  final String orgId;
  final String name;
  final String patientName;
  final String mobileNo;
  final String? doctorId;
  final String? clinicId;
  final String? doctorName;
  final String? clinicName;
  final String? preferredDate;
  final String? preferredTime;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  LeadInfo({
    required this.leadId,
    required this.orgId,
    required this.name,
    required this.patientName,
    required this.mobileNo,
    this.doctorId,
    this.clinicId,
    this.doctorName,
    this.clinicName,
    this.preferredDate,
    this.preferredTime,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory LeadInfo.fromJson(Map<String, dynamic> json) {
    return LeadInfo(
      leadId: json['lead_id'] as String? ?? '',
      orgId: json['org_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      patientName: json['patient_name'] as String? ?? '',
      mobileNo: json['mobile_no'] as String? ?? '',
      doctorId: json['doctor_id'] as String?,
      clinicId: json['clinic_id'] as String?,
      doctorName: json['doctor_name'] as String?,
      clinicName: json['clinic_name'] as String?,
      preferredDate: json['preferred_date'] as String?,
      preferredTime: json['preferred_time'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

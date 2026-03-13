class DoctorListResponse {
  final bool success;
  final String? message;
  final List<DoctorModel> data;
  final String? error;
  final String? requestId;

  DoctorListResponse({
    required this.success,
    this.message,
    required this.data,
    this.error,
    this.requestId,
  });

  factory DoctorListResponse.fromJson(Map<String, dynamic> json) {
    return DoctorListResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => DoctorModel.fromJson(e))
              .toList() ??
          [],
      error: json['error'],
      requestId: json['request_id'],
    );
  }
}

class DoctorModel {
  final String id;
  final String orgId;
  final String userId;
  final String fullName;
  final String? prefix;
  final String? phone;
  final String? specialty;
  final String? qualification;
  final String? title;
  final String? experience;
  final String? description;
  final String? status;
  final String? gender;
  final String? createdAt;
  final String? updatedAt;

  DoctorModel({
    required this.id,
    required this.orgId,
    required this.userId,
    required this.fullName,
    this.prefix,
    this.phone,
    this.specialty,
    this.qualification,
    this.title,
    this.experience,
    this.description,
    this.status,
    this.gender,
    this.createdAt,
    this.updatedAt,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] ?? '',
      orgId: json['org_id'] ?? '',
      userId: json['user_id'] ?? '',
      fullName: json['full_name'] ?? 'Unknown',
      prefix: json['prefix'],
      phone: json['phone'] as String?,
      specialty: json['specialty'] as String?,
      qualification: json['qualification'] as String?,
      title: json['title'] as String?,
      experience: json['experience'] as String?,
      description: json['description'] as String?,
      status: json['status'] as String?,
      gender: json['gender'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

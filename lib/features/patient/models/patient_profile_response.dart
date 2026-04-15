class PatientProfileResponse {
  final bool success;
  final String? message;
  final List<PatientProfile> data;
  final dynamic error;
  final String? requestId;

  PatientProfileResponse({
    required this.success,
    this.message,
    required this.data,
    this.error,
    this.requestId,
  });

  factory PatientProfileResponse.fromJson(Map<String, dynamic> json) {
    return PatientProfileResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => PatientProfile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      error: json['error'],
      requestId: json['request_id'] as String?,
    );
  }
}

class PatientProfile {
  final String id;
  final String name;
  final int? age;
  final String? emailId;
  final String mobileNumber;
  final String? gender;
  final String? location;
  final bool? isProfileVerified;
  final String? createdAt;
  final String? updatedAt;

  PatientProfile({
    required this.id,
    required this.name,
    this.age,
    this.emailId,
    required this.mobileNumber,
    this.gender,
    this.location,
    this.isProfileVerified,
    this.createdAt,
    this.updatedAt,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      age: json['age'] as int?,
      emailId: json['email_id'] as String?,
      mobileNumber: json['mobile_number'] as String? ?? '',
      gender: json['gender'] as String?,
      location: json['location'] as String?,
      isProfileVerified: json['is_profile_verified'] as bool?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

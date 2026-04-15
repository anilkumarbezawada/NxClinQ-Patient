import 'doctor_list_response.dart';

class DoctorInfoResponse {
  final bool success;
  final String? message;
  final DoctorInfoData? data;
  final String? error;
  final String? requestId;

  DoctorInfoResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
    this.requestId,
  });

  factory DoctorInfoResponse.fromJson(Map<String, dynamic> json) {
    return DoctorInfoResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null ? DoctorInfoData.fromJson(json['data']) : null,
      error: json['error'],
      requestId: json['request_id'],
    );
  }
}

class DoctorInfoData {
  final DoctorModel? doctorInfo;
  final List<DoctorPractisingClinic> practisingClinics;

  DoctorInfoData({this.doctorInfo, this.practisingClinics = const []});

  factory DoctorInfoData.fromJson(Map<String, dynamic> json) {
    return DoctorInfoData(
      doctorInfo: json['doctor_info'] != null
          ? DoctorModel.fromJson(json['doctor_info'])
          : null,
      practisingClinics:
          (json['practising_clinics'] as List<dynamic>?)
              ?.map(
                (e) =>
                    DoctorPractisingClinic.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}

class DoctorPractisingClinic {
  final String id;
  final String name;
  final String clinicLocation;
  final String status;

  const DoctorPractisingClinic({
    required this.id,
    required this.name,
    required this.clinicLocation,
    required this.status,
  });

  factory DoctorPractisingClinic.fromJson(Map<String, dynamic> json) {
    return DoctorPractisingClinic(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      clinicLocation: json['clinic_location']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

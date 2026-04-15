class OrgDashboardResponse {
  final bool success;
  final OrgDashboardData? data;
  final String? error;
  final String? requestId;

  OrgDashboardResponse({
    required this.success,
    this.data,
    this.error,
    this.requestId,
  });

  factory OrgDashboardResponse.fromJson(Map<String, dynamic> json) {
    return OrgDashboardResponse(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? OrgDashboardData.fromJson(json['data'])
          : null,
      error: json['error'],
      requestId: json['request_id'],
    );
  }
}

class OrgDashboardData {
  final String orgName;
  final OrgOverview overview;

  OrgDashboardData({required this.orgName, required this.overview});

  factory OrgDashboardData.fromJson(Map<String, dynamic> json) {
    return OrgDashboardData(
      orgName: json['org_name'] ?? 'Organisation',
      overview: json['overview'] != null
          ? OrgOverview.fromJson(json['overview'])
          : OrgOverview(doctors: [], clinics: []),
    );
  }
}

class OrgOverview {
  final List<OrgDoctor> doctors;
  final List<OrgClinic> clinics;

  OrgOverview({required this.doctors, required this.clinics});

  factory OrgOverview.fromJson(Map<String, dynamic> json) {
    final doctorsList = json['doctors'] as List<dynamic>? ?? [];
    final clinicsList = json['clinics'] as List<dynamic>? ?? [];

    return OrgOverview(
      doctors: doctorsList.map((e) => OrgDoctor.fromJson(e)).toList(),
      clinics: clinicsList.map((e) => OrgClinic.fromJson(e)).toList(),
    );
  }
}

class OrgDoctor {
  final String id;
  final String doctorTitle;
  final String doctorName;
  final String speciality;

  OrgDoctor({
    required this.id,
    required this.doctorTitle,
    required this.doctorName,
    required this.speciality,
  });

  factory OrgDoctor.fromJson(Map<String, dynamic> json) {
    return OrgDoctor(
      id: json['id'] ?? '',
      doctorTitle: json['doctor_title'] ?? '',
      doctorName: json['doctor_name'] ?? 'Unknown Doctor',
      speciality: json['speciality'] ?? '',
    );
  }
}

class OrgClinic {
  final String id;
  final String name;
  final String clinicLocation;
  final String? clinicAddress;
  final String? phone;
  final String status;
  final dynamic avalibleDoctors;

  OrgClinic({
    required this.id,
    required this.name,
    required this.clinicLocation,
    this.clinicAddress,
    this.phone,
    required this.status,
    this.avalibleDoctors,
  });

  factory OrgClinic.fromJson(Map<String, dynamic> json) {
    return OrgClinic(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Clinic',
      clinicLocation: json['clinic_location'] ?? '',
      clinicAddress: json['clinic_address'],
      phone: json['phone'],
      avalibleDoctors: json['doctors_count'] ?? '',
      status: json['status'] ?? 'unknown',
    );
  }
}

class AppointmentsByDayResponse {
  final bool success;
  final String? message;
  final List<AppointmentData> data;
  final dynamic error;
  final String? requestId;

  AppointmentsByDayResponse({
    required this.success,
    this.message,
    required this.data,
    this.error,
    this.requestId,
  });

  factory AppointmentsByDayResponse.fromJson(Map<String, dynamic> json) {
    return AppointmentsByDayResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => AppointmentData.fromJson(e))
              .toList() ??
          [],
      error: json['error'],
      requestId: json['request_id'],
    );
  }
}

class AppointmentData {
  final String id;
  final String? schedulerBookingId;
  final AppointmentPatient? patient;
  final String doctorId;
  final String doctorName;
  final String clinicId;
  final String clinicName;
  final String source;
  final String appointmentTime;
  final String appointmentTimeLocal;
  final String timezone;
  final String status;
  final String appointmentType;
  final String? encounterId;
  final String? encounterStatus;
  final String? createdAt;
  final String? updatedAt;

  AppointmentData({
    required this.id,
    this.schedulerBookingId,
    this.patient,
    required this.doctorId,
    required this.doctorName,
    required this.clinicId,
    required this.clinicName,
    required this.source,
    required this.appointmentTime,
    required this.appointmentTimeLocal,
    required this.timezone,
    required this.status,
    required this.appointmentType,
    this.encounterId,
    this.encounterStatus,
    this.createdAt,
    this.updatedAt,
  });

  factory AppointmentData.fromJson(Map<String, dynamic> json) {
    return AppointmentData(
      id: json['id'] ?? '',
      schedulerBookingId: json['scheduler_booking_id'],
      patient: json['patient'] != null
          ? AppointmentPatient.fromJson(json['patient'])
          : null,
      doctorId: json['doctor_id'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      clinicId: json['clinic_id'] ?? '',
      clinicName: json['clinic_name'] ?? '',
      source: json['source'] ?? '',
      appointmentTime: json['appointment_time'] ?? '',
      appointmentTimeLocal: json['appointment_time_local'] ?? '',
      timezone: json['timezone'] ?? '',
      status: json['status'] ?? '',
      appointmentType: json['appointment_type'] ?? '',
      encounterId: json['encounter_id'],
      encounterStatus: json['encounter_status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class AppointmentPatient {
  final String id;
  final String name;
  final String mobileNumber;

  AppointmentPatient({
    required this.id,
    required this.name,
    required this.mobileNumber,
  });

  factory AppointmentPatient.fromJson(Map<String, dynamic> json) {
    return AppointmentPatient(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      mobileNumber: json['mobile_number'] ?? '',
    );
  }
}

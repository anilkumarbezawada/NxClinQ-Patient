import 'package:intl/intl.dart';

class PatientAppointment {
  final String id;
  final DateTime appointmentTime;
  final DateTime appointmentTimeLocal;
  final String doctorName;
  final String doctorSpecialty;
  final String doctorExperience;
  final String doctorTitle;
  final String doctorQualification;
  final String clinicName;
  final String clinicLocation;
  final String status;
  final String appointmentType;
  final bool reportsGenerated;

  const PatientAppointment({
    required this.id,
    required this.appointmentTime,
    required this.appointmentTimeLocal,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.doctorExperience,
    required this.doctorTitle,
    required this.doctorQualification,
    required this.clinicName,
    required this.clinicLocation,
    required this.status,
    required this.appointmentType,
    this.reportsGenerated = false,
  });

  static DateTime _parseLocalTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return DateTime.now();
    try {
      // Strip timezone offset (e.g. +05:30) so Dart doesn't shift the hours
      // when formatting it on a device in a different timezone.
      // E.g. "2026-03-24T19:30:00+05:30" -> "2026-03-24T19:30:00"
      if (timeStr.length >= 19) {
        return DateTime.parse(timeStr.substring(0, 19));
      }
      return DateTime.parse(timeStr);
    } catch (_) {
      return DateTime.now();
    }
  }

  factory PatientAppointment.fromJson(Map<String, dynamic> json) {
    return PatientAppointment(
      id: json['id'] as String? ?? '',
      appointmentTime: _parseLocalTime(json['appointment_time'] as String?),
      appointmentTimeLocal: _parseLocalTime(json['appointment_time_local'] as String?),
      doctorName: json['doctor_name'] as String? ?? 'Unknown Doctor',
      doctorSpecialty: json['doctor_specialty'] as String? ?? '',
      doctorExperience: json['doctor_experience'] as String? ?? '',
      doctorTitle: json['doctor_title'] as String? ?? '',
      doctorQualification: json['doctor_qualification'] as String? ?? '',
      clinicName: json['clinic_name'] as String? ?? '',
      clinicLocation: json['clinic_location'] as String? ?? '',
      status: json['status'] as String? ?? 'scheduled',
      appointmentType: json['appointment_type'] as String? ?? '',
      reportsGenerated: json['reports_generated'] as bool? ?? false,
    );
  }

  String get formattedTime {
    return DateFormat('MMM d, yyyy • h:mm a').format(appointmentTimeLocal);
  }
}

class PatientAppointmentsData {
  final List<PatientAppointment> upcoming;
  final List<PatientAppointment> past;

  const PatientAppointmentsData({
    required this.upcoming,
    required this.past,
  });

  factory PatientAppointmentsData.fromJson(Map<String, dynamic> json) {
    final upcomingList = (json['upcoming'] as List<dynamic>?) ?? [];
    final pastList = (json['past'] as List<dynamic>?) ?? [];

    final upcoming = upcomingList
        .map((e) => PatientAppointment.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.appointmentTimeLocal.compareTo(b.appointmentTimeLocal));

    final past = pastList
        .map((e) => PatientAppointment.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.appointmentTimeLocal.compareTo(a.appointmentTimeLocal));

    return PatientAppointmentsData(
      upcoming: upcoming,
      past: past,
    );
  }
}

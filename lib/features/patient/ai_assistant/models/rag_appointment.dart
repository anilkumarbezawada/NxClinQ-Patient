import 'package:intl/intl.dart';

class RagAppointment {
  final String appointmentId;
  final String encounterId;
  final String appointmentTime;
  final String appointmentTimeLocal;
  final String doctorName;
  final String doctorSpecialty;
  final String doctorTitle;
  final String clinicName;
  final String clinicLocation;
  final String appointmentType;
  final String appointmentTypeDisplay;

  const RagAppointment({
    required this.appointmentId,
    required this.encounterId,
    required this.appointmentTime,
    required this.appointmentTimeLocal,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.doctorTitle,
    required this.clinicName,
    required this.clinicLocation,
    required this.appointmentType,
    required this.appointmentTypeDisplay,
  });

  factory RagAppointment.fromJson(Map<String, dynamic> json) {
    return RagAppointment(
      appointmentId: json['appointment_id'] as String? ?? '',
      encounterId: json['encounter_id'] as String? ?? '',
      appointmentTime: json['appointment_time'] as String? ?? '',
      appointmentTimeLocal: json['appointment_time_local'] as String? ?? '',
      doctorName: json['doctor_name'] as String? ?? '',
      doctorSpecialty: json['doctor_specialty'] as String? ?? '',
      doctorTitle: json['doctor_title'] as String? ?? '',
      clinicName: json['clinic_name'] as String? ?? '',
      clinicLocation: json['clinic_location'] as String? ?? '',
      appointmentType: json['appointment_type'] as String? ?? '',
      appointmentTypeDisplay: json['appointment_type_display'] as String? ?? '',
    );
  }

  String get formattedDate {
    try {
      final raw = appointmentTimeLocal.isNotEmpty
          ? appointmentTimeLocal
          : appointmentTime;
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return '--';
    }
  }

  String get formattedTime {
    try {
      final raw = appointmentTimeLocal.isNotEmpty
          ? appointmentTimeLocal
          : appointmentTime;
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return '--:--';
    }
  }

  static List<RagAppointment> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((e) => RagAppointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

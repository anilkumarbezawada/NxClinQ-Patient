import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../models/patient_appointment.dart';
import '../models/appointment_report.dart';

class PatientAppointmentService {
  PatientAppointmentService._();
  static final PatientAppointmentService instance = PatientAppointmentService._();

  Future<PatientAppointmentsData> getAppointments() async {
    final rawJson = await ApiClient.instance.get(
      ApiConstants.patientAppointments,
    );

    final response = ApiResponse<PatientAppointmentsData>.fromJson(
      rawJson,
      PatientAppointmentsData.fromJson,
    );

    if (!response.success || response.data == null) {
      throw ApiException.fromApiError(
        code: response.error?.code ?? 'APPOINTMENT_ERROR',
        message: response.error?.message ?? 'Failed to load appointments.',
      );
    }

    return response.data!;
  }

  Future<AppointmentReport> getAppointmentReport(String appointmentId) async {
    final rawJson = await ApiClient.instance.get(
      '${ApiConstants.patientAppointmentReports}?appointment_id=$appointmentId',
    );

    final response = ApiResponse<AppointmentReport>.fromJson(
      rawJson,
      AppointmentReport.fromJson,
    );

    if (!response.success || response.data == null) {
      throw ApiException.fromApiError(
        code: response.error?.code ?? 'REPORT_ERROR',
        message: response.error?.message ?? 'Failed to load appointment report.',
      );
    }

    return response.data!;
  }
}

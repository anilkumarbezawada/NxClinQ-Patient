import 'api_client.dart';
import 'network_checker.dart';
import 'api_exception.dart';
import 'api_constants.dart';
import '../../features/patient/models/org_dashboard_response.dart';
import '../../features/patient/models/clinic_list_response.dart';
import '../../features/patient/models/clinic_mapping_status_response.dart';
import '../../features/patient/models/doctor_list_response.dart';
import '../../features/patient/models/doctor_booking_board_response.dart';
import '../../features/patient/models/doctor_info_response.dart';
import '../../features/patient/models/specialty.dart';
import '../../features/patient/models/create_doctor_request.dart';
import '../../features/patient/models/patient_profile_response.dart';
import '../../features/patient/models/appointments_by_day_response.dart';


/// Centralized API Service for all NxClinQ endpoints (Clinic & Organiser)
class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  final _apiClient = ApiClient.instance;

  // ── Organiser Admin Endpoints ─────────────────────────────────────────────

  Future<OrgDashboardResponse> getOrgDashboardOverview() async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message:
            ApiException.noInternet().message,
      );
    }

    try {
      final response = await _apiClient.get(ApiConstants.commonDashboard);
      if (response['data'] != null) {
        return OrgDashboardResponse.fromJson(response);
      }
      return OrgDashboardResponse.fromJson(response);
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  // ── Clinic Endpoints ────────────────────────────────────────────────

  Future<ClinicListResponse> getClinics() async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message:
            ApiException.noInternet().message,
      );
    }
    try {
      final response = await _apiClient.get(ApiConstants.getClinics);
      return ClinicListResponse.fromJson(response);
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  Future<dynamic> createClinic(Map<String, dynamic> data) async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message:
            ApiException.noInternet().message,
      );
    }
    try {
      final response = await _apiClient.post(
        ApiConstants.createClinic,
        data: data,
      );
      return response;
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  Future<dynamic> updateClinic(
    String clinicId,
    Map<String, dynamic> data,
  ) async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message:
            ApiException.noInternet().message,
      );
    }
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.updateClinic}?clinic_id=$clinicId',
        data: data,
      );
      return response;
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  // ── Doctors Endpoints ────────────────────────────────────────────────

  Future<DoctorListResponse> getDoctors() async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message:
            ApiException.noInternet().message,
      );
    }
    try {
      final response = await _apiClient.get(ApiConstants.getDoctors);
      return DoctorListResponse.fromJson(response);
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  Future<DoctorInfoResponse> getDoctorInfo(String doctorId) async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message:
            ApiException.noInternet().message,
      );
    }
    try {
      final response = await _apiClient.get(
        '${ApiConstants.getDoctorInfo}?doctor_id=$doctorId',
      );
      return DoctorInfoResponse.fromJson(response);
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  Future<SpecialtiesResponse> getSpecialties() async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message:
            ApiException.noInternet().message,
      );
    }
    try {
      final response = await _apiClient.get(ApiConstants.specialties);
      return SpecialtiesResponse.fromJson(response);
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  Future<dynamic> createDoctor(CreateDoctorRequest request) async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message:
            ApiException.noInternet().message,
      );
    }
    try {
      final response = await _apiClient.post(
        ApiConstants.createDoctor,
        data: request.toJson(),
      );
      return response;
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  Future<Map<String, dynamic>> mapDoctorToClinics(
    String doctorId,
    List<String> clinicIds,
  ) async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message:
            ApiException.noInternet().message,
      );
    }
    try {
      final response = await _apiClient.post(
        '${ApiConstants.mapDoctorClinics}/$doctorId',
        data: {'clinic_ids': clinicIds},
      );
      return response;
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  Future<ClinicMappingStatusResponse> getClinicMappingStatus(
    String doctorId,
  ) async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message:
            ApiException.noInternet().message,
      );
    }
    try {
      final response = await _apiClient.get(
        ApiConstants.clinicMappingStatus,
        queryParameters: {'doctor_id': doctorId},
      );
      return ClinicMappingStatusResponse.fromJson(response);
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  Future<dynamic> configureDoctorCalendar(
    String doctorId,
    Map<String, dynamic> data,
  ) async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message:
            ApiException.noInternet().message,
      );
    }
    try {
      final response = await _apiClient.post(
        ApiConstants.configureCalendar(doctorId),
        data: data,
      );
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  Future<dynamic> createDoctorScheduleWindows(
    String doctorId,
    Map<String, dynamic> data,
  ) async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message:
            ApiException.noInternet().message,
      );
    }
    try {
      final response = await _apiClient.post(
        ApiConstants.createScheduleWindows(doctorId),
        data: data,
      );
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  Future<dynamic> getDoctorSchedulesByClinic(String clinicId) async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message:
            ApiException.noInternet().message,
      );
    }
    try {
      final response = await _apiClient.get(
        ApiConstants.doctorSchedulesByClinic(clinicId),
      );
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  // ── Leads & Patients ────────────────────────────────────────────────────────
  Future<PatientProfileResponse> getPatientProfiles() async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message: ApiException.noInternet().message,
      );
    }
    try {
      final response = await _apiClient.get(ApiConstants.listPatientProfiles);
      return PatientProfileResponse.fromJson(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  Future<dynamic> createPatientProfile(Map<String, dynamic> data) async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message: ApiException.noInternet().message,
      );
    }
    try {
      final response = await _apiClient.post(
        ApiConstants.createPatientProfile,
        data: data,
      );
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }
  Future<DoctorBookingBoardResponse> getDoctorBookingBoard(
    String doctorId,
    String clinicId,
    String date,
  ) async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message: ApiException.noInternet().message,
      );
    }
    try {
      final response = await _apiClient.get(
        ApiConstants.getBookingBoard(doctorId, clinicId),
        queryParameters: {'date': date},
      );
      return DoctorBookingBoardResponse.fromJson(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }
  Future<dynamic> createAppointment(Map<String, dynamic> data) async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message: ApiException.noInternet().message,
      );
    }
    try {
      final response = await _apiClient.post(
        ApiConstants.createAppointment,
        data: data,
      );
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  Future<AppointmentsByDayResponse> getAppointmentsByDay(
    String date,
    String timezone, {
    String? doctorId,
    String? clinicId,
  }) async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message: ApiException.noInternet().message,
      );
    }

    final queryParams = <String, dynamic>{
      'date': date,
      'timezone': timezone,
    };
    if (doctorId != null && doctorId.isNotEmpty) {
      queryParams['doctor_id'] = doctorId;
    }
    if (clinicId != null && clinicId.isNotEmpty) {
      queryParams['clinic_id'] = clinicId;
    }

    try {
      final response = await _apiClient.get(
        ApiConstants.getAppointmentsByDay,
        queryParameters: queryParams,
      );
      return AppointmentsByDayResponse.fromJson(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }
}

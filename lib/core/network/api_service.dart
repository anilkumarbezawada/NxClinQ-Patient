import 'api_client.dart';
import 'network_checker.dart';
import 'api_exception.dart';
import 'api_constants.dart';
import '../../features/patient/models/doctor_list_response.dart';
import '../../features/patient/models/doctor_booking_board_response.dart';
import '../../features/patient/models/doctor_info_response.dart';
import '../../features/patient/models/specialty.dart';
import '../../features/patient/models/clinic_mapping_status_response.dart';

/// Centralized API Service for NxClinQ patient booking endpoints.
class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  final _apiClient = ApiClient.instance;

  // ── Doctors ───────────────────────────────────────────────────────────────

  Future<DoctorListResponse> getDoctors() async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message: ApiException.noInternet().message,
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
        message: ApiException.noInternet().message,
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
        message: ApiException.noInternet().message,
      );
    }
    try {
      final response = await _apiClient.get(ApiConstants.specialties);
      return SpecialtiesResponse.fromJson(response);
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
        message: ApiException.noInternet().message,
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

  Future<Map<String, dynamic>> mapDoctorToClinics(
    String doctorId,
    List<String> clinicIds,
  ) async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(
        code: 'NO_INTERNET',
        message: ApiException.noInternet().message,
      );
    }
    try {
      final response = await _apiClient.post(
        '${ApiConstants.clinicMappingStatus}/$doctorId',
        data: {'clinic_ids': clinicIds},
      );
      return response;
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  // ── Booking ───────────────────────────────────────────────────────────────

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
}

import 'api_client.dart';
import 'network_checker.dart';
import 'api_exception.dart';
import 'api_constants.dart';
import '../../features/organiser_admin/models/org_dashboard_response.dart';
import '../../features/organiser_admin/models/clinic_list_response.dart';
import '../../features/organiser_admin/models/doctor_list_response.dart';

/// Centralized API Service for all Doctor CRM endpoints (Clinic & Organiser)
class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  final _apiClient = ApiClient.instance;

  // ── Organiser Admin Endpoints ─────────────────────────────────────────────

  Future<OrgDashboardResponse> getOrgDashboardOverview() async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(code: 'NO_INTERNET', message: 'No internet connection. Please check your network and try again.');
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
      throw ApiException(code: 'NO_INTERNET', message: 'No internet connection. Please check your network and try again.');
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
      throw ApiException(code: 'NO_INTERNET', message: 'No internet connection. Please check your network and try again.');
    }
    try {
      final response = await _apiClient.post(ApiConstants.createClinic, data: data);
      return response;
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  Future<dynamic> updateClinic(String clinicId, Map<String, dynamic> data) async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(code: 'NO_INTERNET', message: 'No internet connection. Please check your network and try again.');
    }
    try {
      final response = await _apiClient.patch('${ApiConstants.updateClinic}?clinic_id=$clinicId', data: data);
      return response;
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  // ── Doctors Endpoints ────────────────────────────────────────────────
  
  Future<DoctorListResponse> getDoctors() async {
    final hasConnection = await NetworkChecker.hasInternet();
    if (!hasConnection) {
      throw ApiException(code: 'NO_INTERNET', message: 'No internet connection. Please check your network and try again.');
    }
    try {
      final response = await _apiClient.get(ApiConstants.getDoctors);
      return DoctorListResponse.fromJson(response);
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

}

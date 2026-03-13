/// Central place for all API configuration constants.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://10.10.10.82:8000';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/api/v1/auth/login';
  static const String refreshToken = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';

  // ── Dashboard ─────────────────────────────────────────────────────────────
  static const String commonDashboard = '/api/v1/common/dashboard';

  // ── Clinics ───────────────────────────────────────────────────────────────
  static const String getClinics = '/api/v1/clinics/list_clinics';
  static const String createClinic = '/api/v1/clinics/create_clinic';
  static const String updateClinic = '/api/v1/clinics/clinic-update';

  // ── Doctors ───────────────────────────────────────────────────────────────
  static const String getDoctors = '/api/v1/doctors/list_doctors';
  static const String createDoctor = '/api/v1/doctors/create_doctor';
  static const String specialties = '/api/v1/doctors/specialties';
}

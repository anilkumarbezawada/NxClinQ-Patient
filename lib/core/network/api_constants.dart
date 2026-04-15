/// Central place for all API configuration constants.
class ApiConstants {
  ApiConstants._();

  //static const String baseUrl = 'http://10.10.10.82:8000';
  static const String baseUrl = 'https://nxclinq.ttiplexamservices.com';

  // ── Internal API Key ──────────────────────────────────────────────────────
  /// Change this value when promoting to production.
  // ── Org Config (fallback default) ─────────────────────────────────────────
  static const String defaultOrgId = '4788eae6-4586-4e05-9b6c-4aeecc76cfa1';
  static const String internalApiKey = 'X6EIPkoofCoxnQBrx7eYn8d8NSjvPQ96OGexpV4gjSQ';
  static const String internalApiKeyHeader = 'X-Internal-API-Key';

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
  static const String clinicMappingStatus = '/api/v1/clinics/clinic-mapping-status';
  static const String listPatientProfiles = '/api/v1/appointments/patient_profiles';
  static const String createPatientProfile = '/api/v1/appointments/create_patient_profile';

  // ── Doctors ───────────────────────────────────────────────────────────────
  static const String getDoctors = '/api/v1/doctors/list_doctors';
  static const String getDoctorInfo = '/api/v1/doctors/doctor-info';
  static const String createDoctor = '/api/v1/doctors/create_doctor';
  static const String mapDoctorClinics = '/api/v1/doctors/map-clinics';
  static const String specialties = '/api/v1/doctors/specialties';
  
  static String configureCalendar(String doctorId) => '/api/v1/doctors/$doctorId/calendar/configure';
  static String createScheduleWindows(String doctorId) => '/api/v1/doctors/$doctorId/clinic-schedule-windows';
  static String doctorSchedulesByClinic(String clinicId) => '/api/v1/clinics/$clinicId/doctor-schedules';

  static String getBookingBoard(String doctorId, String clinicId) =>
      '/api/v1/doctors/$doctorId/clinics/$clinicId/board';

  static const String createAppointment = '/api/v1/appointments/create_appointment';
  static const String getAppointmentsByDay = '/api/v1/appointments/day';

  // ── Patient Auth ──────────────────────────────────────────────────────────
  static const String checkPatientProfile = '/api/v1/patients/check_profile_verified';
  static const String verifyPatientOtp = '/api/v1/patients/verify_otp';
  static const String resendPatientOtp = '/api/v1/patients/resend_otp';
  static const String patientLogin = '/api/v1/patients/login';

  // ── Patient Resources ─────────────────────────────────────────────────────
  static const String patientAppointments = '/api/v1/patients/appointments';
  static const String patientAppointmentReports = '/api/v1/patients/appointments/reports';

  // ── AI Assistant (RAG) ────────────────────────────────────────────────────
  static const String ragContext = '/api/v1/patients/appointments/rag-context';
  static String ragAsk(String encounterId) =>
      '/api/v1/encounters/$encounterId/rag/ask';
}

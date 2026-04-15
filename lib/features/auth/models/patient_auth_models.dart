/// Models for patient authentication flow.
///
/// Endpoints used:
///   POST /api/v1/patients/check_profile_verified
///   POST /api/v1/patients/verify_otp
///   POST /api/v1/patients/resend_otp
///   POST /api/v1/patients/login
library;

// ── Check Profile Response ────────────────────────────────────────────────────

class CheckProfileResponse {
  final bool isProfileVerified;
  final String? patientId;

  const CheckProfileResponse({
    required this.isProfileVerified,
    this.patientId,
  });

  factory CheckProfileResponse.fromJson(Map<String, dynamic> json) {
    return CheckProfileResponse(
      isProfileVerified: json['is_profile_verified'] as bool? ?? false,
      patientId: json['patient_id'] as String?,
    );
  }
}

// ── Patient Login (tokens + principal) ───────────────────────────────────────

class PatientTokens {
  final String accessToken;
  final String refreshToken;

  const PatientTokens({required this.accessToken, required this.refreshToken});

  factory PatientTokens.fromJson(Map<String, dynamic> json) {
    return PatientTokens(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
    );
  }
}

class PatientPrincipal {
  final String userId;
  final String orgId;
  final String profileId;
  final String? email;
  final String? name; // Added name
  final String role;
  final String status;
  final String sessionId;

  const PatientPrincipal({
    required this.userId,
    required this.orgId,
    required this.profileId,
    this.email,
    this.name, // Added name
    required this.role,
    required this.status,
    required this.sessionId,
  });

  factory PatientPrincipal.fromJson(Map<String, dynamic> json) {
    return PatientPrincipal(
      userId: json['user_id'] as String? ?? '',
      orgId: json['org_id'] as String? ?? '',
      profileId: json['profile_id'] as String? ?? '',
      email: json['email'] as String?,
      name: json['name'] as String?, // Parse name
      role: json['role'] as String? ?? 'patient',
      status: json['status'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
    );
  }
}

class PatientLoginResponse {
  final PatientTokens tokens;
  final PatientPrincipal principal;

  const PatientLoginResponse({required this.tokens, required this.principal});

  factory PatientLoginResponse.fromJson(Map<String, dynamic> json) {
    return PatientLoginResponse(
      tokens: PatientTokens.fromJson(
        json['tokens'] as Map<String, dynamic>? ?? {},
      ),
      principal: PatientPrincipal.fromJson(
        json['principal'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

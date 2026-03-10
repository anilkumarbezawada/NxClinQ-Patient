// Full model tree for the login response.
//
// Server envelope:
// { "success": bool, "data": AuthData, "error": ..., "request_id": "..." }

// ── Top-level auth data ───────────────────────────────────────────────────────

class AuthData {
  final String accessToken;
  final String accessTokenExpiresAt;
  final String refreshToken;
  final String refreshTokenExpiresAt;
  final String csrfToken;
  final UserData user;
  final int activeDeviceCount;
  final bool requiresClinicSelection;

  const AuthData({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.csrfToken,
    required this.user,
    required this.activeDeviceCount,
    required this.requiresClinicSelection,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      accessToken: json['access_token'] as String? ?? '',
      accessTokenExpiresAt: json['access_token_expires_at'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      refreshTokenExpiresAt: json['refresh_token_expires_at'] as String? ?? '',
      csrfToken: json['csrf_token'] as String? ?? '',
      user: UserData.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      activeDeviceCount: json['active_device_count'] as int? ?? 0,
      requiresClinicSelection: json['requires_clinic_selection'] as bool? ?? false,
    );
  }
}

// ── User data ─────────────────────────────────────────────────────────────────

class UserData {
  final String id;
  final String role;
  final List<ClinicMembership> clinicMemberships;
  final String? activeClinicId;

  const UserData({
    required this.id,
    required this.role,
    required this.clinicMemberships,
    this.activeClinicId,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    final memberships = (json['clinic_memberships'] as List<dynamic>? ?? [])
        .map((e) => ClinicMembership.fromJson(e as Map<String, dynamic>))
        .toList();

    return UserData(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? '',
      clinicMemberships: memberships,
      activeClinicId: json['active_clinic_id'] as String?,
    );
  }

  /// Convenience: returns the active clinic membership or null.
  ClinicMembership? get activeClinic {
    if (activeClinicId == null) return null;
    try {
      return clinicMemberships.firstWhere((m) => m.clinicId == activeClinicId);
    } catch (_) {
      return clinicMemberships.isNotEmpty ? clinicMemberships.first : null;
    }
  }
}

// ── Clinic membership ─────────────────────────────────────────────────────────

class ClinicMembership {
  final String clinicId;
  final String clinicName;
  final String? orgId;
  final String? orgName;
  final String? specialty;
  final String status;

  const ClinicMembership({
    required this.clinicId,
    required this.clinicName,
    this.orgId,
    this.orgName,
    this.specialty,
    required this.status,
  });

  factory ClinicMembership.fromJson(Map<String, dynamic> json) {
    return ClinicMembership(
      clinicId: json['clinic_id'] as String? ?? '',
      clinicName: json['clinic_name'] as String? ?? '',
      orgId: json['org_id'] as String?,
      orgName: json['org_name'] as String?,
      specialty: json['specialty'] as String?,
      status: json['status'] as String? ?? 'unknown',
    );
  }
}

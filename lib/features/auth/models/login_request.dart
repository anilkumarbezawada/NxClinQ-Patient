/// Request body for POST /api/v1/auth/login
class LoginRequest {
  final String identifier;
  final String password;

  const LoginRequest({
    required this.identifier,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'password': password,
      };
}

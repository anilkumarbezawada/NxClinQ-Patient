class CreateDoctorRequest {
  final String prefix;
  final String fullName;
  final String email;
  final String password;
  final String phone;
  final String specialtyId;
  final String qualification;
  final String title;
  final String experience;
  final String description;
  final String gender;
  final List<String> languagesKnown;

  CreateDoctorRequest({
    required this.prefix,
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
    required this.specialtyId,
    required this.qualification,
    required this.title,
    required this.experience,
    required this.description,
    required this.gender,
    required this.languagesKnown,
  });

  Map<String, dynamic> toJson() {
    return {
      'prefix': prefix,
      'full_name': fullName,
      'email': email,
      'password': password,
      'phone': phone,
      'specialty_id': specialtyId,
      'qualification': qualification,
      'title': title,
      'experience': experience,
      'description': description,
      'gender': gender,
      'languages_known': languagesKnown,
    };
  }
}

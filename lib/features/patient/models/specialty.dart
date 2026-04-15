class Specialty {
  final String id;
  final String name;

  Specialty({required this.id, required this.name});

  factory Specialty.fromJson(Map<String, dynamic> json) {
    return Specialty(id: json['id'] as String, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class SpecialtiesResponse {
  final bool success;
  final String? message;
  final List<Specialty> data;
  final String? error;

  SpecialtiesResponse({
    required this.success,
    this.message,
    required this.data,
    this.error,
  });

  factory SpecialtiesResponse.fromJson(Map<String, dynamic> json) {
    return SpecialtiesResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => Specialty.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      error: json['error'] as String?,
    );
  }
}

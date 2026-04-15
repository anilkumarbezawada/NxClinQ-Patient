class ClinicMappingStatusResponse {
  final bool success;
  final String? message;
  final List<ClinicMappingItem> data;

  const ClinicMappingStatusResponse({
    required this.success,
    this.message,
    this.data = const [],
  });

  factory ClinicMappingStatusResponse.fromJson(Map<String, dynamic> json) {
    return ClinicMappingStatusResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => ClinicMappingItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class ClinicMappingItem {
  final String id;
  final String name;
  final String clinicLocation;
  final String status;
  final bool isMapped;

  const ClinicMappingItem({
    required this.id,
    required this.name,
    required this.clinicLocation,
    required this.status,
    required this.isMapped,
  });

  factory ClinicMappingItem.fromJson(Map<String, dynamic> json) {
    return ClinicMappingItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      clinicLocation: json['clinic_location']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isMapped: json['is_mapped'] as bool? ?? false,
    );
  }
}

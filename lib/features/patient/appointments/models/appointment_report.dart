class AppointmentReport {
  final SoapNote soap;
  final List<ErxMedication> medications;
  final List<String> investigations;
  final String diagnosis;
  final bool isSoapGenerated;
  final bool isErxGenerated;
  final String encounterId;

  const AppointmentReport({
    required this.soap,
    required this.medications,
    required this.investigations,
    required this.diagnosis,
    required this.isSoapGenerated,
    required this.isErxGenerated,
    required this.encounterId,
  });

  factory AppointmentReport.fromJson(Map<String, dynamic> json) {
    // Top-level "data" object
    final data = json['data'] as Map<String, dynamic>? ?? json;
    
    final soapJson = data['soap'] as Map<String, dynamic>? ?? {};
    final erxJson = data['erx'] as Map<String, dynamic>? ?? {};
    final medsList = erxJson['medications'] as List<dynamic>? ?? [];
    final investigationsList = erxJson['investigations'] as List<dynamic>? ?? [];

    return AppointmentReport(
      soap: SoapNote.fromJson(soapJson),
      medications: medsList
          .map((e) => ErxMedication.fromJson(e as Map<String, dynamic>))
          .toList(),
      investigations: investigationsList.map((e) {
        if (e is Map) {
          return e['name']?.toString() ?? 'Unknown Investigation';
        }
        return e.toString();
      }).toList(),
      diagnosis: erxJson['diagnosis'] as String? ?? '',
      isSoapGenerated: data['is_soap_generated'] as bool? ?? false,
      isErxGenerated: data['is_erx_generated'] as bool? ?? false,
      encounterId: data['encounter_id'] as String? ?? '',
    );
  }
}

class SoapNote {
  final String plan;
  final String objective;
  final String assessment;
  final String subjective;

  const SoapNote({
    required this.plan,
    required this.objective,
    required this.assessment,
    required this.subjective,
  });

  factory SoapNote.fromJson(Map<String, dynamic> json) {
    return SoapNote(
      plan: json['plan'] as String? ?? '',
      objective: json['objective'] as String? ?? '',
      assessment: json['assessment'] as String? ?? '',
      subjective: json['subjective'] as String? ?? '',
    );
  }
}

class ErxMedication {
  final String name;
  final String remarks;
  final String duration;
  final String frequency;

  const ErxMedication({
    required this.name,
    required this.remarks,
    required this.duration,
    required this.frequency,
  });

  factory ErxMedication.fromJson(Map<String, dynamic> json) {
    String durationStr = '';
    if (json['duration'] is Map) {
      final dMap = json['duration'] as Map;
      final val = dMap['value']?.toString() ?? '';
      final unit = dMap['unit']?.toString() ?? '';
      if (val != 'unknown' && val.isNotEmpty) {
        durationStr = '$val $unit'.trim();
      }
    } else if (json['duration'] is String) {
      durationStr = json['duration'] as String;
    }

    String freqStr = '';
    if (json['frequency'] is Map) {
      final fMap = json['frequency'] as Map;
      final mode = fMap['mode']?.toString() ?? '';
      if (mode != 'unknown' && mode.isNotEmpty) {
        freqStr = mode;
      }
    } else if (json['frequency'] is String) {
      freqStr = json['frequency'] as String;
    }

    final remarksStr = (json['remarks'] as String?) ?? (json['special_instructions'] as String?) ?? '';

    return ErxMedication(
      name: json['name'] as String? ?? 'Unknown Medication',
      remarks: remarksStr,
      duration: durationStr,
      frequency: freqStr,
    );
  }
}

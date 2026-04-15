class VitalRecord {
  const VitalRecord({
    required this.recordedAt,
    this.systolic,
    this.diastolic,
    this.heartRate,
    this.spo2,
    this.temperatureC,
    this.weightKg,
    this.bloodSugar,
    this.notes,
  });

  final DateTime recordedAt;
  final int? systolic;
  final int? diastolic;
  final int? heartRate;
  final int? spo2;
  final double? temperatureC;
  final double? weightKg;
  final int? bloodSugar;
  final String? notes;

  List<String> get summaryItems {
    final items = <String>[];
    if (systolic != null || diastolic != null) {
      items.add('${systolic ?? '--'}/${diastolic ?? '--'} mmHg');
    }
    if (heartRate != null) items.add('$heartRate bpm');
    if (spo2 != null) items.add('$spo2% SpO2');
    if (temperatureC != null) items.add('${temperatureC!.toStringAsFixed(1)} C');
    if (weightKg != null) items.add('${weightKg!.toStringAsFixed(1)} kg');
    if (bloodSugar != null) items.add('$bloodSugar mg/dL');
    return items;
  }
  Map<String, dynamic> toJson() {
    return {
      'recordedAt': recordedAt.toIso8601String(),
      'systolic': systolic,
      'diastolic': diastolic,
      'heartRate': heartRate,
      'spo2': spo2,
      'temperatureC': temperatureC,
      'weightKg': weightKg,
      'bloodSugar': bloodSugar,
      'notes': notes,
    };
  }
}

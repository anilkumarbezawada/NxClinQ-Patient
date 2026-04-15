import '../models/vital_record.dart';

class VitalsService {
  VitalsService._();

  static final VitalsService instance = VitalsService._();

  final List<VitalRecord> _records = <VitalRecord>[];

  Future<List<VitalRecord>> fetchVitalsHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final items = [..._records];
    items.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return items;
  }

  Future<VitalRecord> saveVitals(VitalRecord record) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    _records.add(record);

    // Later we can replace this local storage with server APIs.
    return record;
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  final List<_PatientData> _patients = const [
    _PatientData('Rahul Gupta', 32, 'Male', 'O+', '+91 98100 11223', '15 Feb 2026', AppColors.success),
    _PatientData('Sneha Patel', 28, 'Female', 'B+', '+91 87200 22334', '20 Feb 2026', AppColors.primaryBrand),
    _PatientData('Vikram Singh', 45, 'Male', 'A+', '+91 76300 33445', '10 Feb 2026', AppColors.warning),
    _PatientData('Ananya Roy', 22, 'Female', 'AB-', '+91 65400 44556', '18 Feb 2026', AppColors.error),
    _PatientData('Mohan Lal', 60, 'Male', 'B-', '+91 54500 55667', '05 Feb 2026', AppColors.info),
    _PatientData('Divya Menon', 35, 'Female', 'O-', '+91 43600 66778', '22 Feb 2026', AppColors.success),
    _PatientData('Ajay Kumar', 50, 'Male', 'A-', '+91 32700 77889', '01 Feb 2026', Color(0xFF6A0DAD)),
    _PatientData('Pooja Desai', 27, 'Female', 'B+', '+91 21800 88990', '14 Feb 2026', Color(0xFF8B4513)),
    _PatientData('Rajan Nair', 42, 'Male', 'O+', '+91 10900 99001', '08 Feb 2026', AppColors.success),
    _PatientData('Lakshmi Rao', 38, 'Female', 'A+', '+91 99001 10012', '25 Feb 2026', AppColors.primaryBrandLight),
  ];

  List<_PatientData> get _filtered => _query.isEmpty
      ? _patients
      : _patients.where((p) => p.name.toLowerCase().contains(_query) || p.bloodGroup.toLowerCase().contains(_query)).toList();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.getPrimaryGradient(Theme.of(context).colorScheme.primary)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patients', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
            Text('${_patients.length} total patients', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/admin/patients/add'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Patient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryBrand,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.dividerTheme.color),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search patients by name or blood group...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No results for "$_query"', style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) => _PatientCard(patient: _filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final _PatientData patient;
  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: patient.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  patient.name[0],
                  style: TextStyle(color: patient.color, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          patient.name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      // Blood group badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          patient.bloodGroup,
                          style: const TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        patient.gender == 'Male' ? Icons.male_rounded : Icons.female_rounded,
                        size: 14,
                        color: patient.gender == 'Male' ? AppColors.info : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${patient.gender} · ${patient.age} years',
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _MiniInfo(icon: Icons.phone_outlined, label: patient.phone),
                      const SizedBox(width: 12),
                      _MiniInfo(icon: Icons.calendar_today_outlined, label: 'Last: ${patient.lastVisit}'),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
      ],
    );
  }
}

class _PatientData {
  final String name;
  final int age;
  final String gender;
  final String bloodGroup;
  final String phone;
  final String lastVisit;
  final Color color;
  const _PatientData(this.name, this.age, this.gender, this.bloodGroup, this.phone, this.lastVisit, this.color);
}


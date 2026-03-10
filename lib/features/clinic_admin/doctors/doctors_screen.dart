import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  final List<_DoctorData> _doctors = const [
    _DoctorData('Dr. Priya Sharma', 'Cardiologist', 'priya.sharma@clinic.com', '+91 98765 43210', 'MC/2015/001', 8, AppColors.success),
    _DoctorData('Dr. Arjun Mehta', 'Orthopedic Surgeon', 'arjun.mehta@clinic.com', '+91 87654 32109', 'MC/2012/045', 12, AppColors.primaryBrand),
    _DoctorData('Dr. Kavya Nair', 'Neurologist', 'kavya.nair@clinic.com', '+91 76543 21098', 'MC/2018/112', 6, AppColors.info),
    _DoctorData('Dr. Rohan Das', 'Dermatologist', 'rohan.das@clinic.com', '+91 65432 10987', 'MC/2016/078', 9, AppColors.success),
    _DoctorData('Dr. Aisha Khan', 'Gynecologist', 'aisha.khan@clinic.com', '+91 54321 09876', 'MC/2014/033', 11, AppColors.warning),
    _DoctorData('Dr. Vikram Joshi', 'General Physician', 'vikram.joshi@clinic.com', '+91 43210 98765', 'MC/2019/156', 5, AppColors.error),
    _DoctorData('Dr. Meera Iyer', 'Pediatrician', 'meera.iyer@clinic.com', '+91 32109 87654', 'MC/2013/067', 13, Color(0xFF6A0DAD)),
    _DoctorData('Dr. Suresh Babu', 'ENT Specialist', 'suresh.babu@clinic.com', '+91 21098 76543', 'MC/2017/099', 7, Color(0xFF8B4513)),
  ];

  List<_DoctorData> get _filtered => _query.isEmpty
      ? _doctors
      : _doctors
          .where((d) =>
              d.name.toLowerCase().contains(_query) ||
              d.specialty.toLowerCase().contains(_query))
          .toList();

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
            Text('Doctors', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
            Text('${_doctors.length} registered', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/admin/doctors/add'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Doctor'),
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
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search doctors by name or specialty...',
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
          // List
          Expanded(
            child: _filtered.isEmpty
                ? _EmptyState(query: _query)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) => _DoctorCard(doctor: _filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final _DoctorData doctor;
  const _DoctorCard({required this.doctor});

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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: doctor.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  doctor.name.split(' ').skip(1).first[0],
                  style: TextStyle(
                    color: doctor.color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
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
                          doctor.name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.specialty,
                    style: TextStyle(
                      color: doctor.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _InfoChip(icon: Icons.badge_outlined, label: doctor.licenseNo),
                      const SizedBox(width: 8),
                      _InfoChip(icon: Icons.work_outline_rounded, label: '${doctor.experience} yrs'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 12, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 4),
                      Text(doctor.phone, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _DoctorData {
  final String name;
  final String specialty;
  final String email;
  final String phone;
  final String licenseNo;
  final int experience;
  final Color color;

  const _DoctorData(this.name, this.specialty, this.email, this.phone, this.licenseNo, this.experience, this.color);
}


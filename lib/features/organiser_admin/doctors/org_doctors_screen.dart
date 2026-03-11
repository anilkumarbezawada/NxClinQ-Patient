import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class OrgDoctorsScreen extends StatelessWidget {
  const OrgDoctorsScreen({super.key});

  static const List<_DoctorData> _doctors = [
    _DoctorData(
      name: 'Dr. Priya Sharma',
      specialty: 'Cardiology',
      clinic: 'City Care Clinic',
      phone: '+91 98765 43210',
      calendarSet: true,
    ),
    _DoctorData(
      name: 'Dr. Arjun Mehta',
      specialty: 'Orthopaedics',
      clinic: 'Sunrise Hospital',
      phone: '+91 87654 32109',
      calendarSet: true,
    ),
    _DoctorData(
      name: 'Dr. Kavya Nair',
      specialty: 'Neurology',
      clinic: 'Green Health Centre',
      phone: '+91 76543 21098',
      calendarSet: false,
    ),
    _DoctorData(
      name: 'Dr. Rohan Das',
      specialty: 'Dermatology',
      clinic: 'MedPlus Wellness',
      phone: '+91 65432 10987',
      calendarSet: false,
    ),
    _DoctorData(
      name: 'Dr. Anjali Reddy',
      specialty: 'Gynaecology',
      clinic: 'Apollo Wellness Hub',
      phone: '+91 54321 09876',
      calendarSet: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 64,
            backgroundColor: const Color(0xFF7C3AED),
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Doctors',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '${_doctors.length} doctors registered in your organisation',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/org/doctors/add'),
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: const Text('Add Doctor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF7C3AED),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
            elevation: 0,
          ),

          // Summary strip
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  _SummaryChip(
                    label: 'Calendar Set',
                    count: _doctors.where((d) => d.calendarSet).length,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 10),
                  _SummaryChip(
                    label: 'Pending Calendar',
                    count: _doctors.where((d) => !d.calendarSet).length,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _DoctorCard(doctor: _doctors[index]),
                childCount: _doctors.length,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/org/doctors/add'),
        backgroundColor: const Color(0xFF7C3AED),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Doctor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        elevation: 4,
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  doctor.name.split(' ').length > 1
                      ? doctor.name.split(' ')[1][0].toUpperCase()
                      : doctor.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${doctor.specialty} · ${doctor.clinic}',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: doctor.calendarSet
                              ? AppColors.success.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          doctor.calendarSet ? '● Calendar Set' : '● Set Calendar',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: doctor.calendarSet ? AppColors.success : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action
            if (!doctor.calendarSet)
              IconButton(
                onPressed: () => context.push('/org/doctors/calendar'),
                icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF7C3AED)),
                tooltip: 'Set Calendar',
              ),
          ],
        ),
      ),
    );
  }
}

class _DoctorData {
  final String name;
  final String specialty;
  final String clinic;
  final String phone;
  final bool calendarSet;
  const _DoctorData({
    required this.name,
    required this.specialty,
    required this.clinic,
    required this.phone,
    required this.calendarSet,
  });
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class ClinicsScreen extends StatelessWidget {
  const ClinicsScreen({super.key});

  static const List<_ClinicData> _clinics = [
    _ClinicData(
      name: 'City Care Clinic',
      location: 'Hyderabad, Telangana',
      specialty: 'Multi-Specialty',
      doctorCount: 6,
      contact: '+91 98765 43210',
      isActive: true,
    ),
    _ClinicData(
      name: 'Green Health Centre',
      location: 'Bangalore, Karnataka',
      specialty: 'General Medicine',
      doctorCount: 4,
      contact: '+91 98765 12345',
      isActive: true,
    ),
    _ClinicData(
      name: 'MedPlus Wellness',
      location: 'Chennai, Tamil Nadu',
      specialty: 'Orthopaedics',
      doctorCount: 3,
      contact: '+91 97654 32109',
      isActive: false,
    ),
    _ClinicData(
      name: 'Sunrise Hospital',
      location: 'Mumbai, Maharashtra',
      specialty: 'Cardiology',
      doctorCount: 8,
      contact: '+91 91234 56789',
      isActive: true,
    ),
    _ClinicData(
      name: 'Apollo Wellness Hub',
      location: 'Pune, Maharashtra',
      specialty: 'Neurology',
      doctorCount: 5,
      contact: '+91 90123 45678',
      isActive: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            toolbarHeight: 64,
            backgroundColor: const Color(0xFF0EA5E9),
            surfaceTintColor: Colors.transparent,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Clinics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '${_clinics.length} clinics under your organisation',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/org/clinics/create'),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('New Clinic'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0EA5E9),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // Summary strip
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  _SummaryChip(
                    label: 'Active',
                    count: _clinics.where((c) => c.isActive).length,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 10),
                  _SummaryChip(
                    label: 'Pending',
                    count: _clinics.where((c) => !c.isActive).length,
                    color: Colors.orange,
                  ),
                  const Spacer(),
                  const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    'Search (coming soon)',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Clinic list
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ClinicCard(clinic: _clinics[index]),
                childCount: _clinics.length,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/org/clinics/create'),
        backgroundColor: const Color(0xFF0EA5E9),
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text('Create Clinic', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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

class _ClinicCard extends StatelessWidget {
  final _ClinicData clinic;
  const _ClinicCard({required this.clinic});

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
      child: Column(
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinic.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        clinic.specialty,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF0EA5E9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: clinic.isActive
                        ? AppColors.success.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    clinic.isActive ? '● Active' : '● Pending',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: clinic.isActive ? AppColors.success : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                _InfoChip(icon: Icons.location_on_rounded, label: clinic.location),
                const SizedBox(width: 10),
                _InfoChip(
                  icon: Icons.medical_services_rounded,
                  label: '${clinic.doctorCount} Doctors',
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0EA5E9),
                    side: const BorderSide(color: Color(0xFF0EA5E9)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('View'),
                ),
              ],
            ),
          ),
        ],
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _ClinicData {
  final String name;
  final String location;
  final String specialty;
  final int doctorCount;
  final String contact;
  final bool isActive;
  const _ClinicData({
    required this.name,
    required this.location,
    required this.specialty,
    required this.doctorCount,
    required this.contact,
    required this.isActive,
  });
}

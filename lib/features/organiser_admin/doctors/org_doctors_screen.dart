import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../models/doctor_list_response.dart';

class OrgDoctorsScreen extends StatefulWidget {
  const OrgDoctorsScreen({super.key});

  @override
  State<OrgDoctorsScreen> createState() => _OrgDoctorsScreenState();
}

class _OrgDoctorsScreenState extends State<OrgDoctorsScreen> {
  late Future<DoctorListResponse> _doctorsFuture;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final future = ApiService.instance.getDoctors();
      setState(() {
        _doctorsFuture = future;
      });
      await future;
    } catch (e) {
      if (!mounted) return;
      final errorString = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorString),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFetching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<DoctorListResponse>(
        future: _doctorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const CardShimmerLayout(itemCount: 6);
          }

          final doctors = snapshot.data?.data ?? [];

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: true,
                  toolbarHeight: 64,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.getPrimaryGradient(themeProvider.seedColor),
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
                        '${doctors.length} doctors registered in your organisation',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await context.push('/org/doctors/add');
                          _fetchData();
                        },
                        icon: const Icon(Icons.person_add_rounded, size: 16),
                        label: const Text('New Doctor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: themeProvider.seedColor,
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
              ];
            },
            body: RefreshIndicator(
              onRefresh: _fetchData,
              color: const Color(0xFF0EA5E9),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (doctors.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/doctor.png',
                              width: 160,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.medical_information_rounded, size: 64, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No doctors were found.',
                              style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _DoctorCard(
                            doctor: doctors[index],
                            onRefresh: _fetchData,
                          ),
                          childCount: doctors.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/org/doctors/add');
          _fetchData();
        },
        backgroundColor: const Color(0xFF0EA5E9),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Doctor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        elevation: 4,
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onRefresh;
  const _DoctorCard({required this.doctor, required this.onRefresh});

  void _showDoctorDetails(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark ? theme.colorScheme.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.getPrimaryGradient(themeProvider.seedColor),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.seedColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    doctor.fullName.isNotEmpty ? doctor.fullName[0].toUpperCase() : 'D',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                doctor.fullName,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              if (doctor.title != null && doctor.title!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    doctor.title!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: themeProvider.seedColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              _buildDetailRow(context, Icons.medical_services_rounded, 'Specialty', doctor.specialty ?? 'Not specified'),
              _buildDetailRow(context, Icons.school_rounded, 'Qualification', doctor.qualification ?? 'Not specified'),
              _buildDetailRow(context, Icons.work_history_rounded, 'Experience', doctor.experience ?? 'Not specified'),
              _buildDetailRow(context, Icons.phone_rounded, 'Phone', doctor.phone ?? 'Not specified'),
              if (doctor.description != null && doctor.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'About',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    doctor.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: themeProvider.seedColor.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    IconData genderIcon = Icons.person_rounded;
    if (doctor.gender?.toLowerCase() == 'male') genderIcon = Icons.male_rounded;
    if (doctor.gender?.toLowerCase() == 'female') genderIcon = Icons.female_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark 
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: theme.brightness == Brightness.light ? [
          BoxShadow(
            color: themeProvider.seedColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ] : null,
        border: Border.all(
          color: themeProvider.seedColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showDoctorDetails(context, themeProvider),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.getPrimaryGradient(themeProvider.seedColor),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.seedColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      doctor.fullName.isNotEmpty ? doctor.fullName[0].toUpperCase() : 'D',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              doctor.fullName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(genderIcon, size: 16, color: themeProvider.seedColor.withValues(alpha: 0.7)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor.specialty ?? 'General Physician',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: themeProvider.seedColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.work_history_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(
                            doctor.experience ?? 'Not specified',
                            style: TextStyle(
                              fontSize: 12, 
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

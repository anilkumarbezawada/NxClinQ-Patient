import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../organiser_admin/models/org_dashboard_response.dart';
import '../../organiser_admin/models/clinic_list_response.dart';

class ClinicsScreen extends StatefulWidget {
  const ClinicsScreen({super.key});

  @override
  State<ClinicsScreen> createState() => _ClinicsScreenState();
}

class _ClinicsScreenState extends State<ClinicsScreen> {
  late Future<ClinicListResponse> _clinicsFuture;
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
      final future = ApiService.instance.getClinics();
      setState(() {
        _clinicsFuture = future;
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
      _isFetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<ClinicListResponse>(
        future: _clinicsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const CardShimmerLayout(itemCount: 6);
          }

          final clinics = snapshot.data?.data ?? [];

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
                        'Clinics',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${clinics.length} clinics under your organisation',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await context.push('/org/clinics/create');
                          _fetchData();
                        },
                        icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('New Clinic'),
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
                  if (clinics.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/no_clinics.png',
                              width: 160,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.business_rounded, size: 64, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No clinics were created.',
                              style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // Clinics list
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _ClinicCard(
                            clinic: clinics[index],
                            onRefresh: _fetchData,
                          ),
                          childCount: clinics.length,
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
          await context.push('/org/clinics/create');
          _fetchData();
        },
        backgroundColor: const Color(0xFF0EA5E9),
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text('Create Clinic', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        elevation: 4,
      ),
    );
  }
}

class _ClinicCard extends StatelessWidget {
  final OrgClinic clinic;
  final VoidCallback onRefresh;
  const _ClinicCard({required this.clinic, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    
    final doctorsCountStr = clinic.avalibleDoctors?.toString() ?? '0';
    final doctorsCount = int.tryParse(doctorsCountStr) ?? 0;
    final doctorText = doctorsCount == 0 ? 'No doctors available' : '$doctorsCount Doctors';
    final fullAddress = clinic.clinicAddress ?? clinic.clinicLocation;
    final phoneText = (clinic.phone == null || clinic.phone!.isEmpty) ? 'Not provided' : clinic.phone!;

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
      child: Column(
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: themeProvider.seedColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.getPrimaryGradient(themeProvider.seedColor),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.seedColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinic.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_city_rounded, size: 14, color: themeProvider.seedColor.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Text(
                            clinic.clinicLocation,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: themeProvider.seedColor,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.medical_services_rounded, size: 14, color: themeProvider.seedColor.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Text(
                            doctorText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: themeProvider.seedColor,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_rounded, color: themeProvider.seedColor.withValues(alpha: 0.8), size: 20),
                  onPressed: () async {
                    await context.push('/org/clinics/create', extra: clinic);
                    onRefresh();
                  },
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_rounded, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              fullAddress,
                              style: TextStyle(
                                fontSize: 13, 
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7), 
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                          const SizedBox(width: 6),
                          Text(
                            phoneText,
                            style: TextStyle(
                              fontSize: 13, 
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
                Align(
                  alignment: Alignment.bottomRight,
                  child: FilledButton.tonal(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: themeProvider.seedColor.withValues(alpha: 0.1),
                      foregroundColor: themeProvider.seedColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('View'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

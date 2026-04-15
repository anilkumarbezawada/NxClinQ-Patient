import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../models/doctor_list_response.dart';
import '../models/specialty.dart';
import '../models/patient_profile_response.dart';
import 'doctor_info_screen.dart';

IconData _iconForSpecialtyLabel(String specialty) {
  final value = specialty.toLowerCase();
  if (value.contains('cardi')) return Icons.favorite_rounded;
  if (value.contains('dentist')) return Icons.health_and_safety_rounded;
  if (value.contains('dermato')) return Icons.face_rounded;
  if (value.contains('pediatric')) return Icons.child_care_rounded;
  if (value.contains('neuro')) return Icons.psychology_rounded;
  if (value.contains('ortho')) return Icons.accessibility_new_rounded;
  if (value.contains('ent') || value.contains('otorhino')) {
    return Icons.hearing_rounded;
  }
  if (value.contains('ayurveda')) return Icons.spa_rounded;
  return Icons.medical_services_rounded;
}

class DoctorPickerScreen extends StatefulWidget {
  final PatientProfile patient;

  const DoctorPickerScreen({super.key, required this.patient});

  @override
  State<DoctorPickerScreen> createState() => _DoctorPickerScreenState();
}

class _DoctorPickerScreenState extends State<DoctorPickerScreen> {
  late Future<DoctorListResponse> _doctorsFuture;
  List<Specialty> _specialties = [];
  Specialty? _selectedSpecialty;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _fetchSpecialties();
    _fetchDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSpecialties() async {
    try {
      final res = await ApiService.instance.getSpecialties();
      if (mounted) setState(() => _specialties = res.data);
    } catch (_) {}
  }

  void _fetchDoctors() {
    setState(() {
      _doctorsFuture = ApiService.instance.getDoctors();
    });
  }

  Future<void> _refreshDoctors() async {
    final doctorsFuture = ApiService.instance.getDoctors();

    setState(() {
      _doctorsFuture = doctorsFuture;
    });

    await Future.wait([
      _fetchSpecialties(),
      doctorsFuture,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: _isSearchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search doctor...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Select Doctor',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Booking for ${widget.patient.name}',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close_rounded : Icons.search_rounded, color: Colors.white),
            onPressed: () => setState(() {
              _isSearchVisible = !_isSearchVisible;
              if (!_isSearchVisible) {
                _searchController.clear();
                _searchQuery = '';
              }
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          // Specialty Filter
          if (_specialties.isNotEmpty)
            Container(
              height: 60,
              margin: const EdgeInsets.only(top: 8),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: _specialties.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isSel = _selectedSpecialty == null;
                    return _FilterChip(
                      label: 'All',
                      icon: Icons.apps_rounded,
                      isSelected: isSel,
                      seedColor: AppColors.primary,
                      onTap: () => setState(() => _selectedSpecialty = null),
                    );
                  }
                  final spec = _specialties[index - 1];
                  final isSel = _selectedSpecialty?.id == spec.id;
                  return _FilterChip(
                    label: spec.name,
                    icon: _iconForSpecialtyLabel(spec.name),
                    isSelected: isSel,
                    seedColor: AppColors.primary,
                    onTap: () => setState(() => _selectedSpecialty = isSel ? null : spec),
                  );
                },
              ),
            ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshDoctors,
              child: FutureBuilder<DoctorListResponse>(
                future: _doctorsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 16),
                        CardShimmerLayout(itemCount: 5),
                      ],
                    );
                  }
                  if (snapshot.hasError) {
                    final error = snapshot.error;
                    final isNoInternet =
                        error is ApiException && error.code == 'NO_INTERNET';
                    final message = error is ApiException
                        ? error.message
                        : error.toString();

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: AppErrorState(
                            title: isNoInternet
                                ? 'No Internet Connection'
                                : 'Unable to Load Doctors',
                            message: message,
                            icon: isNoInternet
                                ? Icons.wifi_off_rounded
                                : Icons.error_outline_rounded,
                            actionLabel: 'Retry',
                            onAction: _refreshDoctors,
                          ),
                        ),
                      ],
                    );
                  }

                  var doctors = snapshot.data?.data ?? [];

                  // Filter by specialty
                  if (_selectedSpecialty != null) {
                    doctors = doctors.where((d) => d.specialty == _selectedSpecialty!.name).toList();
                  }

                  // Filter by search
                  if (_searchQuery.isNotEmpty) {
                    doctors = doctors.where((d) => d.fullName.toLowerCase().contains(_searchQuery)).toList();
                  }

                  if (doctors.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 180),
                        Center(child: Text('No doctors found')),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      final doctor = doctors[index];
                      return _DoctorPickerCard(
                        doctor: doctor,
                        seedColor: AppColors.primary,
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => DoctorInfoScreen(
                                doctor: doctor,
                                patient: widget.patient,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color seedColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.seedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorPickerCard extends StatelessWidget {
  final DoctorModel doctor;
  final Color seedColor;
  final VoidCallback onTap;

  const _DoctorPickerCard({
    required this.doctor,
    required this.seedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final specialty = doctor.specialty ?? 'General Physician';
    return GestureDetector(
      onTap: onTap,

      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                          child: Text(
                            doctor.fullName.split(' ').last.isNotEmpty ? doctor.fullName.split(' ').last[0].toUpperCase() : 'D',
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctor.fullName,
                                style: AppTypography.titleLarge.copyWith(
                                  color: AppColors.textMain,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primaryLight, width: 0.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _iconForSpecialtyLabel(specialty),
                                      size: 14,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      specialty,
                                      style: AppTypography.chip.copyWith(
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Qualification with Icon
                    Row(
                      children: [
                        Icon(Icons.school_rounded, size: 16, color: AppColors.textMain.withValues(alpha: 0.6)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            doctor.qualification ?? 'N/A',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMain.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Experience and Languages Side-by-Side
                    Row(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.work_history_rounded, size: 14, color: AppColors.textMain.withValues(alpha: 0.6)),
                            const SizedBox(width: 10),
                            Text(
                              '${doctor.experience ?? 'N/A'} Exp.',
                              style: AppTypography.chip.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (doctor.languagesKnown.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('-', style: TextStyle(color: Colors.grey)),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.translate_rounded, size: 14, color: AppColors.textMain.withValues(alpha: 0.6)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    doctor.languagesKnown.join(', '),
                                    style: AppTypography.chip.copyWith(
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Clinics strip
          if (doctor.practisingClinics.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No clinics mapped', style: TextStyle(color: Colors.grey, fontSize: 12)),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available at Clinics',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (var i = 0; i < doctor.practisingClinics.length; i++) ...[
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFF00BFA5)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${doctor.practisingClinics[i].clinicName} · ${doctor.practisingClinics[i].clinicLocation}',
                              style: AppTypography.chip.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (i < doctor.practisingClinics.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey.shade200,
                          ),
                        ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View Details',
                                style: AppTypography.chipSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
}

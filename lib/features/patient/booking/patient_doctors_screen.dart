import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../models/doctor_list_response.dart';
import '../models/doctor_info_response.dart';
import '../models/specialty.dart';
import '../models/clinic_mapping_status_response.dart';

class PatientDoctorsScreen extends StatefulWidget {
  const PatientDoctorsScreen({super.key});
  @override
  State<PatientDoctorsScreen> createState() => _PatientDoctorsScreenState();
}

class _PatientDoctorsScreenState extends State<PatientDoctorsScreen> {
  late Future<DoctorListResponse> _doctorsFuture;
  bool _isFetching = false;
  List<Specialty> _specialties = [];
  bool _isFetchingSpecialties = false;
  Specialty? _selectedSpecialty;
  @override
  void initState() {
    super.initState();
    _fetchSpecialties();
    _fetchData();
  }

  Future<void> _fetchSpecialties() async {
    if (_isFetchingSpecialties) return;
    _isFetchingSpecialties = true;
    try {
      final res = await ApiService.instance.getSpecialties();
      if (mounted) {
        setState(() {
          _specialties = res.data;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingSpecialties = false);
      }
    }
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
          backgroundColor: Color(0xFFFF5252),
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
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<DoctorListResponse>(
        future: _doctorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const CardShimmerLayout(itemCount: 6);
          }
          var doctors = snapshot.data?.data ?? [];
          if (_selectedSpecialty != null) {
            doctors = doctors
                .where((d) => d.specialty == _selectedSpecialty!.name)
                .toList();
          }
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
              SliverAppBar(
                  pinned: true,
                  expandedHeight: 80,
                  toolbarHeight: 64,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDeep],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x3300BFA5),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Doctors',
                        style: AppTypography.headlineMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        '${doctors.length} available near you',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  actions: const [],
                  elevation: 0,
                ),

                SliverToBoxAdapter(
                  child: _specialties.isNotEmpty
                      ? Container(
                          height: 60,
                          color: Colors.transparent,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: _specialties.length + 1,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                final isSelected = _selectedSpecialty == null;
                                return _SpecialtyChip(
                                  label: 'All',
                                  icon: Icons.apps_rounded,
                                  isSelected: isSelected,
                                  seedColor: AppColors.primary,
                                  isDark: theme.brightness == Brightness.dark,
                                  onTap: () =>
                                      setState(() => _selectedSpecialty = null),
                                );
                              }
                              final spec = _specialties[index - 1];
                              final isSelected =
                                  _selectedSpecialty?.id == spec.id;
                              return _SpecialtyChip(
                                label: spec.name,
                                icon: _iconForSpecialty(spec.name),
                                isSelected: isSelected,
                                seedColor: AppColors.primary,
                                isDark: theme.brightness == Brightness.dark,
                                onTap: () => setState(() {
                                  _selectedSpecialty = isSelected ? null : spec;
                                }),
                              );
                            },
                          ),
                        )
                      : const SizedBox.shrink(),
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
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.medical_information_rounded,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No doctors were found.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
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
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onRefresh;
  const _DoctorCard({required this.doctor, required this.onRefresh});

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'D';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _showDoctorDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _DoctorDetailsSheet(doctorId: doctor.id, onMapped: onRefresh),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
    final isDark = theme.brightness == Brightness.dark;
    
    
    IconData genderIcon = Icons.person_rounded;
    Color genderIconColor = AppColors.primary;
    if (doctor.gender?.toLowerCase() == 'male') {
      genderIcon = Icons.male_rounded;
      genderIconColor = const Color(0xFF2563EB);
    }
    if (doctor.gender?.toLowerCase() == 'female') {
      genderIcon = Icons.female_rounded;
      genderIconColor = const Color(0xFFEC4899);
    }
    final clinics = doctor.practisingClinics
        .where(
          (c) =>
              c.clinicName.trim().isNotEmpty ||
              c.clinicLocation.trim().isNotEmpty,
        )
        .toList();
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showDoctorDetails(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _initials(doctor.fullName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: 0.5,
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  doctor.fullName,
                                  style: AppTypography.titleLarge.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: genderIconColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      genderIcon,
                                      size: 14,
                                      color: genderIconColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      doctor.gender ?? '',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: genderIconColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _iconForSpecialty(
                                          doctor.specialty ?? '',
                                        ),
                                        size: 13,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          doctor.specialty ?? '',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (doctor.experience != null &&
                                  doctor.experience!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF2A2A3C)
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white12
                                          : Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.work_history_rounded,
                                        size: 13,
                                        color: AppColors.primary.withValues(alpha: 0.8),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        doctor.experience!,
                                        style: AppTypography.chip.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
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
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      size: 22,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _InfoPill(
                  icon: Icons.school_rounded,
                  text: doctor.qualification ?? 'N/A',
                  seedColor: AppColors.primary,
                  isDark: isDark,
                ),
              ),

              if (clinics.isNotEmpty) ...[
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.08),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_hospital_rounded,
                            size: 13,
                            color: AppColors.primary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Practising Clinics',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary.withValues(alpha: 0.8),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...clinics.asMap().entries.map((entry) {
                        final clinic = entry.value;
                        final isLast = entry.key == clinics.length - 1;
                        final name = clinic.clinicName.trim();
                        final location = clinic.clinicLocation.trim();
                        final label = name.isNotEmpty ? name : location;
                        final sublabel = name.isNotEmpty ? location : '';
                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: AppColors.primary.withValues(alpha: 0.65),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        if (sublabel.isNotEmpty)
                                          TextSpan(
                                            text: '  •  $sublabel',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (!isLast)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  top: 6,
                                  bottom: 6,
                                ),
                                child: Divider(
                                  height: 1,
                                  thickness: 0.8,
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade200,
                                ),
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ] else
                const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color seedColor;
  final bool isDark;
  const _InfoPill({
    required this.icon,
    required this.text,
    required this.seedColor,
    required this.isDark,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A3C) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color seedColor;
  final bool isDark;
  final VoidCallback onTap;
  const _SpecialtyChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.seedColor,
    required this.isDark,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final selectedBg = AppColors.primary.withValues(alpha: 0.12);
    final borderColor = isSelected
        ? AppColors.primary
        : AppColors.primary.withValues(alpha: 0.25);
    final textColor = isSelected
        ? AppColors.primary
        : (isDark ? Colors.white70 : Colors.grey.shade700);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconForSpecialty(String name) {
  final n = name.toLowerCase();
  if (n.contains('cardio')) return Icons.favorite_rounded;
  if (n.contains('neuro')) return Icons.psychology_rounded;
  if (n.contains('ortho')) return Icons.accessibility_new_rounded;
  if (n.contains('derma')) return Icons.face_retouching_natural;
  if (n.contains('paed') || n.contains('pedia')) {
    return Icons.child_care_rounded;
  }
  if (n.contains('gynaec') || n.contains('obstet')) {
    return Icons.pregnant_woman_rounded;
  }
  if (n.contains('eye') || n.contains('ophthal')) {
    return Icons.visibility_rounded;
  }
  if (n.contains('ent') || n.contains('otorhin')) return Icons.hearing_rounded;
  if (n.contains('dent')) return Icons.local_hospital_rounded;
  if (n.contains('radio')) return Icons.camera_rounded;
  if (n.contains('gastro')) return Icons.medication_rounded;
  if (n.contains('pulmo')) return Icons.air_rounded;
  if (n.contains('onco')) return Icons.biotech_rounded;
  if (n.contains('psych')) return Icons.self_improvement_rounded;
  if (n.contains('urol')) return Icons.water_drop_rounded;
  if (n.contains('nephro')) return Icons.water_rounded;
  if (n.contains('endo')) return Icons.science_rounded;
  if (n.contains('physio')) return Icons.sports_gymnastics_rounded;
  if (n.contains('anaes')) return Icons.air_sharp;
  if (n.contains('diet') || n.contains('nutri')) {
    return Icons.restaurant_rounded;
  }
  if (n.contains('plastic') || n.contains('recon')) return Icons.cut_rounded;
  if (n.contains('rheum')) return Icons.healing_rounded;
  if (n.contains('path')) return Icons.biotech_outlined;
  if (n.contains('audio') || n.contains('speech')) {
    return Icons.volume_up_rounded;
  }
  if (n.contains('ivf') || n.contains('infert')) {
    return Icons.child_friendly_rounded;
  }
  if (n.contains('ayur')) return Icons.spa_rounded;
  if (n.contains('homeo')) return Icons.local_pharmacy_rounded;
  if (n.contains('general surgery')) return Icons.healing_rounded;
  return Icons.medical_services_rounded;
}

class _DoctorDetailsSheet extends StatefulWidget {
  final String doctorId;
  final VoidCallback? onMapped;
  const _DoctorDetailsSheet({required this.doctorId, this.onMapped});
  @override
  State<_DoctorDetailsSheet> createState() => _DoctorDetailsSheetState();
}

class _DoctorDetailsSheetState extends State<_DoctorDetailsSheet> {
  bool _isLoading = true;
  String? _error;
  DoctorModel? _doctor;
  List<DoctorPractisingClinic> _practisingClinics = const [];
  @override
  void initState() {
    super.initState();
    _fetchDoctorInfo();
  }

  Future<void> _fetchDoctorInfo() async {
    try {
      final res = await ApiService.instance.getDoctorInfo(widget.doctorId);
      if (mounted) {
        setState(() {
          _doctor = res.data?.doctorInfo;
          _practisingClinics = res.data?.practisingClinics ?? const [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openClinicMappingSheet() async {
    if (_doctor == null) return;
    final mapped = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MapClinicsSheet(
        doctorId: widget.doctorId,
        doctorName: _doctor!.fullName,
      ),
    );
    if (mapped == true) {
      await _fetchDoctorInfo();
      widget.onMapped?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  iconSize: 22,
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.grey,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null || _doctor == null)
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Text(
                  'Failed to load doctor details\n${_error ?? ''}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[400]),
                ),
              ),
            )
          else
            Flexible(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _doctor!.fullName.isNotEmpty
                              ? _doctor!.fullName[0].toUpperCase()
                              : 'D',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 36,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      _doctor!.fullName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _iconForSpecialty(_doctor!.specialty ?? ''),
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _doctor!.specialty ?? '',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    Row(
                      children: [
                        Expanded(
                          child: _InfoTile(
                            icon: Icons.work_history_rounded,
                            label: 'Experience',
                            value: _doctor!.experience ?? 'N/A',
                            seedColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _InfoTile(
                            icon: Icons.phone_rounded,
                            label: 'Phone',
                            value: _doctor!.phone ?? 'N/A',
                            seedColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoTile(
                            icon: Icons.person_rounded,
                            label: 'Gender',
                            value: _doctor!.gender ?? 'N/A',
                            seedColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _InfoTile(
                            icon: Icons.translate_rounded,
                            label: 'Languages',
                            value: _doctor!.languagesKnown.isNotEmpty
                                ? _doctor!.languagesKnown.join(', ')
                                : 'N/A',
                            seedColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoTile(
                      icon: Icons.school_rounded,
                      label: 'Qualification',
                      value: _doctor!.qualification ?? 'N/A',
                      seedColor: AppColors.primary,
                      isFullWidth: true,
                    ),
                    if (_practisingClinics.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Practising Clinics',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._practisingClinics.map(
                        (clinic) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A2A3C)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.local_hospital_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        clinic.name.isNotEmpty
                                            ? clinic.name
                                            : 'Unnamed Clinic',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      if (clinic.clinicLocation.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          clinic.clinicLocation,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.65),
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),

                    if (_doctor!.description != null &&
                        _doctor!.description!.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'About Doctor',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A3C)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          _doctor!.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _openClinicMappingSheet,
                                icon: const Icon(
                                  Icons.add_business_rounded,
                                  size: 20,
                                ),
                                label: const Text(
                                  'Map Clinic',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor:
                                      AppColors.primary.withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.push(
                                    '/org/doctors/schedule-config',
                                    extra: _doctor,
                                  );
                                },
                                icon: const Icon(
                                  Icons.edit_calendar_rounded,
                                  size: 20,
                                ),
                                label: const Text(
                                  'Schedule',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? const Color(0xFF2A2A3C)
                                      : Colors.white,
                                  foregroundColor: AppColors.primary,
                                  elevation: 0,
                                  side: BorderSide(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color seedColor;
  final bool isFullWidth;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.seedColor,
    this.isFullWidth = false,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A3C) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: isFullWidth ? 3 : 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapClinicsSheet extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  const _MapClinicsSheet({required this.doctorId, required this.doctorName});
  @override
  State<_MapClinicsSheet> createState() => _MapClinicsSheetState();
}

class _MapClinicsSheetState extends State<_MapClinicsSheet> {
  late Future<ClinicMappingStatusResponse> _clinicsFuture;
  final Set<String> _selectedClinicIds = {};
  final Set<String> _alreadyMappedIds = {}; // pre-mapped — never sent to API
  bool _isSaving = false;
  bool _initDone = false;
  @override
  void initState() {
    super.initState();
    _clinicsFuture = ApiService.instance.getClinicMappingStatus(
      widget.doctorId,
    );
  }

  void _initSelections(List<ClinicMappingItem> clinics) {
    if (_initDone) return;
    _initDone = true;
    for (final c in clinics) {
      if (c.isMapped) {
        _alreadyMappedIds.add(c.id); // remember, but don't queue for API
      }
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (_selectedClinicIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one clinic to continue.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    // Send ONLY clinics the user newly selected — exclude already-mapped ones
    final newlySelected = _selectedClinicIds
        .where((id) => !_alreadyMappedIds.contains(id))
        .toList();
    if (newlySelected.isEmpty) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No new clinics selected to map.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      final response = await ApiService.instance.mapDoctorToClinics(
        widget.doctorId,
        newlySelected,
      );
      if (!mounted) return;
      final message =
          response['message']?.toString() ?? 'Doctor mapped to clinics.';
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Color(0xFF00BFA5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final error = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Color(0xFFFF5252),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Map Clinics',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.doctorName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Already mapped clinics are pre-selected. Tap to toggle.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<ClinicMappingStatusResponse>(
              future: _clinicsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  final message = error is ApiException
                      ? error.message
                      : error.toString();
                  final isNoInternet =
                      error is ApiException && error.code == 'NO_INTERNET';

                  return AppErrorState(
                    title: isNoInternet
                        ? 'No Internet Connection'
                        : 'Unable to Load Clinics',
                    message: message,
                    icon: isNoInternet
                        ? Icons.wifi_off_rounded
                        : Icons.error_outline_rounded,
                    actionLabel: 'Retry',
                    onAction: () {
                      setState(() {
                        _clinicsFuture = ApiService.instance
                            .getClinicMappingStatus(widget.doctorId);
                      });
                    },
                    compact: true,
                  );
                }
                final clinics = snapshot.data?.data ?? const [];
                if (clinics.isEmpty) {
                  return const Center(
                    child: Text(
                      'No clinics available for mapping.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _initSelections(clinics));
                });
                return StatefulBuilder(
                  builder: (context, innerSetState) {
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: clinics.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final clinic = clinics[index];
                        final isSelected = _selectedClinicIds.contains(
                          clinic.id,
                        );
                        final wasMapped = clinic.isMapped;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: (_isSaving || wasMapped)
                                ? null
                                : () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedClinicIds.remove(clinic.id);
                                      } else {
                                        _selectedClinicIds.add(clinic.id);
                                      }
                                    });
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.10)
                                    : (isDark
                                          ? const Color(0xFF2A2A3C)
                                          : Colors.grey.shade50),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey.withValues(alpha: 0.2),
                                  width: isSelected ? 1.4 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.18)
                                          : Colors.grey.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.local_hospital_rounded,
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                clinic.name,
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: isSelected
                                                          ? AppColors.primary
                                                          : null,
                                                    ),
                                              ),
                                            ),
                                            if (wasMapped)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  left: 6,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 7,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF00BFA5)
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Mapped',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF00BFA5),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          clinic.clinicLocation,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.65),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (_isSaving || wasMapped)
                                        ? null
                                        : (_) {
                                            setState(() {
                                              if (isSelected) {
                                                _selectedClinicIds.remove(
                                                  clinic.id,
                                                );
                                              } else {
                                                _selectedClinicIds.add(
                                                  clinic.id,
                                                );
                                              }
                                            });
                                          },
                                    activeColor: AppColors.primary,
                                  ),
                                ],
                              ),
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
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save Mapping (${_selectedClinicIds.where((id) => !_alreadyMappedIds.contains(id)).length} new)',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

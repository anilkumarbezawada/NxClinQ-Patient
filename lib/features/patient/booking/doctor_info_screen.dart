import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/doctor_list_response.dart';
import '../models/patient_profile_response.dart';
import 'doctor_booking_screen.dart';

class DoctorInfoScreen extends StatelessWidget {
  final DoctorModel doctor;
  final PatientProfile patient;

  const DoctorInfoScreen({
    super.key,
    required this.doctor,
    required this.patient,
  });

  // ── Navigate to booking ───────────────────────────────────────────────────
  void _openBooking(BuildContext context, PractisingClinic clinic) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => DoctorBookingScreen(
          doctor: doctor,
          clinic: clinic,
          patient: patient,
        ),
      ),
    );
  }

  // ── Pick clinic (bottom-sheet when >1 clinic) ─────────────────────────────
  void _pickClinic(BuildContext context) {
    final clinics = doctor.practisingClinics;
    if (clinics.isEmpty) return;
    if (clinics.length == 1) {
      _openBooking(context, clinics.first);
      return;
    }

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ClinicPickerSheet(
        clinics: clinics,
        onSelect: (clinic) {
          Navigator.pop(context);
          _openBooking(context, clinic);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFemale = doctor.gender?.toLowerCase() == 'female';
    final hasBookableClinic = doctor.practisingClinics.any(
      (clinic) => clinic.timings.isNotEmpty,
    );

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.pageBackground,
      body: Column(
        children: [
          // ── Fixed Non-Scrolling Header ────────────────────────────────────
          _DoctorInfoHeader(
            doctor: doctor,
            isFemale: isFemale,
            isDark: isDark,
            onBack: () => Navigator.pop(context),
          ),

          // ── Scrollable content ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Quick info chips ──────────────────────────────────
                    _QuickInfoRow(doctor: doctor),
                    const SizedBox(height: 16),

                    // ── About ─────────────────────────────────────────────
                    if (doctor.description != null &&
                        doctor.description!.trim().isNotEmpty) ...[
                      _SectionCard(
                        title: 'About',
                        icon: Icons.info_outline_rounded,
                        child: Text(
                          doctor.description!.trim(),
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? Colors.white70 : AppColors.textMuted,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Languages ─────────────────────────────────────────
                    if (doctor.languagesKnown.isNotEmpty) ...[
                      _SectionCard(
                        title: 'Languages Known',
                        icon: Icons.translate_rounded,
                        child: Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: doctor.languagesKnown
                              .map((lang) => _LangChip(label: lang))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Clinics ───────────────────────────────────────────
                    _SectionCard(
                      title: 'Available at Clinics',
                      icon: Icons.local_hospital_rounded,
                      child: doctor.practisingClinics.isEmpty
                          ? Text(
                              'No clinics mapped',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.grey,
                              ),
                            )
                          : Column(
                              children: List.generate(
                                doctor.practisingClinics.length,
                                (i) => _ClinicRow(
                                  clinic: doctor.practisingClinics[i],
                                  isLast: i == doctor.practisingClinics.length - 1,
                                  isBookable:
                                      doctor.practisingClinics[i].timings.isNotEmpty,
                                  onTap: () =>
                                      _openBooking(context, doctor.practisingClinics[i]),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 80), // space for sticky button
                  ],
                ),
              ),
            ),
          ),

          // ── Sticky Book Appointment Button ──────────────────────────────
          _BookButton(
            isEnabled: hasBookableClinic,
            onTap: hasBookableClinic ? () => _pickClinic(context) : null,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Fixed Non-Scrolling Header
// ═══════════════════════════════════════════════════════════════════════════

class _DoctorInfoHeader extends StatelessWidget {
  final DoctorModel doctor;
  final bool isFemale;
  final bool isDark;
  final VoidCallback onBack;

  const _DoctorInfoHeader({
    required this.doctor,
    required this.isFemale,
    required this.isDark,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightMint,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 208,
          child: Stack(
            children: [
              // ── Left Text Content ─────────────────────────────────────
              Positioned(
                left: 20,
                right: 136,
                top: 52,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      doctor.specialty ?? 'General Physician',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Text(
                        doctor.fullName,
                        style: AppTypography.headlineMedium.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (doctor.experience != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${doctor.experience} Exp',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // ── Right Doctor Image ─────────────────────────────────────
              Positioned(
                right: 0,
                bottom: 0,
                child: SizedBox(
                  width: 126,
                  height: 170,
                  child: Image.asset(
                    isFemale
                        ? 'assets/images/female_doctor.png'
                        : 'assets/images/male_doctor.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // ── Back Button ────────────────────────────────────────────
              Positioned(
                top: 8,
                left: 16,
                child: _CircleBtn(
                  icon: Icons.chevron_left_rounded,
                  onTap: onBack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════════════════

// ── Quick info chips (qualification) ─────────────────────────────────────
class _QuickInfoRow extends StatelessWidget {
  final DoctorModel doctor;
  const _QuickInfoRow({required this.doctor});

  @override
  Widget build(BuildContext context) {
    if (doctor.qualification == null) return const SizedBox.shrink();

    return _InfoChip(
      icon: Icons.school_rounded,
      label: doctor.qualification!,
      sublabel: 'Qualification',
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  const _InfoChip({required this.icon, required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sublabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textMain,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section card wrapper ──────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.sectionHeader.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Language chip ─────────────────────────────────────────────────────────
class _LangChip extends StatelessWidget {
  final String label;
  const _LangChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTypography.chip.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ── Clinic row inside info screen ─────────────────────────────────────────
class _ClinicRow extends StatelessWidget {
  final PractisingClinic clinic;
  final bool isLast;
  final bool isBookable;
  final VoidCallback onTap;

  const _ClinicRow({
    required this.clinic,
    required this.isLast,
    required this.isBookable,
    required this.onTap,
  });

  String _shortDayLabel(String rawDays) {
    return rawDays
        .replaceAll(RegExp(r'\bMonday\b', caseSensitive: false), 'Mon')
        .replaceAll(RegExp(r'\bTuesday\b', caseSensitive: false), 'Tue')
        .replaceAll(RegExp(r'\bWednesday\b', caseSensitive: false), 'Wed')
        .replaceAll(RegExp(r'\bThursday\b', caseSensitive: false), 'Thu')
        .replaceAll(RegExp(r'\bFriday\b', caseSensitive: false), 'Fri')
        .replaceAll(RegExp(r'\bSaturday\b', caseSensitive: false), 'Sat')
        .replaceAll(RegExp(r'\bSunday\b', caseSensitive: false), 'Sun');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        InkWell(
          onTap: isBookable ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clinic name + location + arrow
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_hospital_outlined,
                        size: 16,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clinic.clinicName,
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  clinic.clinicLocation,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isBookable
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.unavailable.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Book',
                            style: AppTypography.chipSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isBookable
                                  ? AppColors.primary
                                  : AppColors.unavailable,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            isBookable
                                ? Icons.arrow_forward_rounded
                                : Icons.block_rounded,
                            size: 12,
                            color: isBookable
                                ? AppColors.primary
                                : AppColors.unavailable,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Timings chips (keep these) ──────────────────────────
                if (clinic.timings.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: clinic.timings.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final t = clinic.timings[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _shortDayLabel(t.days),
                                style: AppTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDeep,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                t.time,
                                style: AppTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'No Slots Available',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.unavailableLight
                            : AppColors.unavailable,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                // ── SMTWTFS strip REMOVED ──────────────────────────────
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(height: 20, indent: 32),
      ],
    );
  }
}

// ── Sticky Book Appointment Button ────────────────────────────────────────
class _BookButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isEnabled;
  const _BookButton({required this.onTap, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: isEnabled
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDeep],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: isEnabled ? null : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (isEnabled)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Book Appointment',
                    style: AppTypography.buttonLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Clinic Picker Bottom Sheet ────────────────────────────────────────────
class _ClinicPickerSheet extends StatelessWidget {
  final List<PractisingClinic> clinics;
  final void Function(PractisingClinic) onSelect;

  const _ClinicPickerSheet({required this.clinics, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Select a Clinic',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose where you want to book the appointment',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            ...clinics.map((clinic) => _ClinicSheetTile(
                  clinic: clinic,
                  isDark: isDark,
                  isEnabled: clinic.timings.isNotEmpty,
                  onTap: () => onSelect(clinic),
                )),
          ],
        ),
      ),
    );
  }
}

class _ClinicSheetTile extends StatelessWidget {
  final PractisingClinic clinic;
  final bool isDark;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ClinicSheetTile({
    required this.clinic,
    required this.isDark,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isEnabled
            ? (isDark ? AppColors.darkSurface : Colors.grey.shade50)
            : (isDark
                  ? AppColors.darkSurface.withValues(alpha: 0.65)
                  : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEnabled
              ? Colors.grey.shade200
              : AppColors.unavailable.withValues(alpha: 0.18),
        ),
      ),
      child: ListTile(
        onTap: isEnabled ? onTap : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isEnabled
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.unavailable.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isEnabled ? Icons.local_hospital_outlined : Icons.block_rounded,
            color: isEnabled ? AppColors.primaryDeep : AppColors.unavailable,
            size: 18,
          ),
        ),
        title: Text(
          clinic.clinicName,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: isEnabled
                ? (isDark ? AppColors.white : AppColors.textMain)
                : AppColors.textMuted,
          ),
        ),
        subtitle: Text(
          isEnabled ? clinic.clinicLocation : 'No slots available',
          style: AppTypography.labelSmall.copyWith(
            color: isEnabled ? AppColors.textMuted : AppColors.unavailable,
            fontWeight: isEnabled ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        trailing: Icon(
          isEnabled ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
          color: isEnabled ? AppColors.primary : AppColors.unavailable,
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 24),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_error_state.dart';
import 'appointment_report_screen.dart';
import 'models/patient_appointment.dart';
import 'services/patient_appointment_service.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  late Future<PatientAppointmentsData> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _appointmentsFuture = PatientAppointmentService.instance.getAppointments();
  }

  Future<void> _refresh() async {
    setState(() {
      _appointmentsFuture = PatientAppointmentService.instance.getAppointments();
    });
    await _appointmentsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: FutureBuilder<PatientAppointmentsData>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ShimmerLoading();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final data = snapshot.data;
          if (data == null || (data.upcoming.isEmpty && data.past.isEmpty)) {
            return _buildEmptyState();
          }

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
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
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                          child: Text(
                            'My Appointments',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        TabBar(
                          indicatorColor: Colors.white,
                          indicatorWeight: 3,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white,
                          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                          tabs: const [
                            Tab(text: 'Upcoming'),
                            Tab(text: 'Past'),
                          ],

                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildList(data.upcoming, isPast: false),
                      _buildList(data.past, isPast: true),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(List<PatientAppointment> appointments, {required bool isPast}) {
    if (appointments.isEmpty) {
      return Center(
        child: Text(
          isPast ? 'No past appointments' : 'No upcoming appointments',
          style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: appointments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _AppointmentCard(appointment: appointments[index], isPast: isPast);
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final isNoInternet = error.toLowerCase().contains('no internet');

    return AppErrorState(
      title: isNoInternet
          ? 'No Internet Connection'
          : 'Unable to Load Appointments',
      message: error,
      icon: isNoInternet
          ? Icons.wifi_off_rounded
          : Icons.error_outline_rounded,
      actionLabel: 'Retry',
      onAction: _refresh,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today_rounded, size: 52, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'No Appointments Yet',
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primaryDeep),
          ),
          const SizedBox(height: 8),
          Text(
            'Book an appointment from the Doctors tab.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.teal),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
            label: Text('Refresh', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final PatientAppointment appointment;
  final bool isPast;

  const _AppointmentCard({required this.appointment, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(appointment.status);
    final isDisabled = isPast && !appointment.reportsGenerated;

    final cardContent = Container(
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey.shade200 : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: isDisabled ? 0.08 : 0.18),
          width: 1.2,
        ),
        boxShadow: isDisabled ? [] : [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date & Status Highlighted Tags
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Unified Type & Date/Time Pill
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          appointment.appointmentType == 'online' ? Icons.videocam_rounded : Icons.directions_walk_rounded,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          appointment.appointmentType.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 12,
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.schedule_rounded, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            appointment.formattedTime,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          
          // Body: Doctor Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                  child: Text(
                    appointment.doctorName.isNotEmpty ? appointment.doctorName[0].toUpperCase() : 'D',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${appointment.doctorName}',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                      // Specialty Row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getSpecialtyIcon(appointment.doctorSpecialty), size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            appointment.doctorSpecialty,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Status & Report Row
                      Row(
                        children: [
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getStatusIcon(appointment.status), size: 11, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  appointment.status.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: statusColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (appointment.reportsGenerated) ...[
                            const SizedBox(width: 8),
                            // Report Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.statusCancelled.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.statusCancelled.withValues(alpha: 0.15)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.assignment_turned_in_rounded, size: 11, color: AppColors.statusCancelled),
                                  const SizedBox(width: 4),
                                  Text(
                                    'VIEW REPORT ->',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.statusCancelled,
                                      letterSpacing: 0.3,
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
          ),
          
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // Footer: Clinic Info
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.clinicName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                      Text(
                        appointment.clinicLocation,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (appointment.reportsGenerated) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentReportScreen(
                appointmentId: appointment.id,
                doctorName: appointment.doctorName,
              ),
            ),
          );
        },
        child: cardContent,
      );
    }

    return cardContent;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return const Color(0xFF00478D);
      case 'completed':
        return const Color(0xFF006A65);
      case 'cancelled':
        return const Color(0xFF625B71);
      case 'no_show':
        return const Color(0xFFBA1A1A);
      case 'rescheduled':
        return const Color(0xFFFF5B00);
      default:
        return const Color(0xFF10B981);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Icons.check_circle_outline_rounded;
      case 'cancelled': return Icons.cancel_outlined;
      case 'no_show': return Icons.person_off_rounded;
      case 'rescheduled': return Icons.event_repeat_rounded;
      case 'scheduled': return Icons.event_available_rounded;
      default: return Icons.info_outline_rounded;
    }
  }

  IconData _getSpecialtyIcon(String specialty) {
    specialty = specialty.toLowerCase();
    if (specialty.contains('cardi')) return Icons.favorite_rounded;
    if (specialty.contains('dentist')) return Icons.health_and_safety_rounded;
    if (specialty.contains('dermato')) return Icons.face_rounded;
    if (specialty.contains('pediatric')) return Icons.child_care_rounded;
    if (specialty.contains('neuro')) return Icons.psychology_rounded;
    if (specialty.contains('ortho')) return Icons.accessibility_new_rounded;
    if (specialty.contains('ent') || specialty.contains('otorhino')) return Icons.hearing_rounded;
    if (specialty.contains('ayurveda')) return Icons.spa_rounded;
    return Icons.medical_services_rounded;
  }
}

// ── Custom Shimmer Loading Effect ─────────────────────────────────────────

class _ShimmerLoading extends StatefulWidget {
  const _ShimmerLoading();

  @override
  State<_ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<_ShimmerLoading> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 140, left: 20, right: 20),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (_, _) => Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(radius: 26, backgroundColor: Colors.grey.shade200),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 14, width: 140, color: Colors.grey.shade200),
                          const SizedBox(height: 8),
                          Container(height: 10, width: 200, color: Colors.grey.shade100),
                          const SizedBox(height: 4),
                          Container(height: 10, width: 100, color: Colors.grey.shade100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/ai_bot_icon.dart';
import '../models/doctor_list_response.dart';
import '../models/doctor_booking_board_response.dart';
import '../models/patient_profile_response.dart';

class DoctorBookingScreen extends StatefulWidget {
  final DoctorModel doctor;
  final PractisingClinic clinic;
  final PatientProfile patient;

  const DoctorBookingScreen({
    super.key,
    required this.doctor,
    required this.clinic,
    required this.patient,
  });

  @override
  State<DoctorBookingScreen> createState() => _DoctorBookingScreenState();
}

class _DoctorBookingScreenState extends State<DoctorBookingScreen> {
  DateTime _selectedDate = DateTime.now();
  late Future<DoctorBookingBoardResponse> _bookingBoardFuture;
  bool _isBooking = false;
  final ScrollController _dateScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchBookingBoard();
  }

  @override
  void dispose() {
    _dateScrollCtrl.dispose();
    super.dispose();
  }

  void _fetchBookingBoard() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    setState(() {
      _bookingBoardFuture = ApiService.instance.getDoctorBookingBoard(
        widget.doctor.id,
        widget.clinic.clinicId,
        dateStr,
      );
    });
  }
  
  void _scrollDates(bool forward) {
    if (!_dateScrollCtrl.hasClients) return;
    final currentPos = _dateScrollCtrl.offset;
    final maxPos = _dateScrollCtrl.position.maxScrollExtent;
    final double scrollAmount = 140.0; // roughly 2 dates
    
    double targetPos;
    if (forward) {
      targetPos = (currentPos + scrollAmount).clamp(0.0, maxPos);
    } else {
      targetPos = (currentPos - scrollAmount).clamp(0.0, maxPos);
    }
    
    _dateScrollCtrl.animateTo(
      targetPos,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _showConfirmationDialog(BookingSlot slot) async {
    String appointmentType = 'in_clinic';


    final bool? confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final timeStr = _formatSlotTime(slot.startAtLocal);
          final dateLabel = DateFormat('EEE, d MMM yyyy').format(_selectedDate);

          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF13131F) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 5),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 5, 10, 5),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.event_available_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Confirm Appointment',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 16)),
                          Text('Review your booking',
                              style: TextStyle(
                                  color: Colors.grey.shade700, fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: Colors.grey.shade600, size: 25),
                        onPressed: () => Navigator.pop(sheetCtx, false),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 0.5),

                // Detailed Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    children: [
                      // Date and Time Row (Compact)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isDark ? Colors.white10 : Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(dateLabel,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Colors.green.shade900)),
                            const Spacer(),
                            Container(
                                width: 1,
                                height: 14,
                                color: Colors.grey.withValues(alpha: 0.3)),
                            const Spacer(),
                            Icon(Icons.schedule_rounded,
                                size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(timeStr,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Colors.green.shade900)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Info Rows (Stacked full-width with inline sub-info)
                      _CompactInfoTile(
                        icon: Icons.person_rounded,
                        label: 'Patient',
                        value: widget.patient.name,
                        sub: widget.patient.age != null ? '${widget.patient.age} yrs' : null,
                        color: const Color(0xFF8B5CF6),
                        isDark: isDark,
                        isSubInline: true,
                      ),
                      const SizedBox(height: 8),
                      _CompactInfoTile(
                        icon: Icons.medical_services_rounded,
                        label: widget.doctor.specialty ?? '',
                        value: widget.doctor.fullName,
                        sub: null,
                        color: const Color(0xFF0EA5E9),
                        isDark: isDark,
                        isSubInline: false,
                      ),
                      const SizedBox(height: 8),
                      _CompactInfoTile(
                        icon: Icons.location_on_rounded,
                        label: '',
                        value: widget.clinic.clinicName,
                        sub: widget.clinic.clinicLocation,
                        color: const Color(0xFF00BFA5),
                        isDark: isDark,
                        isSubInline: false,
                      ),
                      const SizedBox(height: 16),

                      // Appointment type selection "strip"
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text('Appointment Type',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade600)),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _TypeStripItem(
                                  label: 'In Clinic',
                                  icon: Icons.local_hospital_rounded,
                                  isSelected: appointmentType == 'in_clinic',
                                  color: AppColors.primary,
                                  isDark: isDark,
                                  onTap: () => setSheetState(
                                      () => appointmentType = 'in_clinic'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _TypeStripItem(
                                  label: 'Online',
                                  icon: Icons.videocam_rounded,
                                  isSelected: appointmentType == 'online',
                                  color: AppColors.primary,
                                  isDark: isDark,
                                  onTap: () => setSheetState(
                                      () => appointmentType = 'online'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(sheetCtx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 20),
                              SizedBox(width: 10),
                              Text('Confirm Appointment',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom + 10),
              ],
            ),
          );
        },
      ),
    );

    if (confirmed == true) {
      await _bookAppointment(slot, appointmentType);
    }
  }

  Future<void> _bookAppointment(BookingSlot slot, String appointmentType) async {
    setState(() => _isBooking = true);
    try {
      await ApiService.instance.createAppointment({
        'patient_id': widget.patient.id,
        'doctor_id': widget.doctor.id,
        'clinic_id': widget.clinic.clinicId,
        'source': 'online',
        'status': 'scheduled',
        'appointment_type': appointmentType,
        'appointment_time': slot.startAt,
        'appointment_time_local': slot.startAtLocal,
        'timezone': slot.timezone,
      });

      if (!mounted) return;
      setState(() => _isBooking = false);
      await _showBookingSuccessDialog(slot);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
          backgroundColor: Color(0xFFFF5252),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted && _isBooking) setState(() => _isBooking = false);
    }
  }

  Future<void> _showBookingSuccessDialog(BookingSlot slot) {
    final timeStr = _formatSlotTime(
      slot.startAtLocal.isNotEmpty ? slot.startAtLocal : slot.startAt,
    );
    final dateStr = DateFormat('EEE, d MMM yyyy').format(_selectedDate);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogContext) => _BookingSuccessDialog(
        patientName: widget.patient.name,
        doctorName: widget.doctor.fullName,
        doctorSpecialty: widget.doctor.specialty ?? '',
        clinicName: widget.clinic.clinicName,
        clinicLocation: widget.clinic.clinicLocation,
        dateStr: dateStr,
        timeStr: timeStr,
        appointmentDate: _selectedDate,
        slot: slot,
        onDone: () {
          final router = GoRouter.of(context);
          Navigator.of(dialogContext, rootNavigator: true).pop();
          Navigator.of(context, rootNavigator: true).popUntil(
            (route) => route.isFirst,
          );
          router.go('/patient/appointments');
        },
      ),
    );
  }

  @override

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              // Static Premium Header
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 10, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row with back button and title
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Text(
                              'Book Appointment',
                              style: AppTypography.titleLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Subtitle row aligned beautifully
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.medical_services_outlined, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.doctor.fullName,
                                      style: AppTypography.titleMedium.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      widget.clinic.clinicName,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w700,
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
                  ),
                ),
              ),

              // Scrollable content body with refresh indicator
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _fetchBookingBoard(),
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Patient Info Strip (Highlighted Pill)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_rounded, size: 16, color: AppColors.primaryDeep),
                                const SizedBox(width: 8),
                                Text(
                                  'Booking Appointment for ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  widget.patient.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primaryDeep,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildDateSelectorWithArrows(AppColors.primary, isDark),

                         // Available Slots label
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                          child: Row(
                            children: [
                              const AiBotIcon(size: 18),
                              const SizedBox(width: 10),
                              Text('Available Slots',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : Colors.black87)),
                            ],
                          ),
                        ),

                        // Slots grid
                        FutureBuilder<DoctorBookingBoardResponse>(
                          future: _bookingBoardFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return _buildShimmerSlots(AppColors.primary, isDark);
                            }
                            if (snapshot.hasError) {
                              return _buildErrorState(snapshot.error.toString());
                            }

                            final slots = snapshot.data?.data?.slots ?? [];
                            if (slots.isEmpty) return _buildEmptyState(isDark);

                            final morningSlots = slots.where((s) {
                              final dt = DateTime.tryParse(s.startAtLocal.isNotEmpty ? s.startAtLocal : s.startAt)?.toLocal();
                              return dt != null && dt.hour < 12;
                            }).toList();

                            final afternoonSlots = slots.where((s) {
                              final dt = DateTime.tryParse(s.startAtLocal.isNotEmpty ? s.startAtLocal : s.startAt)?.toLocal();
                              return dt != null && dt.hour >= 12 && dt.hour < 17;
                            }).toList();

                            final eveningSlots = slots.where((s) {
                              final dt = DateTime.tryParse(s.startAtLocal.isNotEmpty ? s.startAtLocal : s.startAt)?.toLocal();
                              return dt != null && dt.hour >= 17;
                            }).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (morningSlots.isNotEmpty)
                                  _buildSlotSection('Morning', morningSlots, AppColors.primary, isDark),
                                if (afternoonSlots.isNotEmpty)
                                  _buildSlotSection('Afternoon', afternoonSlots, AppColors.primary, isDark),
                                if (eveningSlots.isNotEmpty)
                                  _buildSlotSection('Evening', eveningSlots, AppColors.primary, isDark),
                                const SizedBox(height: 40),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Full-screen booking loader overlay
          if (_isBooking)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 15),
                      const Text('Booking appointment...',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateSelectorWithArrows(Color color, bool isDark) {
    // Compute available weekdays from clinic data (0=Mon..6=Sun in the model,
    // but DateTime.weekday uses 1=Mon..7=Sun; scheduledAvailableDays uses
    // 0=Sun..6=Sat to match JS Date convention)
    final availDays = widget.clinic.scheduledAvailableDays; // List<int> 0-6 (Sun=0)
    const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Date',
                  style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87)),
              Row(
                children: [
                  InkWell(
                    onTap: () => _scrollDates(false),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A3C) : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => _scrollDates(true),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A3C) : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Available Days Indicator ────────────────────────────────────
        if (Theme.of(context).platform == TargetPlatform.fuchsia &&
            availDays.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(
              children: [
                Icon(Icons.event_available_rounded, size: 13,
                    color: isDark ? Colors.white54 : Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  'Available: ',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
                Expanded(
                  child: Text(
                    availDays.map((d) => dayLabels[d]).join('  ·  '),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

        SizedBox(
          height: 70,//height of calender card
          child: ListView.builder(
            controller: _dateScrollCtrl,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: 30, // Show next 30 days
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected = DateUtils.isSameDay(date, _selectedDate);
              final isToday = DateUtils.isSameDay(date, DateTime.now());

              // 0=Sun..6=Sat for scheduledAvailableDays; DateTime.weekday 1=Mon..7=Sun
              final dartWeekday = date.weekday; // 1=Mon..7=Sun
              final jsWeekday = dartWeekday % 7; // converts to 0=Sun..6=Sat
              final isAvailable = availDays.isEmpty || availDays.contains(jsWeekday);

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = date);
                  _fetchBookingBoard();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  width: 52,// width of calender card
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isDark
                            ? const Color(0xFF1E1E2E)
                            : (isAvailable ? Colors.white : Colors.grey.shade100)),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (!isAvailable
                              ? Colors.grey.shade300
                              : (isDark ? Colors.white10 : Colors.grey.shade200)),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [
                            if (!isDark)
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isToday ? 'TODAY' : DateFormat('E').format(date).toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: isToday ? 9 : 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : (!isAvailable
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade500),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        date.day.toString(),
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isSelected
                              ? Colors.white
                              : (!isAvailable
                                  ? Colors.grey.shade400
                                  : (isDark ? Colors.white : Colors.black87)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerSlots(Color color, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.6,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
      ),
      itemCount: 20,
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A3C) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.grey.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text('No Slots Available',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Text('Please check another date for availability.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final isNoInternet = error.toLowerCase().contains('no internet');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: AppErrorState(
        title: isNoInternet ? 'No Internet Connection' : 'Unable to Load Slots',
        message: error,
        icon: isNoInternet
            ? Icons.wifi_off_rounded
            : Icons.error_outline_rounded,
        actionLabel: 'Retry',
        onAction: _fetchBookingBoard,
      ),
    );
  }

  Widget _buildSlotSection(String title, List<BookingSlot> slots, Color color, bool isDark) {
    IconData titleIcon;
    Color sectionColor;

    if (title == 'Morning') {
      titleIcon = Icons.wb_sunny_rounded;
      sectionColor = Colors.orange.shade600;
    } else if (title == 'Afternoon') {
      titleIcon = Icons.light_mode_rounded;
      sectionColor = Colors.amber.shade600;
    } else {
      titleIcon = Icons.nights_stay_rounded;
      sectionColor = Colors.blue.shade700;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Row(
            children: [
              Icon(titleIcon, size: 18, color: sectionColor),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: sectionColor, fontSize: 16)),
              const SizedBox(width: 12),
              Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.grey.shade300, height: 1)),
            ],
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            final slot = slots[index];
            return _PremiumSlotTile(
              slot: slot,
              seedColor: AppColors.primary,
              isDark: isDark,
              onTap: () {
                if (slot.status == 'available') {
                  _showConfirmationDialog(slot);
                }
              },
            );
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  String _formatSlotTime(String isoString) {
    try {
      if (isoString.isEmpty) return '--:--';
      final dt = DateTime.parse(isoString);
      return DateFormat('h:mm a').format(dt.toLocal());
    } catch (_) {
      return '--:--';
    }
  }
}



// ── Premium Slot Tile ────────────────────────────────────────────────────────────
class _PremiumSlotTile extends StatefulWidget {
  final BookingSlot slot;
  final Color seedColor;
  final bool isDark;
  final VoidCallback onTap;

  const _PremiumSlotTile({
    required this.slot,
    required this.seedColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_PremiumSlotTile> createState() => _PremiumSlotTileState();
}

class _PremiumSlotTileState extends State<_PremiumSlotTile> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.94,
      upperBound: 1.0,
    );
    _ctrl.value = 1.0;
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isBooked = widget.slot.status == 'booked';
    final canTap = !isBooked;
    
    final String rawStr = widget.slot.startAtLocal.isNotEmpty 
        ? widget.slot.startAtLocal 
        : widget.slot.startAt;
        
    String timeStr = '--:--';
    try {
      final dt = DateTime.parse(rawStr).toLocal();
      timeStr = DateFormat('h:mm').format(dt);
    } catch (_) {}

    final Color bgColor = isBooked
        ? (widget.isDark ? const Color(0xFF2A2A3C) : Colors.grey.shade100)
        : (widget.isDark ? const Color(0xFF1E1E2E) : Colors.white);
    
    final Color borderColor = isBooked
        ? (widget.isDark ? Colors.white10 : Colors.grey.shade300)
        : (widget.isDark ? Colors.white10 : Colors.grey.shade200);

    final Color contentColor = isBooked
        ? Colors.grey.shade500
        : widget.seedColor;

    return GestureDetector(
      onTapDown: canTap ? (_) => _ctrl.reverse() : null,
      onTapUp: canTap
          ? (_) {
              _ctrl.forward();
              widget.onTap();
            }
          : null,
      onTapCancel: canTap ? () => _ctrl.forward() : null,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              if (!widget.isDark && !isBooked)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isBooked ? Icons.lock_rounded : Icons.schedule_rounded,
                    size: 11,
                    color: contentColor.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: contentColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: -0.4,
                      decoration: isBooked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
              if (isBooked) ...[
                const SizedBox(height: 2),
                Text(
                  'Booked',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Compact Info Tile ──────────────────────────────────────────────────────────
class _CompactInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final Color color;
  final bool isDark;
  final bool isSubInline;

  const _CompactInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    required this.color,
    required this.isDark,
    this.isSubInline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label.isNotEmpty)
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600)),
                if (isSubInline && sub != null && sub!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(value,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(sub!,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700)),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  if (sub != null && sub!.isNotEmpty)
                    Text(sub!,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ── Type Strip Item ──────────────────────────────────────────────────────────
class _TypeStripItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _TypeStripItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white10 : Colors.grey.shade300),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                fontSize: 13,
                color: isSelected ? color : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Premium Booking Success Dialog
// ═══════════════════════════════════════════════════════════════════════════════

class _BookingSuccessDialog extends StatefulWidget {
  final String patientName;
  final String doctorName;
  final String doctorSpecialty;
  final String clinicName;
  final String clinicLocation;
  final String dateStr;
  final String timeStr;
  final DateTime appointmentDate;
  final BookingSlot slot;
  final VoidCallback onDone;

  const _BookingSuccessDialog({
    required this.patientName,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.clinicName,
    required this.clinicLocation,
    required this.dateStr,
    required this.timeStr,
    required this.appointmentDate,
    required this.slot,
    required this.onDone,
  });

  @override
  State<_BookingSuccessDialog> createState() => _BookingSuccessDialogState();
}

class _BookingSuccessDialogState extends State<_BookingSuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _staggerCtrl;

  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _row1Anim;
  late Animation<double> _row2Anim;
  late Animation<double> _row3Anim;
  late Animation<double> _row4Anim;
  late Animation<double> _btnAnim;

  bool _addingToCalendar = false;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.elasticOut,
    ).drive(Tween(begin: 0.75, end: 1.0));
    _fadeAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    ).drive(Tween(begin: 0.0, end: 1.0));

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut)
        .drive(Tween(begin: 0.25, end: 0.65));

    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    Animation<double> stagger(double s, double e) => CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic),
        );
    _row1Anim = stagger(0.10, 0.40);
    _row2Anim = stagger(0.20, 0.50);
    _row3Anim = stagger(0.30, 0.65);
    _row4Anim = stagger(0.40, 0.80);
    _btnAnim  = stagger(0.55, 1.00);

    _entranceCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _staggerCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _glowCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  Future<void> _addToCalendar() async {
    if (_addingToCalendar) return;

    setState(() => _addingToCalendar = true);
    try {
      final rawStr = widget.slot.startAtLocal.isNotEmpty
          ? widget.slot.startAtLocal
          : widget.slot.startAt;
      final parsedStart = DateTime.tryParse(rawStr)?.toLocal();
      final startDt = parsedStart ?? widget.appointmentDate;
      final endDt = startDt.add(const Duration(minutes: 30));

      final doctorName = widget.doctorName.trim().isNotEmpty
          ? widget.doctorName.trim()
          : 'Doctor visit';
      final clinicName = widget.clinicName.trim();
      final clinicLocation = widget.clinicLocation.trim();
      final descriptionLines = <String>[
        'Appointment with $doctorName',
        if (clinicName.isNotEmpty) 'Clinic: $clinicName',
        if (clinicLocation.isNotEmpty) 'Address: $clinicLocation',
        'Date: ${widget.dateStr}',
        'Time: ${widget.timeStr}',
      ];

      final event = Event(
        title: 'Appointment - $doctorName',
        description: descriptionLines.join('\n'),
        location: clinicLocation.isNotEmpty ? clinicLocation : clinicName,
        startDate: startDt,
        endDate: endDt,
        allDay: false,
        iosParams: const IOSParams(
          reminder: Duration(hours: 1),
        ),
      );
      /*
      final title   = Uri.encodeComponent('Doctor Appointment — ${widget.doctorName}');
      final details = Uri.encodeComponent(
          'Appointment with ${widget.doctorName} at ${widget.clinicName}.\n${widget.clinicLocation}');
      // Native calendar insertion via add_2_calendar.

      // Google Calendar event creation URL — works in browser AND Google Calendar app
      */
      final added = await Add2Calendar.addEvent2Cal(event);
      if (!mounted) return;

      if (!added) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Calendar could not be opened. Please check whether a calendar app is available.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment added to calendar.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.message?.trim().isNotEmpty == true
                  ? error.message!.trim()
                  : 'Calendar access is unavailable on this device.',
            ),
            backgroundColor: AppColors.statusCancelled,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Something went wrong while preparing the calendar event.',
            ),
            backgroundColor: AppColors.statusCancelled,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _addingToCalendar = false);
    }
  }

  Widget _staggeredRow(Animation<double> anim, Widget child) =>
      AnimatedBuilder(
        animation: anim,
        builder: (_, _) => Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - anim.value)),
            child: child,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF13131F) : Colors.white;

    return AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (_, child) => Opacity(
        opacity: _fadeAnim.value,
        child: Transform.scale(scale: _scaleAnim.value, child: child),
      ),
      child: Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 40,
                offset: const Offset(0, 20),
                spreadRadius: -5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Gradient header ─────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 22),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    // Pulsing glow ring + Lottie
                    AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, child) => Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: _glowAnim.value),
                              blurRadius: 30,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Lottie.asset(
                          'assets/lottie/success.json',
                          fit: BoxFit.contain,
                          repeat: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Appointment Confirmed! 🎉',
                      style: AppTypography.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Your visit has been scheduled successfully',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // ── Detail cards (staggered) ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Column(
                  children: [
                    _staggeredRow(
                      _row1Anim,
                      Row(
                        children: [
                          Expanded(
                            child: _SuccessDetailCard(
                              icon: Icons.calendar_today_rounded,
                              iconColor: const Color(0xFF00BFA5),
                              label: 'Date',
                              value: widget.dateStr,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SuccessDetailCard(
                              icon: Icons.schedule_rounded,
                              iconColor: const Color(0xFF8B5CF6),
                              label: 'Time',
                              value: widget.timeStr,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _staggeredRow(
                      _row2Anim,
                      _CompactInfoTile(
                        icon: Icons.person_rounded,
                        label: 'Patient',
                        value: widget.patientName,
                        color: const Color(0xFF8B5CF6),
                        isDark: isDark,
                        isSubInline: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _staggeredRow(
                      _row3Anim,
                      _CompactInfoTile(
                        icon: Icons.medical_services_rounded,
                        label: widget.doctorSpecialty,
                        value: widget.doctorName,
                        sub: null,
                        color: const Color(0xFF0EA5E9),
                        isDark: isDark,
                        isSubInline: false,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _staggeredRow(
                      _row4Anim,
                      _CompactInfoTile(
                        icon: Icons.location_on_rounded,
                        label: '',
                        value: widget.clinicName,
                        sub: widget.clinicLocation,
                        color: const Color(0xFF00BFA5),
                        isDark: isDark,
                        isSubInline: false,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Buttons (staggered) ─────────────────────────────────────
              _staggeredRow(
                _btnAnim,
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    children: [
                      // Primary — View Appointments
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDeep],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onDone,
                              borderRadius: BorderRadius.circular(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.event_note_rounded,
                                      color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'View Appointments',
                                    style: AppTypography.buttonLarge
                                        .copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Secondary — Add to Calendar
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _addingToCalendar ? null : _addToCalendar,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            foregroundColor: AppColors.primary,
                          ),
                          child: _addingToCalendar
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                        Icons.add_circle_outline_rounded,
                                        size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Add to Calendar',
                                      style: AppTypography.buttonLarge
                                          .copyWith(color: AppColors.primary),
                                    ),
                                  ],
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
      ),
    );
  }
}

// ── Success detail card ────────────────────────────────────────────────────────
class _SuccessDetailCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isDark;

  const _SuccessDetailCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : iconColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

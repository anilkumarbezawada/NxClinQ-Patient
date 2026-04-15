import 'dart:io';

void main() {
  final content = r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/api_exception.dart';
import '../models/doctor_list_response.dart';
import '../models/clinic_mapping_status_response.dart';
import 'package:intl/intl.dart';

class DoctorScheduleConfigScreen extends StatefulWidget {
  final DoctorModel doctor;
  const DoctorScheduleConfigScreen({super.key, required this.doctor});

  @override
  State<DoctorScheduleConfigScreen> createState() =>
      _DoctorScheduleConfigScreenState();
}

class _DoctorScheduleConfigScreenState
    extends State<DoctorScheduleConfigScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoadingClinics = true;
  String? _error;
  List<ClinicMappingItem> _mappedClinics = [];
  String? _selectedClinicId;

  // Configuration
  int _selectedDuration = 15;
  int _selectedSlotInterval = 5;
  int _selectedBufferBefore = 0;
  int _selectedBufferAfter = 0;
  int _selectedMinNotice = 60;
  int _maxAdvanceDays = 30;

  // schedule windows
  final List<_WindowEntry> _windows = [];

  bool _isSaving = false;
  late TabController _tabController;
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTabIndex = _tabController.index);
      }
    });
    _fetchClinics();
    for (int i = 1; i <= 7; i++) {
      _windows.add(_WindowEntry(dayOfWeek: i));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchClinics() async {
    try {
      final res =
          await ApiService.instance.getClinicMappingStatus(widget.doctor.id);
      if (mounted) {
        setState(() {
          _mappedClinics = res.data.where((c) => c.isMapped).toList();
          _isLoadingClinics = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingClinics = false;
        });
      }
    }
  }

  Future<void> _saveConfiguration() async {
    if (_selectedClinicId == null) {
      _showErrorSnackBar('Please select a clinic first.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ApiService.instance.configureDoctorCalendar(widget.doctor.id, {
        "clinic_id": _selectedClinicId,
        "event_type_name": "General Consultation",
        "duration_minutes": _selectedDuration,
        "slot_interval_minutes": _selectedSlotInterval,
        "buffer_before_minutes": _selectedBufferBefore,
        "buffer_after_minutes": _selectedBufferAfter,
        "timezone": "Asia/Kolkata",
        "min_notice_minutes": _selectedMinNotice,
        "max_advance_days": _maxAdvanceDays
      });
      if (!mounted) return;
      _showSuccessSnackBar('Configuration saved!');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveSchedule() async {
    if (_selectedClinicId == null) {
      _showErrorSnackBar('Please select a clinic first.');
      return;
    }
    final activeWindows = _windows.where((w) => w.isActive).toList();
    if (activeWindows.isEmpty) {
      _showErrorSnackBar('Select at least one working day.');
      return;
    }
    for (final w in activeWindows) {
      if (w.startTime == null || w.endTime == null) {
        _showErrorSnackBar('Set start & end times for all selected days.');
        return;
      }
      if (w.startDate == null) {
        _showErrorSnackBar('Set a start date for all selected days.');
        return;
      }
    }
    setState(() => _isSaving = true);
    try {
      final windowsData = activeWindows.map((w) => {
            "day_of_week": w.dayOfWeek,
            "start_time":
                "${w.startTime!.hour.toString().padLeft(2, '0')}:${w.startTime!.minute.toString().padLeft(2, '0')}:00",
            "end_time":
                "${w.endTime!.hour.toString().padLeft(2, '0')}:${w.endTime!.minute.toString().padLeft(2, '0')}:00",
            "effective_start_date":
                DateFormat('yyyy-MM-dd').format(w.startDate!),
            "effective_end_date": w.endDate != null
                ? DateFormat('yyyy-MM-dd').format(w.endDate!)
                : null,
            "is_active": true
          }).toList();

      await ApiService.instance
          .createDoctorScheduleWindows(widget.doctor.id, {
        "clinic_id": _selectedClinicId,
        "timezone": "Asia/Kolkata",
        "windows": windowsData
      });

      if (!mounted) return;
      _showSuccessSnackBar('Schedule created!');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'CONFLICT') {
        _showConflictDialog();
      } else {
        _showErrorSnackBar(e.message);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showConflictDialog() {
    final seedColor = context.read<ThemeProvider>().seedColor;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppColors.error, size: 56),
        title: const Text('Configuration Required',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        content: const Text(
          'The doctor\'s calendar has not been configured yet.\n\nPlease go to the "Configuration" tab and save the setup first before creating a schedule.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actionsAlignment: MainAxisAlignment.center,
        backgroundColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _tabController.animateTo(0);
              },
              style: FilledButton.styleFrom(
                backgroundColor: seedColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Go to Configuration',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final seedColor = themeProvider.seedColor;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Schedule Setup',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                    color: Colors.white)),
            Text(
              widget.doctor.fullName +
                  (widget.doctor.specialty != null
                      ? '  ·  ${widget.doctor.specialty}'
                      : ''),
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: _isLoadingClinics
          ? Center(child: CircularProgressIndicator(color: seedColor))
          : _error != null
              ? _buildErrorState(theme, seedColor)
              : _mappedClinics.isEmpty
                  ? _buildEmptyState(theme, seedColor, isDark)
                  : _buildContent(themeProvider, theme, seedColor, isDark),
    );
  }

  Widget _buildContent(ThemeProvider themeProvider, ThemeData theme,
      Color seedColor, bool isDark) {
    return Column(
      children: [
        // ── Clinic Picker ──────────────────────────────────────────
        _buildClinicPicker(theme, seedColor, isDark),

        // ── Tabs ───────────────────────────────────────────────────
        Container(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: seedColor,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelColor: Colors.grey,
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            indicatorColor: seedColor,
            indicatorWeight: 2.5,
            tabs: const [
              Tab(text: 'Configuration'),
              Tab(text: 'Scheduling'),
            ],
          ),
        ),

        // ── Tab Content ────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildConfigurationTab(theme, seedColor, isDark),
              _buildSchedulingTab(theme, seedColor, isDark),
            ],
          ),
        ),

        // ── Persistent Bottom Button (changes with tab) ────────────
        _buildBottomAction(themeProvider, seedColor),
      ],
    );
  }

  // ── Clinic Picker ─────────────────────────────────────────────────────────

  Widget _buildClinicPicker(ThemeData theme, Color seedColor, bool isDark) {
    final isSelected = _selectedClinicId != null;
    final selectedClinic = isSelected
        ? _mappedClinics.firstWhere((c) => c.id == _selectedClinicId,
            orElse: () => _mappedClinics.first)
        : null;

    return Container(
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Clinic',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showClinicPicker(seedColor, isDark),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? seedColor.withValues(alpha: 0.06)
                    : (isDark
                        ? const Color(0xFF2A2A3C)
                        : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isSelected
                        ? seedColor.withValues(alpha: 0.4)
                        : Colors.grey.shade300,
                    width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: seedColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.local_hospital_rounded,
                        size: 18, color: seedColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: isSelected
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(selectedClinic!.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87)),
                              Text('Tap to change',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500)),
                            ],
                          )
                        : Text('Select a clinic',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.grey.shade500)),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isSelected ? seedColor : Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClinicPicker(Color seedColor, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text('Select Clinic',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const Divider(height: 1),
            ..._mappedClinics.map((c) {
              final isSelected = _selectedClinicId == c.id;
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: isSelected
                          ? seedColor.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle),
                  child: Icon(Icons.domain_rounded,
                      color: isSelected ? seedColor : Colors.grey, size: 20),
                ),
                title: Text(c.name,
                    style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600)),
                subtitle: Text(c.clinicLocation ?? '',
                    style: const TextStyle(fontSize: 12)),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded, color: seedColor)
                    : null,
                onTap: () {
                  setState(() => _selectedClinicId = c.id);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Configuration Tab ─────────────────────────────────────────────────────

  Widget _buildConfigurationTab(
      ThemeData theme, Color seedColor, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConfigCard(
            theme, seedColor, isDark,
            icon: Icons.timer_rounded,
            label: 'Consultation Duration',
            description: 'How long is each appointment?',
            options: [5, 10, 12, 15, 20, 25, 30],
            selected: _selectedDuration,
            suffix: 'min',
            onChanged: (v) => setState(() => _selectedDuration = v),
          ),
          const SizedBox(height: 12),
          _buildConfigCard(
            theme, seedColor, isDark,
            icon: Icons.linear_scale_rounded,
            label: 'Slot Interval',
            description: 'Gap between consecutive appointment slots',
            options: [5, 10, 15, 30],
            selected: _selectedSlotInterval,
            suffix: 'min',
            onChanged: (v) => setState(() => _selectedSlotInterval = v),
          ),
          const SizedBox(height: 12),
          _buildConfigCard(
            theme, seedColor, isDark,
            icon: Icons.hourglass_top_rounded,
            label: 'Buffer Before',
            description: 'Preparation time before each appointment',
            options: [0, 5, 10, 15],
            selected: _selectedBufferBefore,
            suffix: 'min',
            onChanged: (v) => setState(() => _selectedBufferBefore = v),
          ),
          const SizedBox(height: 12),
          _buildConfigCard(
            theme, seedColor, isDark,
            icon: Icons.hourglass_bottom_rounded,
            label: 'Buffer After',
            description: 'Recovery time after each appointment',
            options: [0, 5, 10, 15],
            selected: _selectedBufferAfter,
            suffix: 'min',
            onChanged: (v) => setState(() => _selectedBufferAfter = v),
          ),
          const SizedBox(height: 12),
          _buildConfigCard(
            theme, seedColor, isDark,
            icon: Icons.notifications_active_rounded,
            label: 'Minimum Notice',
            description: 'Earliest a patient can book before appointment',
            options: [5, 15, 30, 60, 120],
            selected: _selectedMinNotice,
            suffix: 'min',
            onChanged: (v) => setState(() => _selectedMinNotice = v),
          ),
          const SizedBox(height: 12),
          // Advance Days Slider Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.event_available_rounded, color: seedColor, size: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Max Advance Booking',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('How far ahead patients can book',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                        color: seedColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      Text('$_maxAdvanceDays',
                          style: TextStyle(
                              color: seedColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 22)),
                      const Text('days',
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: seedColor,
                        inactiveTrackColor: seedColor.withValues(alpha: 0.1),
                        trackHeight: 6,
                        thumbColor: Colors.white,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10, elevation: 4),
                        overlayColor: seedColor.withValues(alpha: 0.15),
                      ),
                      child: Slider(
                        value: _maxAdvanceDays.toDouble(),
                        min: 30, max: 90, divisions: 12,
                        onChanged: (v) =>
                            setState(() => _maxAdvanceDays = v.toInt()),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard(
    ThemeData theme,
    Color seedColor,
    bool isDark, {
    required IconData icon,
    required String label,
    required String description,
    required List<int> options,
    required int selected,
    required String suffix,
    required Function(int) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: seedColor, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                Text(description,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ]),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: options.map((opt) {
              final isSel = selected == opt;
              return GestureDetector(
                onTap: () => onChanged(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel
                        ? seedColor
                        : (isDark
                            ? const Color(0xFF2A2A3C)
                            : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSel
                            ? seedColor
                            : Colors.transparent),
                    boxShadow: isSel
                        ? [BoxShadow(
                            color: seedColor.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: Text('$opt $suffix',
                      style: TextStyle(
                          color: isSel
                              ? Colors.white
                              : (isDark
                                  ? Colors.white70
                                  : Colors.black87),
                          fontWeight: isSel
                              ? FontWeight.w800
                              : FontWeight.w600,
                          fontSize: 14)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Scheduling Tab ────────────────────────────────────────────────────────

  Widget _buildSchedulingTab(ThemeData theme, Color seedColor, bool isDark) {
    final activeWindows = _windows.where((w) => w.isActive).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.calendar_view_week_rounded,
                      color: seedColor, size: 20),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Working Days',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('Select days the doctor is available',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ]),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: _windows.map((w) {
                    const dayNames = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
                    final dayName = dayNames[w.dayOfWeek];
                    final isSel = w.isActive;
                    return GestureDetector(
                      onTap: () => setState(() => w.isActive = !w.isActive),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSel
                              ? seedColor
                              : (isDark
                                  ? const Color(0xFF2A2A3C)
                                  : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSel
                              ? [BoxShadow(
                                  color: seedColor.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3))]
                              : [],
                        ),
                        child: Text(dayName,
                            style: TextStyle(
                                color: isSel
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black87),
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          if (activeWindows.isEmpty) ...[
            const SizedBox(height: 48),
            Center(
              child: Column(children: [
                Icon(Icons.touch_app_rounded,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('Tap days above to configure their schedule',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ]),
            ),
          ] else ...[
            const SizedBox(height: 20),
            ...activeWindows.map((w) =>
                _buildDayWindowCard(w, theme, seedColor, isDark)),
          ],
        ],
      ),
    );
  }

  Widget _buildDayWindowCard(
      _WindowEntry w, ThemeData theme, Color seedColor, bool isDark) {
    const dayNames = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    final dayName = dayNames[w.dayOfWeek];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: seedColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: seedColor.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: seedColor.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Icon(Icons.today_rounded, color: seedColor, size: 18),
                const SizedBox(width: 8),
                Text(dayName,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: seedColor,
                        fontSize: 15)),
              ],
            ),
          ),
          // Time & date pickers
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Working Hours',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.3)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: _buildPicker(w, isStart: true, isTime: true,
                          theme: theme, seedColor: seedColor, isDark: isDark)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildPicker(w, isStart: false, isTime: true,
                          theme: theme, seedColor: seedColor, isDark: isDark)),
                ]),
                const SizedBox(height: 16),
                Text('Effective Dates',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.3)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: _buildPicker(w, isStart: true, isTime: false,
                          theme: theme, seedColor: seedColor, isDark: isDark)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildPicker(w, isStart: false, isTime: false,
                          theme: theme, seedColor: seedColor, isDark: isDark)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicker(
    _WindowEntry w, {
    required bool isStart,
    required bool isTime,
    required ThemeData theme,
    required Color seedColor,
    required bool isDark,
  }) {
    final time = isStart ? w.startTime : w.endTime;
    final date = isStart ? w.startDate : w.endDate;
    final hasValue = isTime ? time != null : date != null;

    String label;
    String value;
    if (isTime) {
      label = isStart ? 'Start Time' : 'End Time';
      value = time != null ? time.format(context) : '--:--';
    } else {
      label = isStart ? 'Start Date' : 'End Date';
      value = date != null ? DateFormat('MMM d, yy').format(date) : 'Optional';
    }

    return InkWell(
      onTap: () async {
        if (isTime) {
          final picked = await showTimePicker(
              context: context,
              initialTime: time ?? const TimeOfDay(hour: 9, minute: 0));
          if (picked != null) {
            setState(() {
              if (isStart) {
                w.startTime = picked;
              } else {
                w.endTime = picked;
              }
            });
          }
        } else {
          final now = DateTime.now();
          final first = DateTime(now.year, now.month, now.day);
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? first,
            firstDate: first,
            lastDate: DateTime(now.year + 2),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                  colorScheme: ColorScheme.fromSeed(seedColor: seedColor)),
              child: child!,
            ),
          );
          if (picked != null) {
            setState(() {
              if (isStart) {
                w.startDate = picked;
              } else {
                w.endDate = picked;
              }
            });
          } else if (!isStart) {
            setState(() => w.endDate = null);
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: hasValue
              ? seedColor.withValues(alpha: 0.06)
              : (isDark ? const Color(0xFF2A2A3C) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? seedColor.withValues(alpha: 0.3)
                : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: hasValue ? seedColor : Colors.grey.shade500,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(
                  isTime ? Icons.schedule_rounded : Icons.event_rounded,
                  size: 14,
                  color: hasValue ? seedColor : Colors.grey.shade400),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(value,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: hasValue
                              ? (isDark ? Colors.white : Colors.black87)
                              : Colors.grey.shade400),
                      overflow: TextOverflow.ellipsis)),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Bottom Action ─────────────────────────────────────────────────────────

  Widget _buildBottomAction(ThemeProvider themeProvider, Color seedColor) {
    final isConfig = _activeTabIndex == 0;
    final label = isConfig ? 'Save Configuration' : 'Create Schedule';
    final icon = isConfig ? Icons.save_rounded : Icons.check_circle_rounded;
    final action = isConfig ? _saveConfiguration : _saveSchedule;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.12))),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (_isSaving || _selectedClinicId == null) ? null : action,
            style: ElevatedButton.styleFrom(
              backgroundColor: seedColor,
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: seedColor.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor: seedColor.withValues(alpha: 0.4),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 10),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Error & Empty States ──────────────────────────────────────────────────

  Widget _buildErrorState(ThemeData theme, Color seedColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline_rounded,
              size: 64, color: AppColors.error.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('Failed to load clinics',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_error ?? '', textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isLoadingClinics = true;
                _error = null;
              });
              _fetchClinics();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: seedColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmptyState(
      ThemeData theme, Color seedColor, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: seedColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.location_off_rounded, size: 56, color: seedColor),
          ),
          const SizedBox(height: 24),
          Text('No Clinics Mapped',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(
            'Map at least one clinic to this doctor before setting up their schedule.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? const Color(0xFF2A2A3C) : Colors.grey.shade200,
                foregroundColor:
                    isDark ? Colors.white : Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Go Back',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _WindowEntry {
  int dayOfWeek;
  bool isActive = false;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  DateTime? startDate;
  DateTime? endDate;

  _WindowEntry({required this.dayOfWeek});
}
''';
  File('lib/features/organiser_admin/doctors/doctor_schedule_config_screen.dart')
      .writeAsStringSync(content);
  print('Written successfully');
}

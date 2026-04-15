import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'models/vital_record.dart';
import 'services/vitals_service.dart';

class VitalsTrackingScreen extends StatefulWidget {
  const VitalsTrackingScreen({super.key});

  @override
  State<VitalsTrackingScreen> createState() => _VitalsTrackingScreenState();
}

class _VitalsTrackingScreenState extends State<VitalsTrackingScreen> {
  final _service = VitalsService.instance;
  final _formKey = GlobalKey<FormState>();
  final _bpHigh = TextEditingController();
  final _bpLow = TextEditingController();
  final _pulse = TextEditingController();
  final _spo2 = TextEditingController();
  final _temp = TextEditingController();
  final _weight = TextEditingController();
  final _sugar = TextEditingController();
  final _notes = TextEditingController();

  List<VitalRecord> _history = <VitalRecord>[];
  bool _saving = false;

  List<TextEditingController> get _all => [
    _bpHigh,
    _bpLow,
    _pulse,
    _spo2,
    _temp,
    _weight,
    _sugar,
    _notes,
  ];

  bool get _hasInput => _all.any((c) => c.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    for (final controller in _all) {
      controller.addListener(_onChanged);
    }
    _loadHistory();
  }

  @override
  void dispose() {
    for (final controller in _all) {
      controller
        ..removeListener(_onChanged)
        ..dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadHistory() async {
    final data = await _service.fetchVitalsHistory();
    if (!mounted) return;
    setState(() {
      _history = data;
    });
  }

  String? _intValidator(String? value, String label, int min, int max) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    if (parsed == null) return 'Enter numbers';
    if (parsed < min || parsed > max) return 'Range: $min-$max';
    return null;
  }

  String? _doubleValidator(
    String? value,
    String label,
    double min,
    double max,
  ) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Enter numbers';
    if (parsed < min || parsed > max) {
      final sMin = min.toStringAsFixed(0);
      final sMax = max.toStringAsFixed(0);
      return 'Range: $sMin-$sMax';
    }
    return null;
  }

  int? _toInt(TextEditingController c) =>
      c.text.trim().isEmpty ? null : int.tryParse(c.text.trim());
  double? _toDouble(TextEditingController c) =>
      c.text.trim().isEmpty ? null : double.tryParse(c.text.trim());

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false) || !_hasInput) return;

    setState(() => _saving = true);
    final record = VitalRecord(
      recordedAt: DateTime.now(),
      systolic: _toInt(_bpHigh),
      diastolic: _toInt(_bpLow),
      heartRate: _toInt(_pulse),
      spo2: _toInt(_spo2),
      temperatureC: _toDouble(_temp),
      weightKg: _toDouble(_weight),
      bloodSugar: _toInt(_sugar),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    // LOGGING FOR BACKEND TEAM
    debugPrint('--- [BACKEND API PREVIEW] ---');
    debugPrint(jsonEncode(record.toJson()));
    debugPrint('-----------------------------');

    await _service.saveVitals(record);
    await _loadHistory();
    if (!mounted) return;
    for (final c in _all) {
      c.clear();
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Vitals recorded successfully')));
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const _VitalsHistoryScreen()),
    );
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final latest = _history.isEmpty ? null : _history.first;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              AppColors.primary.withValues(alpha: 0.05),
              const Color(0xFFEAF7F5),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _VitalsHero(
                latest: latest,
                count: _history.length,
                onHistoryTap: _openHistory,
              ),
              Expanded(child: _buildAddTab()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 24),
      children: [
        const _InfoCard(
          title: 'Home vitals made simple',
          subtitle: 'Save readings whenever you measure them.',
          icon: Icons.health_and_safety_rounded,
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              _SectionCard(
                title: 'Core Vitals',
                subtitle: 'Record blood pressure, pulse, and oxygen',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _VitalsInput(
                            controller: _bpHigh,
                            label: 'Systolic',
                            hint: '120',
                            suffix: 'mmHg',
                            validator: (v) =>
                                _intValidator(v, 'Systolic', 70, 250),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _VitalsInput(
                            controller: _bpLow,
                            label: 'Diastolic',
                            hint: '80',
                            suffix: 'mmHg',
                            validator: (v) =>
                                _intValidator(v, 'Diastolic', 40, 150),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _VitalsInput(
                            controller: _pulse,
                            label: 'Heart Rate',
                            hint: '72',
                            suffix: 'bpm',
                            validator: (v) =>
                                _intValidator(v, 'Heart rate', 30, 220),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _VitalsInput(
                            controller: _spo2,
                            label: 'SpO2',
                            hint: '98',
                            suffix: '%',
                            validator: (v) => _intValidator(v, 'SpO2', 50, 100),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Extra Measurements',
                subtitle: 'Add anything useful for future consultations',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _VitalsInput(
                            controller: _temp,
                            label: 'Temperature',
                            hint: '36.7',
                            suffix: 'C',
                            validator: (v) =>
                                _doubleValidator(v, 'Temperature', 30, 45),
                            isDecimal: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _VitalsInput(
                            controller: _weight,
                            label: 'Weight',
                            hint: '72.4',
                            suffix: 'kg',
                            validator: (v) =>
                                _doubleValidator(v, 'Weight', 1, 400),
                            isDecimal: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _VitalsInput(
                      controller: _sugar,
                      label: 'Blood Sugar',
                      hint: '110',
                      suffix: 'mg/dL',
                      validator: (v) =>
                          _intValidator(v, 'Blood sugar', 20, 600),
                    ),
                    const SizedBox(height: 12),
                    _VitalsInput(
                      controller: _notes,
                      label: 'Notes',
                      hint: 'Optional note for your doctor',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _hasInput
                            ? 'Snapshot ready for saving'
                            : 'Enter at least one vital',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _saving || !_hasInput ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryDeep,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save Vitals',
                              style: AppTypography.buttonMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VitalsHero extends StatelessWidget {
  const _VitalsHero({
    required this.latest,
    required this.count,
    required this.onHistoryTap,
  });
  final VitalRecord? latest;
  final int count;
  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00897B), Color(0xFF00BFA5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.monitor_heart_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vitals Journal',
                          style: AppTypography.headlineMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Save readings from home and keep them ready for your doctor.',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _HeroMetric(label: 'Entries Saved', value: '$count'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HeroMetric(
                      label: 'Latest Update',
                      value: latest == null
                          ? 'No records'
                          : DateFormat(
                              'dd MMM, hh:mm a',
                            ).format(latest!.recordedAt),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: onHistoryTap,
              child: const Icon(
                Icons.history_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleSmall.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _VitalsHistoryScreen extends StatefulWidget {
  const _VitalsHistoryScreen();

  @override
  State<_VitalsHistoryScreen> createState() => _VitalsHistoryScreenState();
}

class _VitalsHistoryScreenState extends State<_VitalsHistoryScreen> {
  final _service = VitalsService.instance;
  List<VitalRecord> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final data = await _service.fetchVitalsHistory();
    if (!mounted) return;
    setState(() {
      _history = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: Text(
          'Vitals History',
          style: AppTypography.headlineSmall.copyWith(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00897B), Color(0xFF00BFA5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_history.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 56),
          _EmptyHistory(onTap: () => Navigator.pop(context)),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _history.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _InfoCard(
              title: 'Vitals History',
              subtitle:
                  'Review every saved reading and use it during your consultations.',
              icon: Icons.timeline_rounded,
            );
          }
          return _HistoryCard(record: _history[index - 1]);
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primaryDeep),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleLarge.copyWith(color: AppColors.textMain),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _VitalsInput extends StatelessWidget {
  const _VitalsInput({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.suffix,
    this.maxLines = 1,
    this.isDecimal = false,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? suffix;
  final int maxLines;
  final bool isDecimal;
  final String? Function(String?)? validator;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: maxLines > 1
          ? TextInputType.multiline
          : isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textMain),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        filled: true,
        fillColor: const Color(0xFFF7FBFB),
        alignLabelWithHint: maxLines > 1,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.primaryDeep,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record});
  final VitalRecord record;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('dd MMM yyyy • hh:mm a').format(record.recordedAt),
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primaryDeep,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: record.summaryItems
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      item,
                      style: AppTypography.chip.copyWith(
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (record.notes != null && record.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FBFB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                record.notes!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
            child: const Icon(
              Icons.monitor_heart_outlined,
              size: 42,
              color: AppColors.primaryDeep,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No records found',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start saving home readings and they will appear here for future doctor visits.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDeep,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              'Add Your First Record',
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.primaryDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_error_state.dart';
import 'models/appointment_report.dart';
import 'services/patient_appointment_service.dart';

class AppointmentReportScreen extends StatefulWidget {
  final String appointmentId;
  final String doctorName;

  const AppointmentReportScreen({
    super.key,
    required this.appointmentId,
    required this.doctorName,
  });

  @override
  State<AppointmentReportScreen> createState() => _AppointmentReportScreenState();
}

class _AppointmentReportScreenState extends State<AppointmentReportScreen> {
  late Future<AppointmentReport> _reportFuture;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  void _fetchReport() {
    setState(() {
      _reportFuture = PatientAppointmentService.instance.getAppointmentReport(widget.appointmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Report: ${widget.doctorName}',
          style: AppTypography.headlineSmall.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<AppointmentReport>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to Load Report',
              message: snapshot.error.toString(),
              icon: Icons.error_outline_rounded,
              actionLabel: 'Retry',
              onAction: _fetchReport,
            );
          }

          final report = snapshot.data;
          if (report == null) {
            return const Center(child: Text('No report data found.'));
          }

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  color: AppColors.primary,
                  child: TabBar(
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: AppTypography.titleMedium,
                    tabs: const [
                      Tab(text: 'SOAP Note'),
                      Tab(text: 'Medications'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildSoapTab(report.soap),
                      _buildMedicationsTab(report),
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

  Widget _buildSoapTab(SoapNote soap) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        if (soap.subjective.isNotEmpty)
          _buildSoapCard('Subjective', soap.subjective, Icons.person_outline_rounded),
        if (soap.objective.isNotEmpty)
          _buildSoapCard('Objective', soap.objective, Icons.analytics_outlined),
        if (soap.assessment.isNotEmpty)
          _buildSoapCard('Assessment', soap.assessment, Icons.fact_check_outlined),
        if (soap.plan.isNotEmpty)
          _buildSoapCard('Plan', soap.plan, Icons.assignment_outlined),
        
        if (soap.subjective.isEmpty && soap.objective.isEmpty && soap.assessment.isEmpty && soap.plan.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                'No notes recorded.',
                style: AppTypography.bodyMedium.copyWith(color: Colors.grey.shade500),
              ),
            ),
          )
      ],
    );
  }

  Widget _buildSoapCard(String title, String content, IconData icon) {
    // Parse content into points if possible
    final points = _parseClinicalPoints(content);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDeep),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: points.map((point) => _buildClinicalPoint(point)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _parseClinicalPoints(String content) {
    if (content.isEmpty) return [];

    // Split by newlines or common bullet point indicators
    // This handles:
    // 1. Newlines
    // 2. Dash (-)
    // 3. Asterisk (*)
    // 4. Numbering (1. 2.)
    final lines = content.split(RegExp(r'\n|(?<=\w)\s*[\-\*•]\s+|^[\-\*•]\s+|^\d+\.\s+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    // If it's a single block of text with no real markers, just return it as one point
    if (lines.length <= 1) return [content.trim()];

    return lines;
  }

  Widget _buildClinicalPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMain,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsTab(AppointmentReport report) {
    final medications = report.medications;
    final investigations = report.investigations;
    final diagnosis = report.diagnosis;

    if (medications.isEmpty && investigations.isEmpty && diagnosis.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No medications or investigations recorded.',
              style: AppTypography.bodyMedium.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        if (diagnosis.isNotEmpty) ...[
          _buildDiagnosisSection(diagnosis),
          const SizedBox(height: 24),
        ],
        if (medications.isNotEmpty) ...[
          _buildMedicationTable(medications),
          const SizedBox(height: 24),
        ],
        if (investigations.isNotEmpty)
          _buildInvestigationsSection(investigations),
      ],
    );
  }

  Widget _buildDiagnosisSection(String diagnosis) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.troubleshoot, size: 18, color: Colors.amber.shade900),
              const SizedBox(width: 8),
              Text(
                'DIAGNOSIS',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.amber.shade900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            diagnosis,
            style: AppTypography.bodyMedium.copyWith(color: Colors.brown.shade900),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationTable(List<ErxMedication> medications) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'PRESCRIPTION',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.primaryDeep,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5), // Medication
                1: FlexColumnWidth(1.2), // Frequency
                2: FlexColumnWidth(1.0), // Duration
                3: FlexColumnWidth(2.0), // Remarks
              },
              border: TableBorder.symmetric(
                inside: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade50),
                  children: [
                    _buildTableCell('Medications', isHeader: true),
                    _buildTableCell('Frequency', isHeader: true),
                    _buildTableCell('Duration', isHeader: true),
                    _buildTableCell('Remarks', isHeader: true),
                  ],
                ),
                // Rows
                ...medications.map((med) => TableRow(
                  children: [
                    _buildTableCell(med.name),
                    _buildTableCell(med.frequency),
                    _buildTableCell(med.duration),
                    _buildTableCell(med.remarks),
                  ],
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvestigationsSection(List<String> investigations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'INVESTIGATIONS / LABS',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.primaryDeep,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: investigations.map((inv) => _buildClinicalPoint(inv)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTableCell(String content, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Text(
        content.isEmpty ? '-' : content,
        style: AppTypography.bodySmall.copyWith(
          fontSize: isHeader ? 12 : 13,
          fontWeight: isHeader ? FontWeight.w800 : FontWeight.w500,
          color: isHeader ? AppColors.textMuted : AppColors.textMain,
          height: 1.3,
        ),
      ),
    );
  }
}

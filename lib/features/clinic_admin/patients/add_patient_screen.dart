import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _gender;
  String? _bloodGroup;
  bool _isSaving = false;

  static const List<String> _genders = ['Male', 'Female', 'Other'];
  static const List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context),
        child: child!,
      ),
    );
    if (picked != null) {
      _dobCtrl.text =
          '${picked.day.toString().padLeft(2, '0')} / ${picked.month.toString().padLeft(2, '0')} / ${picked.year}';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_nameCtrl.text} added as a patient!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Add New Patient', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.dividerTheme.color),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.personal_injury_rounded, size: 40, color: AppColors.success),
              ),
            ),
            const SizedBox(height: 28),

            _SectionTitle('Personal Information'),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Full Name',
              child: TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Patient full name', prefixIcon: Icon(Icons.person_outline_rounded)),
                validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'Gender',
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      hint: const Text('Select'),
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.wc_rounded)),
                      items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (v) => setState(() => _gender = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _LabeledField(
                    label: 'Blood Group',
                    child: DropdownButtonFormField<String>(
                      initialValue: _bloodGroup,
                      hint: const Text('Select'),
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.bloodtype_rounded)),
                      items: _bloodGroups.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (v) => setState(() => _bloodGroup = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Date of Birth',
              child: TextFormField(
                controller: _dobCtrl,
                readOnly: true,
                onTap: _pickDOB,
                decoration: const InputDecoration(
                  hintText: 'DD / MM / YYYY',
                  prefixIcon: Icon(Icons.cake_rounded),
                  suffixIcon: Icon(Icons.calendar_month_rounded),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Date of birth required' : null,
              ),
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Phone Number',
              child: TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '+91 XXXXX XXXXX', prefixIcon: Icon(Icons.phone_outlined)),
                validator: (v) => v == null || v.isEmpty ? 'Phone required' : null,
              ),
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Address (optional)',
              child: TextFormField(
                controller: _addressCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Patient home address',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.location_on_outlined),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Save Patient', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}


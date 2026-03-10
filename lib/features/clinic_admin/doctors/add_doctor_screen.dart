import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class AddDoctorScreen extends StatefulWidget {
  const AddDoctorScreen({super.key});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  String? _specialty;
  bool _isSaving = false;

  static const List<String> _specialties = [
    'Cardiologist', 'Dermatologist', 'ENT Specialist', 'General Physician',
    'Gynecologist', 'Neurologist', 'Oncologist', 'Orthopedic Surgeon',
    'Pediatrician', 'Psychiatrist', 'Radiologist', 'Urologist',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _licenseCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dr. ${_nameCtrl.text} added successfully!'),
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
        title: Text(
          'Add New Doctor',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
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
            // Avatar placeholder
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 2),
                ),
                child: Icon(Icons.person_add_rounded, size: 40, color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 28),

            _SectionTitle('Personal Information'),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Full Name',
              child: TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(hintText: 'Dr. First Last', prefixIcon: Icon(Icons.person_outline_rounded)),
                textCapitalization: TextCapitalization.words,
                validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
              ),
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Specialty',
              child: DropdownButtonFormField<String>(
                initialValue: _specialty,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.medical_services_outlined)),
                hint: const Text('Select specialty'),
                items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _specialty = v),
                validator: (v) => v == null ? 'Please select a specialty' : null,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'Phone Number',
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: '+91 XXXXX XXXXX', prefixIcon: Icon(Icons.phone_outlined)),
                      validator: (v) => v == null || v.isEmpty ? 'Phone required' : null,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _LabeledField(
                    label: 'Experience (years)',
                    child: TextFormField(
                      controller: _expCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'e.g. 5', prefixIcon: Icon(Icons.work_outline_rounded)),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            _SectionTitle('Professional Details'),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Email Address',
              child: TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'doctor@clinic.com', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'License Number',
              child: TextFormField(
                controller: _licenseCtrl,
                decoration: const InputDecoration(hintText: 'MC/YYYY/XXX', prefixIcon: Icon(Icons.badge_outlined)),
                validator: (v) => v == null || v.isEmpty ? 'License number required' : null,
              ),
            ),
            const SizedBox(height: 40),

            // Save button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Save Doctor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
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


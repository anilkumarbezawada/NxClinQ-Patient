import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/api_exception.dart';

import '../models/org_dashboard_response.dart';

class CreateClinicScreen extends StatefulWidget {
  final OrgClinic? existingClinic;
  const CreateClinicScreen({super.key, this.existingClinic});

  @override
  State<CreateClinicScreen> createState() => _CreateClinicScreenState();
}

class _CreateClinicScreenState extends State<CreateClinicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingClinic != null) {
      final clinic = widget.existingClinic!;
      _nameCtrl.text = clinic.name;
      _locationCtrl.text = clinic.clinicLocation;
      _addressCtrl.text = clinic.clinicAddress ?? '';
      _contactCtrl.text = clinic.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _addressCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'clinic_location': _locationCtrl.text.trim(),
        'clinic_address': _addressCtrl.text.trim(),
        'phone': _contactCtrl.text.trim(),
      };
      
      final dynamic response;
      if (widget.existingClinic != null) {
        response = await ApiService.instance.updateClinic(widget.existingClinic!.id, data);
      } else {
        response = await ApiService.instance.createClinic(data);
      }
      
      if (!mounted) return;
      
      final bool isSuccess = response['success'] == true;
      final defaultSuccess = widget.existingClinic != null ? 'Clinic updated successfully!' : 'Clinic created successfully!';
      final defaultError = widget.existingClinic != null ? 'Failed to update clinic.' : 'Failed to create clinic.';
      final String serverMessage = response['message']?.toString() ?? (isSuccess ? defaultSuccess : defaultError);
      
      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(serverMessage)),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(serverMessage),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errorString = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorString),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.existingClinic != null ? 'Update Clinic' : 'Create Clinic',
          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.getPrimaryGradient(themeProvider.seedColor),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                      const Color(0xFF0369A1).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_business_rounded, color: Color(0xFF0EA5E9), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.existingClinic != null ? 'Update Clinic Details' : 'New Clinic Registration',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0369A1),
                            ),
                          ),
                          Text(
                            widget.existingClinic != null
                                ? 'Modify the details for this clinic'
                                : 'Fill in the details to register a clinic under your organisation',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _buildSectionLabel(context, 'Basic Information'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nameCtrl,
                label: 'Clinic Name',
                hint: 'e.g. City Care Clinic',
                icon: Icons.local_hospital_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (v) => v == null || v.trim().isEmpty ? 'Clinic name is required' : null,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _locationCtrl,
                label: 'Location',
                hint: 'e.g. Hyderabad, Telangana',
                icon: Icons.location_on_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (v) => v == null || v.trim().isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _addressCtrl,
                label: 'Clinic Address',
                hint: 'e.g. Road no. 11, Banjara Hills, Hyderabad, Telangana - 500081',
                icon: Icons.map_rounded,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => v == null || v.trim().isEmpty ? 'Clinic address is required' : null,
              ),
              const SizedBox(height: 24),

              _buildSectionLabel(context, 'Contact Details'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _contactCtrl,
                label: 'Contact Phone',
                hint: '+91 98765 43210 or 040 1234 5678',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Contact phone is required';
                  final phoneRegExp = RegExp(r'^\+?[\d\s-]{8,15}$');
                  if (!phoneRegExp.hasMatch(v.trim())) return 'Enter a valid mobile or landline number';
                  return null;
                },
              ),
              const SizedBox(height: 36),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.seedColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                    shadowColor: const Color(0xFF0EA5E9).withValues(alpha: 0.4),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          widget.existingClinic != null ? 'Update Clinic' : 'Create Clinic',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0EA5E9),
            letterSpacing: 0.5,
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: maxLines > 1 ? null : label,
        hintText: maxLines > 1 ? label : hint,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? (maxLines * 16.0 - 24) : 0),
          child: Icon(icon, color: const Color(0xFF0EA5E9), size: 20),
        ),
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
        ),
      ),
    );
  }


}

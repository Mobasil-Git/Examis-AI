import 'dart:io';
import 'package:examis_ai/componenets/universal%20components/universal_text_field.dart';
import 'package:examis_ai/services/template_service.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:flutter/material.dart';

class CreateInstituteForm extends StatefulWidget {
  final VoidCallback onSuccess;

  const CreateInstituteForm({Key? key, required this.onSuccess}) : super(key: key);

  @override
  State<CreateInstituteForm> createState() => _CreateInstituteFormState();
}

class _CreateInstituteFormState extends State<CreateInstituteForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final TemplateService _templateService = TemplateService();

  File? _selectedFile;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    final file = await _templateService.pickTemplateFile();
    if (file != null) {
      setState(() {
        _selectedFile = file;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a .docx template file.', style: TextStyle(color: Colors.white)),
          backgroundColor: context.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _templateService.createInstituteProfile(
      _nameController.text.trim(),
      _selectedFile!,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Institute Profile created successfully!', style: TextStyle(color: Colors.white)),
            backgroundColor: AppColors.success,
          ),
        );
      }
      _nameController.clear();
      setState(() => _selectedFile = null);
      widget.onSuccess();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to create profile. Please try again.', style: TextStyle(color: Colors.white)),
            backgroundColor: context.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: context.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: context.border, width: 1.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Add New Institute",
                style: TextStyle(
                    color: context.textPrimary,
                    fontFamily: 'Lato',
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 16),

              UniversalTextField(
                controller: _nameController,
                labelText: "Institute Name",
                hintText: "e.g., MNS University",
                prefixIcon: Icon(Icons.account_balance_outlined, color: context.textSecondary),
                validator: (value) =>
                value != null && value.trim().isNotEmpty
                    ? null
                    : "Please enter a name",
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: Icon(
                    _selectedFile != null ? Icons.check_circle : Icons.attach_file,
                    color: _selectedFile != null ? AppColors.success : context.textSecondary,
                  ),
                  label: Text(
                    _selectedFile != null
                        ? "Template Selected: ${_selectedFile!.path.split('/').last}"
                        : "Attach Header Template (.docx)",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _selectedFile != null ? context.textPrimary : context.textSecondary,
                      fontFamily: 'Lato',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    alignment: Alignment.centerLeft,
                    side: BorderSide(
                        color: _selectedFile != null ? AppColors.success : context.border,
                        width: 1.5
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18), // Matched UniversalTextField
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withAlpha(100),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      )
                  )
                      : const Text(
                    "Save Institute Profile",
                    style: TextStyle(
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
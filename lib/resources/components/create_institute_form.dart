import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'universal_text_field.dart';
import '../../repository/template_repository.dart';
import '../../utils/responsive_ui.dart';

class CreateInstituteForm extends StatefulWidget {
  final VoidCallback onSuccess;

  const CreateInstituteForm({super.key, required this.onSuccess});

  @override
  State<CreateInstituteForm> createState() => _CreateInstituteFormState();
}

class _CreateInstituteFormState extends State<CreateInstituteForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final TemplateRepository _templateRepo = TemplateRepository();

  File? _selectedFile;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    final file = await _templateRepo.pickTemplateFile();
    if (file != null) {
      setState(() {
        _selectedFile = file;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a .docx template file.', style: TextStyle(color: Colors.white)),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("User must be logged in.");

      final instituteName = _nameController.text.trim();
      final originalFileName = _selectedFile!.path.split(RegExp(r'[/\\]')).last.replaceAll(RegExp(r'\s+'), '_');

      final existingTemplates = await _templateRepo.fetchExistingTemplates(user.id);

      for (var template in existingTemplates) {
        if (template['institute_name'].toString().trim().toLowerCase() == instituteName.toLowerCase()) {
          throw Exception("An institute with the name '$instituteName' already exists.");
        }
        if (template['template_url'].toString().contains(originalFileName)) {
          throw Exception("You have already uploaded a file named '$originalFileName'. Please rename it or choose a different one.");
        }
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageFileName = '${user.id}_${timestamp}_$originalFileName';

      final publicUrl = await _templateRepo.uploadTemplateFile(storageFileName, _selectedFile!);
      await _templateRepo.insertInstitute(user.id, instituteName, publicUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Institute Profile created successfully!', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
          ),
        );
        _nameController.clear();
        setState(() => _selectedFile = null);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", ""), style: const TextStyle(color: Colors.white)),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: colorScheme.outline.withAlpha(50),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.widthPercent(0.05)), // Responsive padding
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Add New Institute",
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontFamily: 'Lato',
                  fontSize: context.isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: context.heightPercent(0.02)),
              UniversalTextField(
                controller: _nameController,
                labelText: "Institute Name",
                hintText: "e.g., MNS University",
                prefixIcon: Icon(
                  Icons.account_balance_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
                validator: (value) => value != null && value.trim().isNotEmpty ? null : "Please enter a name",
              ),
              SizedBox(height: context.heightPercent(0.02)),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: Icon(
                    _selectedFile != null ? Icons.check_circle : Icons.attach_file,
                    color: _selectedFile != null ? Colors.green : colorScheme.onSurfaceVariant,
                  ),
                  label: Text(
                    _selectedFile != null
                        ? "Template Selected: ${_selectedFile!.path.split('/').last}"
                        : "Attach Header Template (.docx)",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _selectedFile != null ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                      fontFamily: 'Lato',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: context.heightPercent(0.02), horizontal: context.widthPercent(0.04)),
                    alignment: Alignment.centerLeft,
                    side: BorderSide(
                      color: _selectedFile != null ? Colors.green : colorScheme.outline.withAlpha(50),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.heightPercent(0.03)),
              SizedBox(
                width: double.infinity,
                height: context.heightPercent(0.065), // Responsive button height
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: colorScheme.primary.withAlpha(100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: context.widthPercent(0.06),
                    height: context.widthPercent(0.06),
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    "Save Institute Profile",
                    style: TextStyle(
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                      fontSize: context.isMobile ? 16 : 18,
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
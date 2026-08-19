import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../resources/components/universal_text_field.dart';
import '../../view_models/assessment_view_model.dart';
import '../../view_models/theme_view_model.dart';
import '../../utils/responsive_ui.dart';
import 'manual_course_entry_view.dart';
import 'review_syllabus_view.dart';

class CourseCatalogView extends StatefulWidget {
  const CourseCatalogView({super.key});

  @override
  State<CourseCatalogView> createState() => _CourseCatalogViewState();
}

class _CourseCatalogViewState extends State<CourseCatalogView> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  String? _selectedDepartmentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AssessmentViewModel>();
      vm.fetchBatches();
      vm.fetchDepartments();
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      if (_searchController.text != query) return;

      try {
        final vm = context.read<AssessmentViewModel>();
        final String? activeBatchId = vm.selectedBatch?['id'];

        if (activeBatchId == null || _selectedDepartmentId == null) {
          setState(() => _isSearching = false);
          return;
        }

        final generalDeptId = vm.generalDepartment?['id'];
        var supabaseQuery = Supabase.instance.client
            .from('master_courses')
            .select('id, course_code, title, credit_hours, departments(name)')
            .eq('batch_id', activeBatchId);

        if (generalDeptId != null && _selectedDepartmentId != generalDeptId) {
          supabaseQuery = supabaseQuery.or(
            'department_id.eq.$_selectedDepartmentId,department_id.eq.$generalDeptId',
          );
        } else {
          supabaseQuery = supabaseQuery.eq(
            'department_id',
            _selectedDepartmentId!,
          );
        }

        final response = await supabaseQuery
            .or('course_code.ilike.%$query%,title.ilike.%$query%')
            .limit(15);

        if (mounted && _searchController.text == query) {
          setState(() {
            _searchResults = List<Map<String, dynamic>>.from(response);
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final assessmentVM = context.watch<AssessmentViewModel>();
    final themeVM = context.watch<ThemeViewModel>();

    final hasSearched = _searchController.text.isNotEmpty;
    final noResults = hasSearched && !_isSearching && _searchResults.isEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // Dynamic AppBar coloring based on theme mode
        backgroundColor: themeVM.isDarkMode ? colorScheme.surface : colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Add Course",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(context.widthPercent(0.06)),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilters(context, assessmentVM, colorScheme, themeVM),
                SizedBox(height: context.heightPercent(0.025)),
                Text(
                  "Search University Catalog",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    fontSize: context.isMobile ? 18 : 20,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.005)),
                Text(
                  "Find your course to instantly import its official CLOs and PLOs.",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'Lato',
                    fontSize: context.isMobile ? 13 : 15,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.02)),
                TextField(
                  controller: _searchController,
                  onChanged: _performSearch,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontFamily: 'Lato',
                  ),
                  decoration: InputDecoration(
                    hintText: "e.g., CS-304 or Programming",
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch("");
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isSearching
                ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
                : noResults
                ? _buildNotFoundState(context, colorScheme)
                : _buildResultsList(context, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
      BuildContext context,
      AssessmentViewModel vm,
      ColorScheme colorScheme,
      ThemeViewModel themeVM,
      ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFlatDropdown(
                context: context,
                value: vm.selectedBatch?['id'],
                hint: "Select Session Batch",
                items: vm.availableBatches,
                displayKey: 'batch_name',
                colorScheme: colorScheme,
                onChanged: (newId) {
                  if (newId != null) {
                    final newBatch = vm.availableBatches.firstWhere(
                          (b) => b['id'] == newId,
                    );
                    vm.updateSelectedBatch(newBatch);
                    _performSearch(_searchController.text);
                  }
                },
              ),
            ),
            SizedBox(width: context.widthPercent(0.03)),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: IconButton(
                icon: Icon(Icons.add_chart_rounded, color: colorScheme.primary),
                tooltip: "Create New Session",
                onPressed: () => _showAddBatchDialog(context, vm, colorScheme),
              ),
            ),
          ],
        ),
        SizedBox(height: context.heightPercent(0.015)),
        _buildFlatDropdown(
          context: context,
          value: _selectedDepartmentId,
          hint: "Filter by Department",
          items: vm.departments,
          displayKey: 'name',
          colorScheme: colorScheme,
          onChanged: (newId) {
            setState(() => _selectedDepartmentId = newId);
            _performSearch(_searchController.text);
          },
        ),
      ],
    );
  }

  Widget _buildFlatDropdown({
    required BuildContext context,
    required String? value,
    required String hint,
    required List<Map<String, dynamic>> items,
    required String displayKey,
    required ColorScheme colorScheme,
    required Function(String?) onChanged,
  }) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.widthPercent(0.04),
          vertical: context.heightPercent(0.005)
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: bgColor,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colorScheme.primary,
          ),
          hint: Text(
            hint,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((item) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item[displayKey],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    fontSize: context.isMobile ? 14 : 16,
                  ),
                ),
              );
            }).toList();
          },
          items: items.map((item) {
            final isSelected = value == item['id'];
            final isGeneral = item[displayKey].toString().contains('General');
            return DropdownMenuItem<String>(
              value: item['id'] as String,
              child: Text(
                item[displayKey],
                style: TextStyle(
                  color: isGeneral
                      ? Colors.orange
                      : (isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface),
                  fontFamily: 'Lato',
                  fontWeight: isSelected || isGeneral
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, ColorScheme colorScheme) {
    if (_searchResults.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_books_outlined,
                size: context.isMobile ? 64 : 80,
                color: colorScheme.onSurfaceVariant.withAlpha(100),
              ),
              SizedBox(height: context.heightPercent(0.02)),
              Text(
                "Select filters and search to import a course",
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(context.widthPercent(0.06)),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final course = _searchResults[index];
        final deptName = course['departments']?['name'] ?? 'Unknown Dept';
        final isGeneral = deptName.toString().contains('General');

        return Card(
          elevation: 0,
          color: colorScheme.surface,
          margin: EdgeInsets.only(bottom: context.heightPercent(0.02)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outline.withAlpha(50)),
          ),
          child: Padding(
            padding: EdgeInsets.all(context.widthPercent(0.04)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(context.widthPercent(0.03)),
                      decoration: BoxDecoration(
                        color: isGeneral
                            ? Colors.orange.withAlpha(20)
                            : colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isGeneral ? Icons.public : Icons.account_balance,
                        color: isGeneral ? Colors.orange : colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: context.widthPercent(0.04)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${course['course_code']}: ${course['title']}",
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.bold,
                              fontSize: context.isMobile ? 16 : 18,
                            ),
                          ),
                          SizedBox(height: context.heightPercent(0.01)),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildBadge(
                                isGeneral ? "🌍 $deptName" : "🏛️ $deptName",
                                isGeneral ? Colors.orange : colorScheme.primary,
                              ),
                              _buildBadge(
                                "⏱️ ${course['credit_hours'] ?? 'N/A'}",
                                Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.heightPercent(0.02)),
                SizedBox(
                  width: double.infinity,
                  height: context.heightPercent(0.06), // Responsive Button
                  child: ElevatedButton(
                    onPressed: () async {
                      final userId =
                          Supabase.instance.client.auth.currentUser?.id;
                      if (userId == null) return;

                      try {
                        try {
                          await Supabase.instance.client
                              .from('user_courses')
                              .insert({
                            'user_id': userId,
                            'course_id': course['id'],
                          });
                        } catch (_) {}

                        final cloResponse = await Supabase.instance.client
                            .from('master_clos')
                            .select('description, domain, bt_level, plo_id')
                            .eq('course_id', course['id']);

                        if (!context.mounted) return;
                        context.read<AssessmentViewModel>().setImportedCourse(
                          course['course_code'],
                          course['title'],
                          List<Map<String, dynamic>>.from(cloResponse),
                          course['credit_hours'] ?? "3(3-0)",
                          deptName,
                        );

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Course loaded successfully!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to load course: $e"),
                            backgroundColor: colorScheme.error,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Import Course",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          fontFamily: 'Lato',
        ),
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.widthPercent(0.08)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(context.widthPercent(0.06)),
              decoration: BoxDecoration(
                color: colorScheme.error.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: context.isMobile ? 64 : 80,
                color: colorScheme.error,
              ),
            ),
            SizedBox(height: context.heightPercent(0.03)),
            Text(
              "Course Not Found",
              style: TextStyle(
                color: colorScheme.onSurface,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
                fontSize: context.isMobile ? 20 : 24,
              ),
            ),
            SizedBox(height: context.heightPercent(0.015)),
            Text(
              "It looks like this course isn't in the global catalog yet. Help us build the library by uploading your syllabus!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'Lato',
                fontSize: context.isMobile ? 14 : 16,
                height: 1.5,
              ),
            ),
            SizedBox(height: context.heightPercent(0.04)),
            SizedBox(
              width: double.infinity,
              height: context.heightPercent(0.065),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null && context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      ),
                    );

                    try {
                      final vm = context.read<AssessmentViewModel>();
                      final parsedJson = await vm.extractCourseWithGemini(
                        image,
                      );

                      if (!context.mounted) return;
                      Navigator.pop(context);

                      if (parsedJson != null) {
                        final success = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              ReviewSyllabusView(aiExtractedData: parsedJson),
                        );

                        if (success == true && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Course published to Catalog and added to your library!",
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              "Failed to extract data. Please try a clearer image.",
                            ),
                            backgroundColor: colorScheme.error,
                          ),
                        );
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: $e"),
                          backgroundColor: colorScheme.error,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(
                  Icons.document_scanner_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  "Scan Syllabus (AI Extract)",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            SizedBox(height: context.heightPercent(0.02)),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManualCourseEntryView(),
                  ),
                );
              },
              child: Text(
                "Enter Manually",
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showAddBatchDialog(
    BuildContext context,
    AssessmentViewModel vm,
    ColorScheme colorScheme,
    ) {
  final startYearCtrl = TextEditingController();
  final endYearCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Add New Academic Session",
          style: TextStyle(
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Enter the starting and ending years for the new batch.",
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: UniversalTextField(
                    controller: startYearCtrl,
                    labelText: "Start Year",
                    hintText: "e.g., 2027",
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: UniversalTextField(
                    controller: endYearCtrl,
                    labelText: "End Year",
                    hintText: "e.g., 2031",
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final startYear = int.tryParse(startYearCtrl.text);
              final endYear = int.tryParse(endYearCtrl.text);

              if (startYear == null ||
                  endYear == null ||
                  startYear >= endYear) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      "Please enter valid chronological years.",
                    ),
                    backgroundColor: colorScheme.error,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Creating session..."),
                  duration: Duration(seconds: 1),
                ),
              );

              final success = await vm.createNewBatch(startYear, endYear);

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Session created successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      "Failed to create session. It may already exist.",
                    ),
                    backgroundColor: colorScheme.error,
                  ),
                );
              }
            },
            child: const Text(
              "Create",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}
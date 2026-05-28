import 'package:examis_ai/componenets/universal%20components/universal_text_field.dart';
import 'package:examis_ai/pages/review_syllabus_page.dart';
import 'package:examis_ai/provider/assessment_provider.dart';
import 'package:examis_ai/provider/theme_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'manual_course_entry_page.dart';

class CourseCatalogPage extends StatefulWidget {
  const CourseCatalogPage({super.key});

  @override
  State<CourseCatalogPage> createState() => _CourseCatalogPageState();
}

class _CourseCatalogPageState extends State<CourseCatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  String? _selectedDepartmentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AssessmentProvider>();
      provider.fetchBatches();
      provider.fetchDepartments();
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
        final provider = context.read<AssessmentProvider>();
        final String? activeBatchId = provider.selectedBatch?['id'];

        if (activeBatchId == null || _selectedDepartmentId == null) {
          setState(() => _isSearching = false);
          return;
        }

        final generalDeptId = provider.generalDepartment?['id'];

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
        print("Search Error: $e");
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final assessmentProvider = context.watch<AssessmentProvider>();

    final hasSearched = _searchController.text.isNotEmpty;
    final noResults = hasSearched && !_isSearching && _searchResults.isEmpty;

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode
            ? context.surface
            : AppColors.primary,
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? context.surface
                  : AppColors.primary,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilters(context, assessmentProvider, themeProvider),
                const SizedBox(height: 20),

                const Text(
                  "Search University Catalog",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Find your course to instantly import its official CLOs and PLOs.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Lato',
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),

                // Flat, theme-aware search bar
                TextField(
                  controller: _searchController,
                  onChanged: _performSearch,
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                    fontFamily: 'Lato',
                  ),
                  decoration: InputDecoration(
                    hintText: "e.g., CS-304 or Programming",
                    hintStyle: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white54
                          : Colors.black38,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: themeProvider.isDarkMode
                                  ? Colors.white54
                                  : Colors.black38,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch("");
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: themeProvider.isDarkMode
                        ? Theme.of(context).colorScheme.background
                        : Colors.white,
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
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : noResults
                ? _buildNotFoundState()
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    AssessmentProvider provider,
    ThemeProvider themeProvider,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFlatDropdown(
                context: context,
                value: provider.selectedBatch?['id'],
                hint: "Select Session Batch",
                items: provider.availableBatches,
                displayKey: 'batch_name',
                themeProvider: themeProvider,
                onChanged: (newId) {
                  if (newId != null) {
                    final newBatch = provider.availableBatches.firstWhere(
                      (b) => b['id'] == newId,
                    );
                    provider.updateSelectedBatch(newBatch);
                    _performSearch(_searchController.text);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode
                    ? Theme.of(context).colorScheme.background
                    : Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.add_chart_rounded,
                  color: AppColors.primary,
                ),
                tooltip: "Create New Session",
                onPressed: () {
                  _showAddBatchDialog(context, provider);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildFlatDropdown(
          context: context,
          value: _selectedDepartmentId,
          hint: "Filter by Department",
          items: provider.departments,
          displayKey: 'name',
          themeProvider: themeProvider,
          onChanged: (newId) {
            setState(() => _selectedDepartmentId = newId);
            _performSearch(_searchController.text);
          },
        ),
      ],
    );
  }

  // 🚀 REBUILT: 100% Flat, opaque, and strictly theme-aware. Zero shadows/glass.
  Widget _buildFlatDropdown({
    required BuildContext context,
    required String? value,
    required String hint,
    required List<Map<String, dynamic>> items,
    required String displayKey,
    required ThemeProvider themeProvider,
    required Function(String?) onChanged,
  }) {
    final bgColor = themeProvider.isDarkMode
        ? Theme.of(context).colorScheme.background
        : Colors.white;
    final textColor = themeProvider.isDarkMode ? Colors.white : Colors.black87;
    final hintColor = themeProvider.isDarkMode
        ? Colors.white54
        : Colors.black38;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: bgColor,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primary,
          ),
          hint: Text(hint, style: TextStyle(color: hintColor)),
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((item) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item[displayKey],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
                      : (isSelected ? AppColors.primary : textColor),
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

  Widget _buildResultsList() {
    if (_searchResults.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_books_outlined,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withAlpha(100),
              ),
              const SizedBox(height: 16),
              Text(
                "Select filters and search to import a course",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final course = _searchResults[index];
        final deptName = course['departments']?['name'] ?? 'Unknown Dept';
        final isGeneral = deptName.toString().contains('General');

        return Card(
          elevation: 0,
          // 🚀 Flat card
          color: context.surface,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withAlpha(50),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isGeneral
                            ? Colors.orange.withAlpha(20)
                            : AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isGeneral ? Icons.public : Icons.account_balance,
                        color: isGeneral ? Colors.orange : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${course['course_code']}: ${course['title']}",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildBadge(
                                isGeneral ? "🌍 $deptName" : "🏛️ $deptName",
                                isGeneral ? Colors.orange : AppColors.primary,
                              ),
                              _buildBadge(
                                "⏱️ ${course['credit_hours'] ?? 'N/A'}",
                                AppColors.success,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // 🚀 Restored the core import logic
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
                        } catch (insertError) {
                          print(
                            "Course is already in library. Proceeding to fetch data...",
                          );
                        }

                        final cloResponse = await Supabase.instance.client
                            .from('master_clos')
                            .select('description, domain, bt_level, plo_id')
                            .eq('course_id', course['id']);

                        if (!context.mounted) return;

                        context.read<AssessmentProvider>().setImportedCourse(
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
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to load course: $e"),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
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

  Widget _buildNotFoundState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Course Not Found",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "It looks like this course isn't in the global catalog yet. Help us build the library by uploading your syllabus!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'Lato',
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
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
                      builder: (_) => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    );

                    try {
                      final provider = context.read<AssessmentProvider>();
                      final parsedJson = await provider.extractCourseWithGemini(
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
                              ReviewSyllabusSheet(aiExtractedData: parsedJson),
                        );

                        if (success == true && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Course published to Catalog and added to your library!",
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Failed to extract data. Please try a clearer image.",
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: $e"),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(
                  Icons.document_scanner_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  "Scan Syllabus (AI Extract)",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManualCourseEntryPage(),
                  ),
                );
              },
              child: Text(
                "Enter Manually",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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

void _showAddBatchDialog(BuildContext context, AssessmentProvider provider) {
  final startYearCtrl = TextEditingController();
  final endYearCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Add New Academic Session",
          style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter the starting and ending years for the new batch.",
              style: TextStyle(fontFamily: 'Lato', fontSize: 13),
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
              backgroundColor: AppColors.primary,
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
                  const SnackBar(
                    content: Text("Please enter valid chronological years."),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext); // Close dialog immediately

              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Creating session..."),
                  duration: Duration(seconds: 1),
                ),
              );

              final success = await provider.createNewBatch(startYear, endYear);

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Session created successfully!"),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Failed to create session. It may already exist.",
                    ),
                    backgroundColor: AppColors.error,
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

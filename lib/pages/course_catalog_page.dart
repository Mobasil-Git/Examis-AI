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
        final response = await Supabase.instance.client
            .from('master_courses')
            .select('id, course_code, title')
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
                const Text(
                  "Search University Catalog",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Find your course to instantly import its official CLOs and PLOs.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Lato',
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: _performSearch,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontFamily: 'Lato',
                  ),
                  decoration: InputDecoration(
                    hintText: "e.g., CS-304 or Programming",
                    hintStyle: const TextStyle(color: Colors.black38),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.black38,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch("");
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
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

  Widget _buildResultsList() {
    if (_searchResults.isEmpty) {
      return Center(
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
              "Search to import a course",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final course = _searchResults[index];
        return Card(
          elevation: 0,
          color: context.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withAlpha(50),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
              ),
            ),
            // 🚀 FIX: Used course_code instead of code
            title: Text(
              "${course['course_code']}: ${course['title']}",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Text(
                "Official Catalog • Pre-loaded CLOs",
                style: TextStyle(fontFamily: 'Lato', fontSize: 12),
              ),
            ),
            trailing: ElevatedButton(
              onPressed: () async {
                final userId = Supabase.instance.client.auth.currentUser?.id;
                if (userId == null) return;

                try {
                  // 1. Link the course to the user
                  await Supabase.instance.client.from('user_courses').insert({
                    'user_id': userId,
                    'course_id': course['id'],
                  });

                  // 🚀 2. FIX: Fetch the actual CLOs from Supabase!
                  final cloResponse = await Supabase.instance.client
                      .from('master_clos')
                      .select('description, domain, bt_level, plo_id')
                      .eq('course_id', course['id']);

                  if (!context.mounted) return;

                  // 🚀 3. FIX: Pass the CLOs as the third parameter!
                  context.read<AssessmentProvider>().setImportedCourse(
                    course['course_code'],
                    course['title'],
                    List<Map<String, dynamic>>.from(cloResponse),
                  );

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Course & CLOs imported successfully!"),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "You already have this course in your library!",
                      ),
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
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Import",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
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
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // The Manual Entry Button
            TextButton(
              onPressed: () {
                // 🚀 Send them to the shiny new Manual Entry Page!
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

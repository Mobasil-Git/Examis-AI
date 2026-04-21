import 'package:examis_ai/componenets/social_icon/build_social_icon.dart';
import 'package:examis_ai/componenets/universal%20components/universal_text_field.dart';
import 'package:examis_ai/pages/auth/login_page.dart';
import 'package:examis_ai/provider/auth_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:examis_ai/utils/responive_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordHidden = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Helper widget for Social Buttons

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_outlined,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.024)),
                Text(
                  "Create Account",
                  style: TextStyle(
                    color: context.textPrimary,
                    fontFamily: 'Lato',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.009)),
                Text(
                  "Start generating smart assessments today.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontFamily: 'Lato',
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.045)),

                // --- Signup Form Card ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    children: [
                      UniversalTextField(
                        controller: nameController,
                        labelText: "Full Name",
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                          color: context.textSecondary,
                        ),
                      ),
                      SizedBox(height: context.heightPercent(0.017)),
                      UniversalTextField(
                        controller: emailController,
                        labelText: "Email Address",
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: context.textSecondary,
                        ),
                      ),
                      SizedBox(height: context.heightPercent(0.017)),
                      UniversalTextField(
                        controller: passwordController,
                        labelText: "Password",
                        obscureText: isPasswordHidden,
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: context.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordHidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: context.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordHidden = !isPasswordHidden;
                            });
                          },
                        ),
                      ),

                      SizedBox(height: context.heightPercent(0.033)),

                      // --- SIGNUP BUTTON ---
                      GestureDetector(
                        onTap: () async {
                          FocusScope.of(context).unfocus();

                          if (nameController.text.isEmpty ||
                              emailController.text.isEmpty ||
                              passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please fill in all fields."),
                              ),
                            );
                            return;
                          }

                          final auth = context.read<AuthProvider>();
                          final success = await auth.signUp(
                            context,
                            fullName: nameController.text.trim(),
                            email: emailController.text.trim(),
                            password: passwordController.text.trim(),
                          );

                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Account created! Please log in.",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          }
                        },
                        child: Container(
                          height: 55,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: context.primary,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: context.watch<AuthProvider>().isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Text(
                                    "Sign Up",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      SizedBox(height: context.heightPercent(0.03)),

                      // --- THE NEW SOCIAL LOGIN SECTION ---
                      Row(
                        children: [
                          Expanded(child: Divider(color: context.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "Or",
                              style: TextStyle(
                                color: context.textSecondary,
                                fontFamily: 'Lato',
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: context.border)),
                        ],
                      ),

                      SizedBox(height: context.heightPercent(0.025)),

                      BuildSocialIcon(
                        image: 'assets/social_icons/google.png', // Assuming you added the PNG!
                        text: "Continue with Google", // The new text parameter
                        onTap: () async {
                          await context.read<AuthProvider>().signInWithGoogle(context);
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: context.heightPercent(0.025)),

                // --- Switch to Login ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: context.textSecondary,
                        fontFamily: 'Lato',
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        "Log In",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

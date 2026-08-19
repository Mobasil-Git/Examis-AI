import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../resources/components/build_social_icon.dart';
import '../../resources/components/universal_text_field.dart';
import '../../view_models/auth_view_model.dart';
import '../../utils/responsive_ui.dart';
import '../../utils/routes/route_names.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.06)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(context.widthPercent(0.04)),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add_alt_1_outlined,
                    color: colorScheme.primary,
                    size: context.isMobile ? 40 : 50,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.024)),
                Text(
                  "Create Account",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontFamily: 'Lato',
                    fontSize: context.isMobile ? 28 : 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.009)),
                Text(
                  "Start generating smart assessments today.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'Lato',
                    fontSize: context.isMobile ? 14 : 16,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.045)),
                Container(
                  padding: EdgeInsets.all(context.widthPercent(0.05)),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outline.withAlpha(50)),
                  ),
                  child: Column(
                    children: [
                      UniversalTextField(
                        controller: nameController,
                        hintText: "Full Name",
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: context.heightPercent(0.017)),
                      UniversalTextField(
                        controller: emailController,
                        hintText: "Email Address",
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: context.heightPercent(0.017)),
                      UniversalTextField(
                        controller: passwordController,
                        hintText: "Password",
                        obscureText: isPasswordHidden,
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordHidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordHidden = !isPasswordHidden;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: context.heightPercent(0.033)),
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

                          final authVM = context.read<AuthViewModel>();
                          final success = await authVM.signUp(
                            context,
                            fullName: nameController.text.trim(),
                            email: emailController.text.trim(),
                            password: passwordController.text.trim(),
                          );

                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Account created! Please log in."),
                                backgroundColor: Colors.green,
                              ),
                            );
                            // Implementing Custom Routing
                            Navigator.pushReplacementNamed(context, RouteNames.login);
                          }
                        },
                        child: Container(
                          height: context.heightPercent(0.065),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: context.watch<AuthViewModel>().isLoading
                                ? SizedBox(
                              height: context.widthPercent(0.06),
                              width: context.widthPercent(0.06),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                                : Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.bold,
                                fontSize: context.isMobile ? 16 : 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: context.heightPercent(0.03)),
                      Row(
                        children: [
                          Expanded(child: Divider(color: colorScheme.outline.withAlpha(50))),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.04)),
                            child: Text(
                              "Or",
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontFamily: 'Lato',
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: colorScheme.outline.withAlpha(50))),
                        ],
                      ),
                      SizedBox(height: context.heightPercent(0.025)),
                      BuildSocialIcon(
                        image: 'assets/social_icons/google.png',
                        text: "Continue with Google",
                        onTap: () async {
                          await context.read<AuthViewModel>().signInWithGoogle(context);
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.heightPercent(0.025)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontFamily: 'Lato',
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Implementing Custom Routing
                        Navigator.pushReplacementNamed(context, RouteNames.login);
                      },
                      child: Text(
                        "Log In",
                        style: TextStyle(
                          color: colorScheme.primary,
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
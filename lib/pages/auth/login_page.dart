import 'package:examis_ai/componenets/dialogs/forgot_password_dialogs.dart';
import 'package:examis_ai/componenets/social_icon/build_social_icon.dart';
import 'package:examis_ai/componenets/universal%20components/universal_text_field.dart';
import 'package:examis_ai/layout/master_layout.dart';
import 'package:examis_ai/pages/auth/signup_page.dart';
import 'package:examis_ai/provider/auth_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:examis_ai/utils/responive_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordHidden = true;

  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();

    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          final AuthChangeEvent event = data.event;

          if (event == AuthChangeEvent.signedIn) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MasterLayout()),
              );
            }
          }
        });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
                    Icons.auto_awesome,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.025)),
                Text(
                  "Welcome Back!",
                  style: TextStyle(
                    color: context.textPrimary,
                    fontFamily: 'Lato',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.009)),
                Text(
                  "Log in to continue generating assessments.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontFamily: 'Lato',
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.05)),
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
                        controller: emailController,
                        hintText: "Email Address",
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: context.textSecondary,
                        ),
                      ),
                      SizedBox(height: context.heightPercent(0.017)),
                      UniversalTextField(
                        controller: passwordController,
                        hintText:  "Password",
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ForgotPasswordFlow.showEmailPrompt(
                              context,
                              initialEmail: emailController.text,
                            );
                          },
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: context.heightPercent(0.017)),

                      Consumer<AuthProvider>(
                        builder: (context, auth, child) {
                          return GestureDetector(
                            onTap: auth.isLoading
                                ? null
                                : () async {
                                    FocusScope.of(context).unfocus();

                                    if (emailController.text.isEmpty ||
                                        passwordController.text.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Please enter your email and password.",
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final success = await auth.signIn(
                                      context,
                                      email: emailController.text.trim(),
                                      password: passwordController.text.trim(),
                                    );

                                    if (success && context.mounted) {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const MasterLayout(),
                                        ),
                                            (route) => false,
                                      );
                                    }
                                  },
                            child: Container(
                              height: 55,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: auth.isLoading
                                    ? context.primary.withAlpha(150)
                                    : context.primary,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Center(
                                child: auth.isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        "Log In",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Lato',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: context.heightPercent(0.03)),

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
                        image: 'assets/social_icons/google.png',
                        text: "Continue with Google",
                        onTap: () async {
                          await context.read<AuthProvider>().signInWithGoogle(
                            context,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: context.heightPercent(0.024)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: context.textSecondary,
                        fontFamily: 'Lato',
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const SignupPage()),
                        );
                      },
                      child: const Text(
                        "Sign Up",
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

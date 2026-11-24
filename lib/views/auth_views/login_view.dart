import 'dart:async';
import 'package:examisai/view_models/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../resources/components/forgot_password_dialogs.dart';
import '../../resources/components/build_social_icon.dart';
import '../../resources/components/universal_text_field.dart';
import '../../utils/responsive_ui.dart';
import '../../utils/routes/route_names.dart';


class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordHidden = true;

  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();

    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn && mounted) {
        Navigator.pushReplacementNamed(context, RouteNames.home);
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
                    Icons.auto_awesome,
                    color: colorScheme.primary,
                    size: context.isMobile ? 40 : 50,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.025)),
                Text(
                  "Welcome Back!",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontFamily: 'Lato',
                    fontSize: context.isMobile ? 28 : 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.009)),
                Text(
                  "Log in to continue generating assessments.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'Lato',
                    fontSize: context.isMobile ? 14 : 16,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.05)),
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ForgotPasswordFlow.showEmailPrompt(
                              context,
                              initialEmail: emailController.text,
                            );
                          },
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: context.heightPercent(0.017)),

                      // Optimization: Only this action button listens to AuthState changes
                      Consumer(
                        builder: (context, ref, child) {
                          final isLoading = ref.watch(authProvider.select((s) => s.isLoading));

                          return GestureDetector(
                            onTap: isLoading
                                ? null
                                : () async {
                              FocusScope.of(context).unfocus();

                              if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please enter your email and password."),
                                  ),
                                );
                                return;
                              }

                              final success = await ref.read(authProvider.notifier).signIn(
                                context,
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                              );

                              if (success && context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  RouteNames.home,
                                      (route) => false,
                                );
                              }
                            },
                            child: Container(
                              height: context.heightPercent(0.065),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isLoading
                                    ? colorScheme.primary.withAlpha(150)
                                    : colorScheme.primary,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Center(
                                child: isLoading
                                    ? SizedBox(
                                  height: context.widthPercent(0.06),
                                  width: context.widthPercent(0.06),
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                                    : Text(
                                  "Log In",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.bold,
                                    fontSize: context.isMobile ? 16 : 18,
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
                          await ref.read(authProvider.notifier).signInWithGoogle(context);
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
                        color: colorScheme.onSurfaceVariant,
                        fontFamily: 'Lato',
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, RouteNames.signUp);
                      },
                      child: Text(
                        "Sign Up",
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
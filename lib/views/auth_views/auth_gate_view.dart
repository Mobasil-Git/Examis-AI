import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard_views/master_layout_view.dart';
import 'login_view.dart';

class AuthGateView extends ConsumerWidget {
  const AuthGateView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          return const MasterLayoutView();
        } else {
          return const LoginView();
        }
      },
    );
  }
}
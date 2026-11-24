import 'package:examisai/view_models/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/routes/route_names.dart';
import 'utils/routes/routes.dart';
import 'utils/theme/theme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await GoogleSignIn.instance.initialize(
    serverClientId: dotenv.env['WEB_CLIENT_ID'],
  );

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Examis AI',
      themeMode: themeState.themeMode,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      initialRoute: RouteNames.splash,
      onGenerateRoute: Routes.generateRoutes,
    );
  }
}
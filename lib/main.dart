import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/routes/route_names.dart';
import 'utils/routes/routes.dart';
import 'utils/theme/theme.dart';
import 'view_models/theme_view_model.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/assessment_view_model.dart';
import 'view_models/history_view_model.dart';
import 'view_models/template_view_model.dart';

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
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => AssessmentViewModel()),
        ChangeNotifierProvider(create: (_) => HistoryViewModel()),
        ChangeNotifierProvider(create: (_) => TemplateViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeViewModel>(
      builder: (context, themeVM, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Examis AI',
          themeMode: themeVM.themeMode,
          theme: TAppTheme.lightTheme,
          darkTheme: TAppTheme.darkTheme,
          initialRoute: RouteNames.splash,
          onGenerateRoute: Routes.generateRoutes,
        );
      },
    );
  }
}
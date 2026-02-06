import 'package:crmportal_app/dashboard.dart';
import 'package:crmportal_app/login_page.dart';
import 'package:crmportal_app/admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..checkAuth()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.profile == null) {
            return const LoginPage();
          }

          final email = appState.profile?['email'] as String?;
          if (email == 'unzoloap@gmail.com') {
            return const AdminDashboard();
          }

          return const Dashboard();
        },
      ),
      theme: ThemeData(primaryColor: Colors.green[100], useMaterial3: true),
    );
  }
}

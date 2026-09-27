import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/khaata_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QarzKhaataApp());
}

/// Root widget for Qarz Khaata Application.
class QarzKhaataApp extends StatelessWidget {
  const QarzKhaataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KhaataProvider()..init(),
      child: MaterialApp(
        title: 'Qarz Khaata',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E3C72),
            primary: const Color(0xFF1E3C72),
            secondary: const Color(0xFF2A5298),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
          ),
          fontFamily: 'Roboto',
        ),
        home: Consumer<KhaataProvider>(
          builder: (context, provider, child) {
            if (provider.isLoggedIn) {
              return const DashboardScreen();
            }
            return const AuthScreen();
          },
        ),
      ),
    );
  }
}

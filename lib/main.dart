import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'utils/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final state = AppState();
  await state.init();

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const LumenApp(),
    ),
  );
}

class LumenApp extends StatelessWidget {
  const LumenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return MaterialApp(
      title: 'Lumen',
      debugShowCheckedModeBanner: false,
      theme: LumenTheme.lightTheme,
      darkTheme: LumenTheme.darkTheme,
      themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: state.currentUser == null ? const AuthScreen() : const MainShell(),
    );
  }
}

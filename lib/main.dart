import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'providers/theme_provider.dart';
import 'providers/build_session_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/build_screen.dart';
import 'services/timer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final storageService = StorageService();
  await storageService.init();

  await TimerService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(storageService)),
        ChangeNotifierProvider(create: (_) => BuildSessionProvider(storageService)),
        ChangeNotifierProvider(create: (_) => SettingsProvider(storageService)),
      ],
      child: const IntervaApp(),
    ),
  );
}

class IntervaApp extends StatelessWidget {
  const IntervaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    return MaterialApp(
      title: 'Interva',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const BuildScreen(),
    );
  }
}

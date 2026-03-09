import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_screen.dart';
import 'widgets/auth_wrapper.dart';
import 'utils/scroll_behavior.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  
  final themeIndex = prefs.getInt('themeMode') ?? 0;
  final colorValue = prefs.getInt('themeColor') ?? Colors.blueAccent.value;
  final hapticsEnabled = prefs.getBool('hapticsEnabled') ?? true;
  final lockEnabled = prefs.getBool('lockEnabled') ?? false;
  final gridCols = prefs.getInt('gridColumns') ?? 2;
  
  MyApp.themeNotifier.value = ThemeMode.values[themeIndex];
  MyApp.themeColorNotifier.value = Color(colorValue);
  MyApp.hapticNotifier.value = hapticsEnabled;
  MyApp.lockNotifier.value = lockEnabled;
  MyApp.gridColumnsNotifier.value = gridCols;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(
    ThemeMode.system,
  );
  
  static final ValueNotifier<Color> themeColorNotifier = ValueNotifier(
    Colors.blueAccent,
  );

  static final ValueNotifier<bool> hapticNotifier = ValueNotifier(true);

  static final ValueNotifier<bool> lockNotifier = ValueNotifier(false);

  static final ValueNotifier<int> gridColumnsNotifier = ValueNotifier(2);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return ValueListenableBuilder<Color>(
          valueListenable: themeColorNotifier,
          builder: (context, currentColor, _) {
            return MaterialApp(
              title: '12A1 THPT Đơn Dương',
              scrollBehavior: NoStretchScrollBehavior(),
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: currentColor),
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: currentColor,
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
              ),
              themeMode: currentMode,
              themeAnimationDuration: const Duration(milliseconds: 500),
              themeAnimationCurve: Curves.easeInOut,
              home: const AuthWrapper(child: MainScreen()),
            );
          },
        );
      },
    );
  }
}

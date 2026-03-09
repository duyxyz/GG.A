import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../main.dart';
import '../utils/haptics.dart';

class AuthWrapper extends StatefulWidget {
  final Widget child;
  const AuthWrapper({super.key, required this.child});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (MyApp.lockNotifier.value) {
      _checkAuth();
    } else {
      _isAuthenticated = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && MyApp.lockNotifier.value && !_isAuthenticated) {
      _checkAuth();
    }
    
    if (state == AppLifecycleState.paused && MyApp.lockNotifier.value) {
      setState(() => _isAuthenticated = false);
    }
  }

  Future<void> _checkAuth() async {
    if (_isAuthenticating || !MyApp.lockNotifier.value) return;
    
    setState(() => _isAuthenticating = true);

    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        setState(() => _isAuthenticated = true);
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Xác thực để mở khóa kho ảnh 12A1',
      );

      if (mounted) {
        setState(() {
          _isAuthenticated = didAuthenticate;
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticated = true; 
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MyApp.lockNotifier,
      builder: (context, isLockEnabled, _) {
        if (!isLockEnabled || _isAuthenticated) {
          return widget.child;
        }

        return Scaffold(
          body: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_person_outlined, size: 100, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 64),
                IconButton.filled(
                  onPressed: _checkAuth,
                  icon: const Icon(Icons.fingerprint, size: 32),
                  padding: const EdgeInsets.all(20),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

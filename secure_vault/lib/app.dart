import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/vault_provider.dart';
import 'providers/theme_provider.dart';
import 'shared/theme/app_theme.dart';
import 'features/auth/setup_screen.dart';
import 'features/unlock/unlock_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/auth/login_screen.dart';
import 'providers/auth_provider.dart';

class SecureVaultApp extends ConsumerWidget {
  SecureVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'UB Secure',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const _AuthGate(),
    );
  }
}

/// Decides whether to show Firebase Login or the Vault Gate
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return LoginScreen();
        }
        return const _VaultGate();
      },
      loading: () => Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Text('Error: $err', style: TextStyle(color: Colors.redAccent)),
        ),
      ),
    );
  }
}

/// Decides which screen to show based on vault state.
class _VaultGate extends ConsumerWidget {
  const _VaultGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = ref.watch(vaultProvider);

    switch (vaultState.status) {
      case VaultStatus.uninitialized:
        return SetupScreen();
      case VaultStatus.locked:
        return UnlockScreen();
      case VaultStatus.unlocked:
        return DashboardScreen();
      case VaultStatus.loading:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'Deriving encryption key...',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        );
      case VaultStatus.error:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                SizedBox(height: 16),
                Text(
                  vaultState.errorMessage ?? 'An error occurred',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Reset to check state again
                    ref.invalidate(vaultProvider);
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        );
    }
  }
}

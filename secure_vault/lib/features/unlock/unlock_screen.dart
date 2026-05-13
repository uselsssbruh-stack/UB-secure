import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vault_provider.dart';
import '../../providers/auth_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../dashboard/dashboard_screen.dart';

/// Unlock screen — master password entry to decrypt the vault.
class UnlockScreen extends ConsumerStatefulWidget {
  UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen>
    with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _error;
  int _attempts = 0;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _error = 'Please enter your master password');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await ref.read(vaultProvider.notifier).unlockVault(password);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
      } else {
        _attempts++;
        _shakeController.forward(from: 0);
        setState(() {
          _error = _attempts >= 3
              ? 'Incorrect password ($_attempts attempts)'
              : 'Incorrect master password';
        });
        _passwordController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            icon: Icon(Icons.logout_rounded, color: AppColors.accentCyan, size: 18),
            label: Text('Switch Account', style: TextStyle(color: AppColors.accentCyan)),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo with scale animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Image.asset(
                    'assets/logo/UBsecureLogoWithTitle.png',
                    width: 180,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Enter your master password to unlock',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.of(context).textSecondary,
                  ),
                ),
                SizedBox(height: 40),

                // Password field with shake animation
                AnimatedBuilder3(
                  listenable: _shakeAnimation,
                  builder: (context, child) {
                    final dx = _shakeAnimation.value *
                        10 *
                        ((_shakeController.value * 6).floor().isOdd ? -1 : 1) *
                        (1 - _shakeController.value);
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: child,
                    );
                  },
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    autofocus: true,
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Master Password',
                      prefixIcon: Icon(
                        Icons.key_rounded,
                        color: _error != null
                            ? AppColors.accentRed
                            : AppColors.accentCyan,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.of(context).textMuted,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      errorText: _error,
                      errorStyle: TextStyle(color: AppColors.accentRed),
                    ),
                    onSubmitted: (_) => _unlock(),
                  ),
                ),
                SizedBox(height: 24),

                // Unlock button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _unlock,
                    icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.of(context).backgroundDark,
                            ),
                          )
                        : Icon(Icons.lock_open_rounded),
                    label: Text(_isLoading ? 'Decrypting...' : 'Unlock Vault'),
                  ),
                ),
                SizedBox(height: 32),

                // Footer hint
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.security_rounded,
                      size: 14,
                      color: AppColors.of(context).textMuted,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Zero-knowledge encryption — your data stays on your device',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.of(context).textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedBuilder3 extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  AnimatedBuilder3({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

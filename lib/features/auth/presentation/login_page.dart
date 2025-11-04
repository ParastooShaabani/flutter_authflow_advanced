import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_authflow_advanced/core/di/locator.dart';
import 'package:flutter_authflow_advanced/features/auth/data/auth_repository.dart';
import 'package:flutter_authflow_advanced/routes/app_routes.dart';

/// - Mobile: triggers real AppAuth (OIDC + PKCE) and navigates to Home.
/// - Web: uses mock flow → navigates to ConsentPage with the auth code.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _busy = false;

  Future<void> _handleSignIn() async {
    if (_busy) return;
    setState(() => _busy = true);

    final ctx = context;
    try {
      final auth = sl<AuthRepository>();
      // Mobile: performs the full flow; Web: returns a mock code to exchange.
      final codeOrFlag = await auth.beginAuth();

      if (!ctx.mounted) return;

      if (kIsWeb) {
        Navigator.of(ctx).pushNamed(AppRoutes.consent, arguments: codeOrFlag);
      } else {
        Navigator.of(ctx).pushReplacementNamed(AppRoutes.home);
      }
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Sign in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 0,
            color: scheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Icon(Icons.lock_outline, size: 48, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'AuthFlow Advanced',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kIsWeb
                        ? 'Demo PKCE (mock) on Web; real OAuth2/OIDC on mobile.'
                        : 'Sign in with your identity provider (OIDC + PKCE).',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: _busy
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.login),
                      onPressed: _busy ? null : _handleSignIn,
                      label: Text(_busy ? 'Signing in…' : 'Sign in'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

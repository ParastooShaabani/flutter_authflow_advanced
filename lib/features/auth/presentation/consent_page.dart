import 'package:flutter/material.dart';
import 'package:flutter_authflow_advanced/core/di/locator.dart';
import 'package:flutter_authflow_advanced/features/auth/data/auth_repository.dart';
import 'package:flutter_authflow_advanced/routes/app_routes.dart';

/// Consent screen displayed during the mock/web OAuth flow.
/// In mobile (AppAuth) flow, this page is typically skipped.
class ConsentPage extends StatelessWidget {
  const ConsentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final code = args is String ? args : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Consent')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Allow demo app to access your profile?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: code == null
                    ? null
                    : () async {
                        final repo = sl<AuthRepository>();
                        await repo.exchangeCode(code);
                        if (!context.mounted) return;
                        Navigator.of(
                          context,
                        ).pushReplacementNamed(AppRoutes.home);
                      },
                child: const Text('Allow'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

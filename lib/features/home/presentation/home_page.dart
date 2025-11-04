import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_authflow_advanced/core/di/locator.dart';
import 'package:flutter_authflow_advanced/core/network/dio_client.dart';
import 'package:flutter_authflow_advanced/features/auth/data/auth_repository.dart';
import 'package:flutter_authflow_advanced/routes/app_routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? secret;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ctx = context;
    final repo = sl<AuthRepository>();
    final tokens = await repo.current();

    if (tokens == null) {
      if (!ctx.mounted) return;
      Navigator.of(ctx).pushReplacementNamed(AppRoutes.login);
      return;
    }

    try {
      final Dio dio = buildAuthedDio();
      // Mobile demo call; ok on Android/iOS. (CORS will block this on Web.)
      final res = await dio.get('https://postman-echo.com/get');
      if (!ctx.mounted) return;
      setState(() => secret = res.data.toString());
    } catch (e) {
      if (!ctx.mounted) return;
      setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget body() {
      if (secret != null) {
        return Row(
          children: [
            Icon(Icons.verified_user, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(secret!)),
          ],
        );
      }
      if (error != null) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: scheme.error),
            const SizedBox(width: 12),
            Expanded(child: Text('Error: $error')),
          ],
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Home (Protected)')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: body(),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ctx = context;
          await sl<AuthRepository>().logout();
          if (!ctx.mounted) return;
          Navigator.of(ctx).pushReplacementNamed(AppRoutes.login);
        },
        label: const Text('Logout'),
        icon: const Icon(Icons.logout),
      ),
    );
  }
}


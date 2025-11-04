import 'package:flutter/material.dart';
import 'package:flutter_authflow_advanced/core/di/locator.dart';
import 'package:flutter_authflow_advanced/routes/app_routes.dart';
import 'package:flutter_authflow_advanced/features/auth/data/auth_repository.dart';

/// - Initializes dependency injection and token storage
/// - Restores session (if tokens exist and are not expired)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();

  // Decide the initial route based on stored tokens
  final authRepo = sl<AuthRepository>();
  final tokenSet = await authRepo.current();
  final initialRoute =
  (tokenSet != null && !tokenSet.isExpired) ? AppRoutes.home : AppRoutes.login;

  runApp(App(initialRoute: initialRoute));
}

class App extends StatelessWidget {
  const App({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuthFlow Advanced',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.lightGreen,
      ),
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: initialRoute,
    );
  }
}

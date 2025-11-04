import 'package:flutter/material.dart';
import 'package:flutter_authflow_advanced/features/auth/presentation/login_page.dart';
import 'package:flutter_authflow_advanced/features/auth/presentation/consent_page.dart';
import 'package:flutter_authflow_advanced/features/auth/presentation/callback_page.dart';
import 'package:flutter_authflow_advanced/features/home/presentation/home_page.dart';

class AppRoutes {
  static const login = '/';
  static const consent = '/consent';
  static const callback = '/callback';
  static const home = '/home';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _page(const LoginPage(), settings);
      case consent:
        return _page(const ConsentPage(), settings);
      case callback:
        return _page(const CallbackPage(), settings);
      case home:
        return _page(const HomePage(), settings);
      default:
        return _page(const LoginPage(), settings);
    }
  }

  static MaterialPageRoute _page(Widget page, RouteSettings settings) =>
      MaterialPageRoute(builder: (_) => page, settings: settings);
}

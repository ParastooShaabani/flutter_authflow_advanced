import 'package:dio/dio.dart';
import 'package:flutter_authflow_advanced/core/auth/appauth_service.dart';
import 'package:flutter_authflow_advanced/core/storage/token_store.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_authflow_advanced/core/mock/mock_auth_server.dart';
import 'package:flutter_authflow_advanced/features/auth/data/auth_repository.dart';

/// Global service locator instance.
/// Use `sl<T>()` anywhere to retrieve a registered dependency.
final sl = GetIt.instance;

/// Registers all dependencies used across the app.
/// Handles platform-specific bindings (real AppAuth vs mock flow for web).
Future<void> setupLocator() async {
  final dio = Dio();

  if (kIsWeb) {
    dio.options.baseUrl = Uri.base.origin; // e.g. http://localhost:12345
  }

  // Shared instances
  sl.registerSingleton<Dio>(Dio());

  // Token storage (secure on mobile, local on web)
  final store = TokenStoreImpl();
  await store.init();
  sl.registerSingleton<TokenStore>(store);

  // Platform-specific auth setup
  if (kIsWeb) {
    // Mock server for web flow
    final mock = MockAuthServer();
    sl
      ..registerSingleton<MockAuthServer>(mock)
      ..registerSingleton<AuthRepository>(
        AuthRepository(mock: mock, store: store),
      );
  } else {
    // Real AppAuth for Android / iOS
    final appAuth = AppAuthService();
    sl
      ..registerSingleton<AppAuthService>(appAuth)
      ..registerSingleton<AuthRepository>(
        AuthRepository.mobile(appAuth: appAuth, store: store),
      );
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_authflow_advanced/core/auth/appauth_service.dart';
import 'package:flutter_authflow_advanced/core/mock/mock_auth_server.dart';
import 'package:flutter_authflow_advanced/core/storage/token_store.dart';
import 'package:flutter_authflow_advanced/features/auth/domain/models/token_set.dart';

/// AuthRepository is the heart of authentication layer
/// It bridges AppAuthService (real OIDC) and MockAuthServer (web)
/// manages token persistence, and unifies all flows, a clean implementation.

class AuthRepository {
  final MockAuthServer? mock;
  final AppAuthService? appAuth;
  final TokenStore store;

  AuthRepository({required this.mock, required this.store}) : appAuth = null;
  AuthRepository.mobile({required this.appAuth, required this.store}) : mock = null;

  /// Begin login flow (native or mock)
  Future<String> beginAuth() async {
    if (!kIsWeb && appAuth != null) {
      await appAuth!.login();
      final access = await appAuth!.readAccess();
      final refresh = await appAuth!.readRefresh();
      if (access == null || refresh == null) throw Exception('login_failed');
      await _persistTokenPair(access, refresh);
      return 'native_login_started';
    }

    // Mock (web)
    final code = await mock!.authorize(codeChallenge: 'demo');
    return code;
  }

  Future<TokenSet?> current() => store.read();

  /// Exchange authorization code for tokens
  Future<TokenSet> exchangeCode(String code) async {
    if (!kIsWeb && appAuth != null) {
      final access = await appAuth!.readAccess();
      final refresh = await appAuth!.readRefresh();
      if (access == null || refresh == null) throw Exception('not_authenticated');
      return _persistTokenPair(access, refresh);
    }

    final t = await mock!.exchange(code: code, codeVerifier: 'demo');
    await store.save(t);
    return t;
  }

  /// Refresh token (native or mock)
  Future<TokenSet> refresh() async {
    final cur = await current();
    if (cur == null) throw Exception('not_authenticated');

    if (!kIsWeb && appAuth != null) {
      await appAuth!.refresh();
      final access = await appAuth!.readAccess();
      final refresh = await appAuth!.readRefresh();
      if (access == null || refresh == null) throw Exception('refresh_failed');
      return _persistTokenPair(access, refresh);
    }

    final t = await mock!.refresh(cur.refreshToken);
    await store.save(t);
    return t;
  }

  /// Logout
  Future<void> logout() async {
    if (!kIsWeb && appAuth != null) {
      await appAuth!.logout();
    }
    await store.clear();
  }

  /// Helper — persist tokens to store and return TokenSet
  Future<TokenSet> _persistTokenPair(String access, String refresh) async {
    final t = TokenSet(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );
    await store.save(t);
    return t;
  }
}

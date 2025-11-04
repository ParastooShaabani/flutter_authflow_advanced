import 'dart:async';
import 'dart:math';
import 'package:flutter_authflow_advanced/features/auth/domain/models/token_set.dart';

/// in-memory mock of an OAuth2/OIDC Authorization Server.
/// Used for Web builds and unit tests to simulate:
/// - `/authorize` endpoint → returns an auth code
/// - `/token` endpoint → returns access/refresh tokens
/// - `/refresh` endpoint → issues a new access token
/// Behaves asynchronously to mimic real network delays.

class MockAuthServer {
  final _rand = Random();

  /// Simulates `/authorize` endpoint
  Future<String> authorize({required String codeChallenge}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'auth_code_${_rand.nextInt(999999)}';
  }

  /// Simulates `/token` exchange endpoint
  Future<TokenSet> exchange({
    required String code,
    required String codeVerifier,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();

    return TokenSet(
      accessToken: 'access_${_rand.nextInt(999999)}',
      refreshToken: 'refresh_${_rand.nextInt(999999)}',
      expiresAt: now.add(const Duration(minutes: 15)),
    );
  }

  /// Simulates `/token` refresh endpoint
  Future<TokenSet> refresh(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();

    return TokenSet(
      accessToken: 'access_${_rand.nextInt(999999)}',
      refreshToken: refreshToken,
      expiresAt: now.add(const Duration(minutes: 15)),
    );
  }
}
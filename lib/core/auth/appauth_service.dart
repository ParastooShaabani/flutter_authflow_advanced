import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_authflow_advanced/core/env/app_env.dart';
import 'package:flutter_authflow_advanced/core/auth/auth_keys.dart';

class AppAuthService {
  AppAuthService();

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  bool _inFlight = false;

  /// Perform Authorization Code + PKCE login (native; web not supported here).
  Future<void> login() async {
    if (kIsWeb) {
      throw UnimplementedError('Use mock flow on Web for now.');
    }
    if (_inFlight) return;
    _inFlight = true;

    try {
      final res = await _appAuth
          .authorizeAndExchangeCode(
            AuthorizationTokenRequest(
              AppEnv.auth0ClientId,
              AppEnv.redirectUri,
              discoveryUrl: AppEnv.discoveryUrl,
              scopes: AppEnv.scopes,
              promptValues: const ['login'],
            ),
          )
          .timeout(const Duration(seconds: 30));

      if (res.accessToken == null) {
        throw Exception('Login failed or cancelled');
      }

      await _secure.write(key: AuthKeys.accessToken, value: res.accessToken);
      await _secure.write(key: AuthKeys.refreshToken, value: res.refreshToken);
      await _secure.write(
        key: AuthKeys.accessExpiresAt,
        value: res.accessTokenExpirationDateTime?.toIso8601String(),
      );
      await _secure.write(key: AuthKeys.idToken, value: res.idToken);

      if (kDebugMode) {
        final idClaims = _safeDecodeJwt(res.idToken);
        final atClaims = _safeDecodeJwt(res.accessToken);
        _logLoginSuccess(
          access: res.accessToken,
          refresh: res.refreshToken,
          id: res.idToken,
          accessExp: res.accessTokenExpirationDateTime,
          idClaims: idClaims,
          accessClaims: atClaims,
        );
      }
    } on TimeoutException {
      throw Exception('Login timed out. Check browser/redirect config.');
    } finally {
      _inFlight = false;
    }
  }

  /// Refresh access token using stored refresh token.
  Future<void> refresh() async {
    final rt = await _secure.read(key: AuthKeys.refreshToken);
    if (rt == null) throw Exception('No refresh_token');

    final res = await _appAuth.token(
      TokenRequest(
        AppEnv.auth0ClientId,
        AppEnv.redirectUri,
        discoveryUrl: AppEnv.discoveryUrl,
        refreshToken: rt,
        scopes: AppEnv.scopes,
      ),
    );

    if (res.accessToken == null) throw Exception('Refresh failed');

    await _secure.write(key: AuthKeys.accessToken, value: res.accessToken);
    await _secure.write(
      key: AuthKeys.accessExpiresAt,
      value: res.accessTokenExpirationDateTime?.toIso8601String(),
    );
    if (res.refreshToken != null) {
      await _secure.write(key: AuthKeys.refreshToken, value: res.refreshToken);
    }

    if (kDebugMode) {
      _debug('🔄 Refresh OK  access exp: ${res.accessTokenExpirationDateTime}');
    }
  }

  /// End session (best effort) and clear local secure storage.
  Future<void> logout() async {
    final idToken = await _secure.read(key: AuthKeys.idToken);
    try {
      await _appAuth
          .endSession(
            EndSessionRequest(
              idTokenHint: idToken,
              postLogoutRedirectUrl: AppEnv.logoutRedirectUri,
              discoveryUrl: AppEnv.discoveryUrl,
            ),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // ignore network/UI issues
    } finally {
      await _secure.deleteAll();
      if (kDebugMode) _debug('👋 Logged out and cleared secure storage');
    }
  }

  Future<String?> readAccess() => _secure.read(key: AuthKeys.accessToken);

  Future<String?> readRefresh() => _secure.read(key: AuthKeys.refreshToken);

  Future<String?> readId() => _secure.read(key: AuthKeys.idToken);
}

void _logLoginSuccess({
  required String? access,
  required String? refresh,
  required String? id,
  required DateTime? accessExp,
  Map<String, dynamic>? idClaims,
  Map<String, dynamic>? accessClaims,
}) {
  _debug('🔐 Login OK');
  _debug('  access:  ${_short(access)}');
  _debug('  refresh: ${_short(refresh)}');
  _debug('  id:      ${_short(id)}');
  _debug('  access exp: $accessExp');

  if (idClaims != null) {
    _debug(
      '  id.claims: sub=${idClaims["sub"]} email=${idClaims["email"]} '
      'iss=${idClaims["iss"]} aud=${idClaims["aud"]}',
    );
  } else {
    _debug('  id.claims: <not a JWT or could not decode>');
  }
  _debug('  access.claims: ${accessClaims ?? "<opaque or undecodable>"}');
}

void _debug(Object? msg) {
  // ignore: avoid_print
  print(msg);
}

String _short(String? v, {int take = 14}) {
  if (v == null) return 'null';
  return v.length <= take ? v : '${v.substring(0, take)}…';
}

Map<String, dynamic>? _safeDecodeJwt(String? jwt) {
  if (jwt == null) return null;
  try {
    final parts = jwt.split('.');
    if (parts.length < 2) return null; // not a JWT
    String norm(String s) {
      final pad = (4 - s.length % 4) % 4;
      return s
          .padRight(s.length + pad, '=')
          .replaceAll('-', '+')
          .replaceAll('_', '/');
    }

    final payload = utf8.decode(base64.decode(norm(parts[1])));
    final map = jsonDecode(payload);
    return map is Map<String, dynamic> ? map : null;
  } catch (_) {
    return null;
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_authflow_advanced/features/auth/domain/models/token_set.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';


/// Persists the user's token set and exposes a stream for changes.
abstract class TokenStore {
  /// Must be called before save/read/clear/watch.
  Future<void> init();

  Future<void> save(TokenSet tokens);
  Future<TokenSet?> read();
  Future<void> clear();

  /// Emits the latest TokenSet after each save/clear.
  /// After [init], the current value is pushed once (may be null).
  Stream<TokenSet?> watch();
}

/// Cross-platform implementation:
/// • Web: GetStorage (localStorage under the hood)
/// • Mobile/Desktop: FlutterSecureStorage (encrypted on device)
class TokenStoreImpl implements TokenStore {
  static const _boxName = 'auth_box';
  static const _key = 'auth.token_set.v1';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  GetStorage? _box; // only used on Web

  final StreamController<TokenSet?> _controller =
  StreamController<TokenSet?>.broadcast();

  bool _initialized = false;

  @override
  Future<void> init() async {
    if (kIsWeb) {
      await GetStorage.init(_boxName);
      _box = GetStorage(_boxName);
    }
    // Warm current value into the stream (works for both branches)
    _controller.add(await read());
    _initialized = true;
  }

  @override
  Future<void> save(TokenSet tokens) async {
    _assertInited();
    final raw = jsonEncode(tokens.toJson());

    if (kIsWeb) {
      // _box is guaranteed after init on web
      await _box!.write(_key, raw);
    } else {
      await _secure.write(key: _key, value: raw);
    }
    _controller.add(tokens);
  }

  @override
  Future<TokenSet?> read() async {
    _assertInited();
    String? raw;

    if (kIsWeb) {
      final v = _box!.read(_key);
      raw = v is String ? v : (v == null ? null : jsonEncode(v));
    } else {
      raw = await _secure.read(key: _key);
    }

    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return TokenSet.fromJson(map);
    } catch (_) {
      // treat as no tokens
      return null;
    }
  }

  @override
  Future<void> clear() async {
    _assertInited();
    if (kIsWeb) {
      await _box!.remove(_key);
    } else {
      await _secure.delete(key: _key);
    }
    _controller.add(null);
  }

  @override
  Stream<TokenSet?> watch() => _controller.stream;

  void _assertInited() {
    assert(_initialized, 'TokenStore.init() must be called before use.');
  }

  //to close the stream.
  void dispose() {
    _controller.close();
  }
}
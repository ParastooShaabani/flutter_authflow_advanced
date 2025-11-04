import 'dart:async';
import 'package:flutter_authflow_advanced/core/storage/token_store.dart';
import 'package:flutter_authflow_advanced/features/auth/domain/models/token_set.dart';

/// Lightweight in-memory TokenStore for unit tests.
class InMemoryTokenStore implements TokenStore {
  TokenSet? _value;
  final _controller = StreamController<TokenSet?>.broadcast();

  @override
  Future<void> init() async {
    // No-op for memory store; push current value once.
    _controller.add(_value);
  }

  @override
  Future<void> save(TokenSet tokens) async {
    _value = tokens;
    _controller.add(_value);
  }

  @override
  Future<TokenSet?> read() async => _value;

  @override
  Future<void> clear() async {
    _value = null;
    _controller.add(null);
  }

  @override
  Stream<TokenSet?> watch() => _controller.stream;

  /// Call in test tearDown() to avoid open stream warnings.
  void dispose() {
    _controller.close();
  }
}

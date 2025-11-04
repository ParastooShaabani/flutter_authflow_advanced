import 'package:flutter_authflow_advanced/core/network/dio_client.dart';
import 'package:flutter_authflow_advanced/features/auth/data/auth_repository.dart';
import 'package:flutter_authflow_advanced/features/auth/domain/models/token_set.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'helpers/in_memory_token_store.dart';
import 'mocks/mock_app_auth_service.dart';
import 'dart:convert';

/// A minimal in-memory adapter that never touches the network.
/// Returns 401 on first call, 200 OK on retry.
class _FakeAdapter implements HttpClientAdapter {
  int hits = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
      RequestOptions options,
      Stream<List<int>>? requestStream,
      Future<dynamic>? cancelFuture,
      ) async {
    hits += 1;

    // First call → 401 Unauthorized
    if (hits == 1) {
      final body = utf8.encode('{"error":"unauthorized"}');
      return ResponseBody.fromBytes(
        body,
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    // Second call (after refresh) → 200 OK
    final ok = utf8.encode('{"ok":true}');
    return ResponseBody.fromBytes(
      ok,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

/// Recorder utility to verify that requests were retried.
class _Recorder {
  int onRequestHits = 0;
}

void main() {
  late InMemoryTokenStore store;
  late MockAppAuthService appAuth;
  late AuthRepository repo;

  setUp(() async {
    store = InMemoryTokenStore();
    await store.init();
    appAuth = MockAppAuthService();
    repo = AuthRepository.mobile(appAuth: appAuth, store: store);
  });

  tearDown(() => store.dispose());

  test('401 triggers refresh and retried request succeeds (adapter stubbed)',
          () async {
        // Seed tokens
        await store.save(TokenSet(
          accessToken: 'access_old',
          refreshToken: 'refresh_old',
          expiresAt: DateTime.now().add(const Duration(minutes: 1)),
        ));

        // Mock refresh logic called by RefreshInterceptor
        when(() => appAuth.refresh()).thenAnswer((_) async {});
        when(() => appAuth.readAccess()).thenAnswer((_) async => 'access_new');
        when(() => appAuth.readRefresh()).thenAnswer((_) async => 'refresh_new');

        final dio = Dio();

        // Never hit network
        final fake = _FakeAdapter();
        dio.httpClientAdapter = fake;

        // Inject interceptors under test
        dio.interceptors
          ..clear()
          ..add(AuthInterceptor(repo))
          ..add(RefreshInterceptor(repo, dio));

        // Optional: track how many times onRequest runs
        final rec = _Recorder();
        dio.interceptors.add(
          InterceptorsWrapper(onRequest: (options, handler) {
            rec.onRequestHits += 1;
            handler.next(options);
          }),
        );

        // Act
        final res = await dio
            .get('https://anything/secret')
            .timeout(const Duration(seconds: 5));

        // Assert
        expect(res.statusCode, 200);
        expect(res.data, {'ok': true});

        // Verify refresh() invoked once
        verify(() => appAuth.refresh()).called(1);

        // Adapter and onRequest should each have 2 hits (original + retry)
        expect(fake.hits, 2);
        expect(rec.onRequestHits, 2);

        // Store should now have new tokens saved by repo.refresh()
        final t = await store.read();
        expect(t!.accessToken, 'access_new');
        expect(t.refreshToken, 'refresh_new');
          }, timeout: const Timeout(Duration(seconds: 10)));
}




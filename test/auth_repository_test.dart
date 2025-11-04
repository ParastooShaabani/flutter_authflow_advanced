import 'package:flutter_authflow_advanced/features/auth/data/auth_repository.dart';
import 'package:flutter_authflow_advanced/features/auth/domain/models/token_set.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'helpers/in_memory_token_store.dart';
import 'mocks/mock_app_auth_service.dart';

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

  tearDown(() {
    store.dispose();
  });

  group('AuthRepository (mobile/AppAuth)', () {
    test('beginAuth stores TokenSet and returns native flag', () async {
      // Arrange
      when(() => appAuth.login()).thenAnswer((_) async {});
      when(() => appAuth.readAccess()).thenAnswer((_) async => 'access_1');
      when(() => appAuth.readRefresh()).thenAnswer((_) async => 'refresh_1');

      // Act
      final flag = await repo.beginAuth();

      // Assert
      expect(flag, 'native_login_started');
      final t = await store.read();
      expect(t, isNotNull);
      expect(t!.accessToken, 'access_1');
      expect(t.refreshToken, 'refresh_1');
      expect(t.isExpired, isFalse);
      verify(() => appAuth.login()).called(1);
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('refresh updates TokenSet with new tokens', () async {
      // Arrange
      await store.save(TokenSet(
        accessToken: 'access_1',
        refreshToken: 'refresh_1',
        expiresAt: DateTime.now().add(const Duration(minutes: 1)),
      ));

      when(() => appAuth.refresh()).thenAnswer((_) async {});
      when(() => appAuth.readAccess()).thenAnswer((_) async => 'access_2');
      when(() => appAuth.readRefresh()).thenAnswer((_) async => 'refresh_2');

      // Act
      final t2 = await repo.refresh();

      // Assert
      expect(t2.accessToken, 'access_2');
      expect(t2.refreshToken, 'refresh_2');
      verify(() => appAuth.refresh()).called(1);
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('logout clears TokenStore and calls AppAuth.logout', () async {
      // Arrange
      await store.save(TokenSet(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      ));
      when(() => appAuth.logout()).thenAnswer((_) async {});

      // Act
      await repo.logout();

      // Assert
      expect(await store.read(), isNull);
      verify(() => appAuth.logout()).called(1);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });
}

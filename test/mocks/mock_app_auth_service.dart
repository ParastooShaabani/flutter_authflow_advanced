import 'package:flutter_authflow_advanced/core/auth/appauth_service.dart';
import 'package:mocktail/mocktail.dart';

/// Mock implementation of [AppAuthService] for unit tests.
/// Allows verifying calls like login(), refresh(), and logout().
class MockAppAuthService extends Mock implements AppAuthService {}


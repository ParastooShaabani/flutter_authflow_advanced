/// Defines all secure storage key names used for authentication.
/// Keeping them centralized prevents typos and eases maintenance.
class AuthKeys {
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const accessExpiresAt = 'access_expires_at';
  static const idToken = 'id_token';
}

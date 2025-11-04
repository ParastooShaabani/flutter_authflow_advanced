class AppEnv {
  static const auth0Domain = 'dev-r4rci7w33lsoky2i.au.auth0.com';  //'YOUR_TENANT.auth0.com';
  static const auth0ClientId = 'MayFZrSrxfm6ujuAbkKZjZ7YiLKmVGPK'; //'YOUR_CLIENT_ID';

  static const redirectUri = 'https://com.example.flutter_authflow_advanced';
  static const logoutRedirectUri = 'https://com.example.flutter_authflow';

  static String get discoveryUrl =>
      'https://$auth0Domain/.well-known/openid-configuration';
  static const scopes = ['openid', 'profile', 'email', 'offline_access'];
}
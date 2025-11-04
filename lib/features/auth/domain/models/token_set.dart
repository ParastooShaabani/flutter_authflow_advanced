class TokenSet {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  TokenSet({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory TokenSet.fromJson(Map<String, dynamic> json) => TokenSet(
    accessToken: json['access'] as String,
    refreshToken: json['refresh'] as String,
    expiresAt: DateTime.parse(json['exp'] as String),
  );

  Map<String, dynamic> toJson() => {
    'access': accessToken,
    'refresh': refreshToken,
    'exp': expiresAt.toIso8601String(),
  };
}
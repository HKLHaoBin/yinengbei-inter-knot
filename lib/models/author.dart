class AuthorModel {
  static const String _baseUrl = 'https://ik.tiwat.cn';

  String login;
  String avatar;
  late String name;
  String? email;
  String? userId;
  String? authorId;
  DateTime? createdAt;

  // Adjusted for custom backend
  String get url => ''; // No external profile URL yet

  AuthorModel({
    required this.login,
    required this.avatar,
    required String? name,
    this.email,
    this.userId,
    this.authorId,
    this.createdAt,
  }) : name = name ?? login;

  static String? extractAvatarUrl(dynamic avatarData) {
    if (avatarData is! Map) return null;

    final directUrl = avatarData['url'] as String?;
    if (directUrl != null && directUrl.isNotEmpty) {
      return directUrl;
    }

    final data = avatarData['data'];
    if (data is Map) {
      final nestedUrl = data['url'] as String?;
      if (nestedUrl != null && nestedUrl.isNotEmpty) {
        return nestedUrl;
      }
      final attributes = data['attributes'];
      if (attributes is Map) {
        final attrUrl = attributes['url'] as String?;
        if (attrUrl != null && attrUrl.isNotEmpty) {
          return attrUrl;
        }
      }
    }

    final attributes = avatarData['attributes'];
    if (attributes is Map) {
      final attrUrl = attributes['url'] as String?;
      if (attrUrl != null && attrUrl.isNotEmpty) {
        return attrUrl;
      }
    }

    return null;
  }

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    final authorData = json['author'];
    final authorMap = authorData is Map<String, dynamic> ? authorData : null;
    final authorDataMap = authorMap?['data'];
    final authorDataMapTyped =
        authorDataMap is Map<String, dynamic> ? authorDataMap : null;
    final authorDataAttributes = authorDataMapTyped?['attributes'];
    final authorAttributes = authorMap?['attributes'];

    final avatarData = json['avatar'] ??
        authorMap?['avatar'] ??
        authorDataMapTyped?['avatar'] ??
        (authorDataAttributes is Map ? authorDataAttributes['avatar'] : null) ??
        (authorAttributes is Map ? authorAttributes['avatar'] : null);
    String? avatarUrl = extractAvatarUrl(avatarData);

    if (avatarUrl != null && !avatarUrl.startsWith('http')) {
      avatarUrl = '$_baseUrl$avatarUrl';
    }

    final username = json['username'] as String?;
    final userId = json['id']?.toString();
    final authorId = authorDataMapTyped?['documentId']?.toString() ??
        authorDataMapTyped?['id']?.toString() ??
        authorMap?['documentId']?.toString() ??
        authorMap?['id']?.toString() ??
        (authorData is String || authorData is num
            ? authorData.toString()
            : null) ??
        json['authorId']?.toString();

    DateTime? createdAt;
    final createdStr = json['createdAt'] as String?;
    if (createdStr != null) {
      createdAt = DateTime.tryParse(createdStr);
    }

    return AuthorModel(
      login: json['name'] as String? ?? username ?? 'unknown',
      avatar: avatarUrl ?? '',
      name: json['name'] as String? ?? username,
      email: json['email'] as String?,
      userId: userId,
      authorId: authorId,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AuthorModel && other.login == login;

  @override
  int get hashCode => login.hashCode;
}

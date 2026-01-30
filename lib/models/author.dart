class AuthorModel {
  String login;
  String avatar;
  late String name;

  // Adjusted for custom backend
  String get url => ''; // No external profile URL yet

  AuthorModel({
    required this.login,
    required this.avatar,
    required String? name,
  }) : name = name ?? login;

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    // Strapi Media 字段可能包含 data 层，也可能通过 flatten plugin 只有 attributes
    // 假设结构是 avatar: { url: "..." }
    final avatarData = json['avatar'];
    String? avatarUrl;
    if (avatarData is Map) {
      avatarUrl = avatarData['url'] as String?;
    }
    
    // 补全完整 URL
    if (avatarUrl != null && !avatarUrl.startsWith('http')) {
      avatarUrl = 'https://ik.tiwat.cn$avatarUrl';
    }

    return AuthorModel(
      login: json['name'] as String? ?? json['username'] as String,
      avatar: avatarUrl ?? 'https://ik.tiwat.cn/uploads/default_avatar.png',
      name: json['name'] as String? ?? json['username'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AuthorModel && other.login == login;

  @override
  int get hashCode => login.hashCode;
}

class AuthorModel {
  String login;
  String avatar;
  late String name;
  int level; // Mocked or removed

  // Adjusted for custom backend
  String get url => ''; // No external profile URL yet

  AuthorModel({
    required this.login,
    required this.avatar,
    required this.level,
    required String? name,
  }) : name = name ?? login;

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      login: json['username'] as String,
      avatar: json['avatarUrl'] as String? ?? '',
      level: 0, // No repositories count in backend
      name: json['username'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AuthorModel && other.login == login;

  @override
  int get hashCode => login.hashCode;
}

class AppUser {
  final String id;
  final String name;

  const AppUser({required this.id, required this.name});

  static const AppUser user1 = AppUser(id: 'user1', name: 'User 1');
  static const AppUser user2 = AppUser(id: 'user2', name: 'User 2');

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  AppUser copyWith({String? name}) => AppUser(id: id, name: name ?? this.name);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      AppUser(id: json['id'] as String, name: json['name'] as String);
}

enum UserStatus {
  online(0),
  offline(1),
  busy(2);

  final int value;
  const UserStatus(this.value);

  static UserStatus fromValue(int value) {
    return UserStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserStatus.offline,
    );
  }
}

class User {
  final int id;
  final String username;
  final String nickname;
  final String? avatar;
  UserStatus status;

  User({
    required this.id,
    required this.username,
    this.nickname = '',
    this.avatar,
    this.status = UserStatus.offline,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final username = json['username'] ?? '';
    return User(
      id: json['id'] ?? 0,
      username: username,
      nickname: json['nickname'] ?? username,
      avatar: json['avatar'],
      status: UserStatus.fromValue(json['status'] ?? 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'avatar': avatar,
      'status': status.value,
    };
  }

  String get displayName => nickname.isNotEmpty ? nickname : username;

  bool get isOnline => status == UserStatus.online;

  User copyWith({
    int? id,
    String? username,
    String? nickname,
    String? avatar,
    UserStatus? status,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, name: $displayName, status: ${status.name}}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username;

  @override
  int get hashCode => id.hashCode ^ username.hashCode;
}

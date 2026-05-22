class Group {
  final int id;
  final String name;
  final String? avatar;
  final int ownerId;
  final int memberCount;
  final int createTime;
  final List<int>? memberIds;

  Group({
    required this.id,
    required this.name,
    this.avatar,
    required this.ownerId,
    this.memberCount = 0,
    int? createTime,
    this.memberIds,
  }) : createTime = createTime ?? DateTime.now().millisecondsSinceEpoch;

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      avatar: json['avatar'],
      ownerId: json['ownerId'] ?? 0,
      memberCount: json['memberCount'] ?? 0,
      createTime: json['createTime'],
      memberIds: json['memberIds'] != null
          ? List<int>.from(json['memberIds'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'ownerId': ownerId,
      'memberCount': memberCount,
      'createTime': createTime,
      'memberIds': memberIds,
    };
  }

  bool isOwner(int userId) => ownerId == userId;

  Group copyWith({
    int? id,
    String? name,
    String? avatar,
    int? ownerId,
    int? memberCount,
    int? createTime,
    List<int>? memberIds,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      ownerId: ownerId ?? this.ownerId,
      memberCount: memberCount ?? this.memberCount,
      createTime: createTime ?? this.createTime,
      memberIds: memberIds ?? this.memberIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Group &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          ownerId == other.ownerId;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ ownerId.hashCode;

  @override
  String toString() {
    return 'Group{id: $id, name: $name, members: $memberCount}';
  }
}

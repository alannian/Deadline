class MemoFolder {
  final String id;
  final String name;
  final String? parentId; // null = 根级文件夹
  final int sortOrder;
  final DateTime createdAt;
  final bool isStarred;

  MemoFolder({
    required this.id,
    required this.name,
    this.parentId,
    this.sortOrder = 0,
    required this.createdAt,
    this.isStarred = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'sortOrder': sortOrder,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isStarred': isStarred ? 1 : 0,
    };
  }

  factory MemoFolder.fromMap(Map<String, dynamic> map) {
    return MemoFolder(
      id: map['id'],
      name: map['name'],
      parentId: map['parentId'],
      sortOrder: map['sortOrder'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isStarred: (map['isStarred'] ?? 0) == 1,
    );
  }

  MemoFolder copyWith({String? name, String? parentId, int? sortOrder, bool? isStarred}) {
    return MemoFolder(
      id: id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      isStarred: isStarred ?? this.isStarred,
    );
  }
}

class Memo {
  final String id;
  final String? folderId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isStarred;

  Memo({
    required this.id,
    this.folderId,
    required this.title,
    this.content = '',
    required this.createdAt,
    required this.updatedAt,
    this.isStarred = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folderId': folderId,
      'title': title,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isStarred': isStarred ? 1 : 0,
    };
  }

  factory Memo.fromMap(Map<String, dynamic> map) {
    return Memo(
      id: map['id'],
      folderId: map['folderId'],
      title: map['title'],
      content: map['content'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      isStarred: (map['isStarred'] ?? 0) == 1,
    );
  }

  Memo copyWith({
    String? folderId,
    String? title,
    String? content,
    DateTime? updatedAt,
    bool? isStarred,
  }) {
    return Memo(
      id: id,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isStarred: isStarred ?? this.isStarred,
    );
  }
}

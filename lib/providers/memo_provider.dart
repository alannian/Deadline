import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/memo.dart';
import '../services/database_service.dart';

class MemoProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  /// 当前目录下的子文件夹
  List<MemoFolder> _currentFolders = [];
  List<MemoFolder> get currentFolders => _currentFolders;

  /// 普通文件夹（未标星）
  List<MemoFolder> get normalFolders =>
      _currentFolders.where((f) => !f.isStarred).toList();

  /// 标星文件夹
  List<MemoFolder> get starredFolders =>
      _currentFolders.where((f) => f.isStarred).toList();

  /// 当前目录下的备忘录
  List<Memo> _currentMemos = [];
  List<Memo> get currentMemos => _currentMemos;

  /// 普通备忘录（未标星）
  List<Memo> get normalMemos =>
      _currentMemos.where((m) => !m.isStarred).toList();

  /// 标星备忘录
  List<Memo> get starredMemos =>
      _currentMemos.where((m) => m.isStarred).toList();

  /// 文件夹路径栈（用于面包屑导航）
  final List<MemoFolder> _folderPath = [];
  List<MemoFolder> get folderPath => List.unmodifiable(_folderPath);

  /// 当前所在文件夹ID（null = 根目录）
  String? get currentFolderId =>
      _folderPath.isEmpty ? null : _folderPath.last.id;

  bool get isRoot => _folderPath.isEmpty;

  /// 加载当前文件夹的内容
  Future<void> loadCurrentFolder() async {
    _currentFolders = await _db.getFoldersByParent(currentFolderId);
    _currentMemos = await _db.getMemosByFolder(currentFolderId);
    notifyListeners();
  }

  /// 兼容旧调用
  Future<void> loadFolders() async {
    await loadCurrentFolder();
  }

  /// 兼容旧调用
  Future<void> showAllMemos() async {
    await loadCurrentFolder();
  }

  /// 进入子文件夹
  Future<void> enterFolder(MemoFolder folder) async {
    _folderPath.add(folder);
    await loadCurrentFolder();
  }

  /// 返回上一级
  Future<void> goBack() async {
    if (_folderPath.isNotEmpty) {
      _folderPath.removeLast();
      await loadCurrentFolder();
    }
  }

  /// 返回根目录
  Future<void> goRoot() async {
    _folderPath.clear();
    await loadCurrentFolder();
  }

  /// 导航到面包屑中的某一级
  Future<void> navigateTo(int pathIndex) async {
    // pathIndex = -1 表示根目录
    if (pathIndex < 0) {
      _folderPath.clear();
    } else {
      while (_folderPath.length > pathIndex + 1) {
        _folderPath.removeLast();
      }
    }
    await loadCurrentFolder();
  }

  /// 创建文件夹（在当前目录下）
  Future<void> createFolder(String name) async {
    final folder = MemoFolder(
      id: _uuid.v4(),
      name: name,
      parentId: currentFolderId,
      sortOrder: _currentFolders.length,
      createdAt: DateTime.now(),
    );
    await _db.insertMemoFolder(folder);
    await loadCurrentFolder();
  }

  /// 重命名文件夹
  Future<void> renameFolder(MemoFolder folder, String newName) async {
    await _db.updateMemoFolder(folder.copyWith(name: newName));
    await loadCurrentFolder();
  }

  /// 删除文件夹（级联删除所有子文件夹和备忘录）
  Future<void> deleteFolder(String id) async {
    await _db.deleteMemoFolderCascade(id);
    await loadCurrentFolder();
  }

  /// 移动文件夹到另一个父文件夹
  Future<void> moveFolder(MemoFolder folder, String? targetParentId) async {
    final updated = MemoFolder(
      id: folder.id,
      name: folder.name,
      parentId: targetParentId,
      sortOrder: folder.sortOrder,
      createdAt: folder.createdAt,
    );
    await _db.updateMemoFolder(updated);
    await loadCurrentFolder();
  }

  /// 移动备忘录到另一个文件夹
  Future<void> moveMemo(Memo memo, String? targetFolderId) async {
    final updated = Memo(
      id: memo.id,
      folderId: targetFolderId,
      title: memo.title,
      content: memo.content,
      createdAt: memo.createdAt,
      updatedAt: memo.updatedAt,
    );
    await _db.updateMemo(updated);
    await loadCurrentFolder();
  }

  /// 获取所有文件夹（用于移动对话框）
  Future<List<MemoFolder>> getAllFolders() async {
    return await _db.getAllMemoFolders();
  }

  /// 创建备忘录（在当前文件夹下）
  Future<Memo> createMemo({
    String? folderId,
    String title = '新备忘录',
  }) async {
    final now = DateTime.now();
    final memo = Memo(
      id: _uuid.v4(),
      folderId: folderId ?? currentFolderId,
      title: title,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insertMemo(memo);
    await loadCurrentFolder();
    return memo;
  }

  /// 更新备忘录
  Future<void> updateMemo(Memo memo) async {
    final updated = memo.copyWith(updatedAt: DateTime.now());
    await _db.updateMemo(updated);
    await loadCurrentFolder();
  }

  /// 删除备忘录
  Future<void> deleteMemo(String id) async {
    await _db.deleteMemo(id);
    await loadCurrentFolder();
  }

  /// 切换备忘录标星状态
  Future<void> toggleStar(Memo memo) async {
    final updated = memo.copyWith(isStarred: !memo.isStarred);
    await _db.updateMemo(updated);
    await loadCurrentFolder();
  }

  /// 切换文件夹标星状态
  Future<void> toggleFolderStar(MemoFolder folder) async {
    final updated = folder.copyWith(isStarred: !folder.isStarred);
    await _db.updateMemoFolder(updated);
    await loadCurrentFolder();
  }
}

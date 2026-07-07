import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/memo_provider.dart';
import '../models/memo.dart';
import '../l10n/app_strings.dart';
import 'memo_edit_page.dart';

class MemoPage extends StatefulWidget {
  const MemoPage({super.key});

  @override
  State<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage> {
  @override
  void initState() {
    super.initState();
    final p = context.read<MemoProvider>();
    Future.microtask(() {
      p.loadCurrentFolder();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final memoProvider = context.watch<MemoProvider>();

    return PopScope(
      canPop: memoProvider.isRoot,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          memoProvider.goBack();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(s.memoTitle),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateMenu(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: Consumer<MemoProvider>(
        builder: (context, provider, child) {
          final normalFolders = provider.normalFolders;
          final starredFolders = provider.starredFolders;
          final normalMemos = provider.normalMemos;
          final starredMemos = provider.starredMemos;
          final isEmpty = normalFolders.isEmpty &&
              starredFolders.isEmpty &&
              normalMemos.isEmpty &&
              starredMemos.isEmpty;

          return Column(
            children: [
              // 面包屑导航
              _buildBreadcrumb(context, provider, isDark),

              // 内容区
              Expanded(
                child: isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open_rounded,
                                size: 56,
                                color: isDark
                                    ? Colors.grey[700]
                                    : Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(s.emptyFolder,
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[600]
                                        : Colors.grey[500])),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                        children: [
                          // 上部：普通文件夹 + 普通文件
                          if (normalFolders.isNotEmpty ||
                              normalMemos.isNotEmpty)
                            _buildGrid(context, normalFolders, normalMemos,
                                isDark, provider),
                          // 下部：标星文件夹 + 标星文件
                          if (starredFolders.isNotEmpty ||
                              starredMemos.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.star_rounded,
                                      size: 20,
                                      color: isDark
                                          ? Colors.amber[600]
                                          : Colors.amber[700]),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Divider(
                                      color: isDark
                                          ? Colors.grey[700]
                                          : Colors.grey[300],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildGrid(context, starredFolders, starredMemos,
                                isDark, provider),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    ),
    );
  }

  // ── 网格布局 ──
  Widget _buildGrid(BuildContext context, List<MemoFolder> folders,
      List<Memo> memos, bool isDark, MemoProvider provider) {
    final count = folders.length + memos.length;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        if (index < folders.length) {
          return _buildFolderCard(context, folders[index], isDark, provider);
        } else {
          return _buildMemoCard(context, memos[index - folders.length], isDark);
        }
      },
    );
  }

  // ── 面包屑导航 ──
  Widget _buildBreadcrumb(
      BuildContext context, MemoProvider provider, bool isDark) {
    final s = S.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: provider.isRoot ? null : () => provider.navigateTo(-1),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  s.allFiles,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        provider.isRoot ? FontWeight.w600 : FontWeight.normal,
                    color: provider.isRoot
                        ? (isDark ? Colors.white : Colors.black87)
                        : const Color(0xFF42A5F5),
                  ),
                ),
              ),
            ),
            for (var i = 0; i < provider.folderPath.length; i++) ...[
              Icon(Icons.chevron_right,
                  size: 16,
                  color: isDark ? Colors.grey[600] : Colors.grey[400]),
              InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: i == provider.folderPath.length - 1
                    ? null
                    : () => provider.navigateTo(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  child: Text(
                    provider.folderPath[i].name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: i == provider.folderPath.length - 1
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: i == provider.folderPath.length - 1
                          ? (isDark ? Colors.white : Colors.black87)
                          : const Color(0xFF42A5F5),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── 文件夹方块卡片 ──
  Widget _buildFolderCard(BuildContext context, MemoFolder folder,
      bool isDark, MemoProvider provider) {
    return GestureDetector(
      onTap: () => provider.enterFolder(folder),
      onLongPress: () => _showFolderOptions(context, folder),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.folder_rounded,
                  size: 44,
                  color: isDark
                      ? const Color(0xFFFFCA28)
                      : const Color(0xFFFFA000),
                ),
                if (folder.isStarred)
                  const Positioned(
                    right: -4,
                    top: -4,
                    child: Icon(Icons.star_rounded,
                        size: 16, color: Colors.amber),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                folder.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 备忘录方块卡片 ──
  Widget _buildMemoCard(BuildContext context, Memo memo, bool isDark) {
    final dateStr =
        '${memo.updatedAt.month}/${memo.updatedAt.day} ${memo.updatedAt.hour}:${memo.updatedAt.minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: () => _openMemo(context, memo),
      onLongPress: () => _showMemoOptions(context, memo),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_rounded,
              size: 36,
              color: isDark
                  ? const Color(0xFF42A5F5)
                  : const Color(0xFF1976D2),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                memo.title.isEmpty ? S.of(context).untitled : memo.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: memo.title.isEmpty
                      ? (isDark ? Colors.grey[500] : Colors.grey[400])
                      : null,
                  fontStyle: memo.title.isEmpty ? FontStyle.italic : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 操作方法 ──

  void _showCreateMenu(BuildContext context) {
    final s = S.read(context);
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(s.newItem, textAlign: TextAlign.center),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _showCreateFolderDialog(context);
            },
            child: Row(
              children: [
                const Icon(Icons.create_new_folder_rounded),
                const SizedBox(width: 12),
                Text(s.newFolder),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _createMemo(context);
            },
            child: Row(
              children: [
                const Icon(Icons.note_add_rounded),
                const SizedBox(width: 12),
                Text(s.newMemo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _createMemo(BuildContext context) async {
    final provider = context.read<MemoProvider>();
    final memo = await provider.createMemo(title: '');
    if (context.mounted) {
      _openMemo(context, memo);
    }
  }

  void _openMemo(BuildContext context, Memo memo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MemoEditPage(memo: memo)),
    );
    if (context.mounted) {
      context.read<MemoProvider>().loadCurrentFolder();
    }
  }

  void _showCreateFolderDialog(BuildContext context) {
    final s = S.read(context);
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.newFolder),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: s.folderNameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                context.read<MemoProvider>().createFolder(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text(s.create),
          ),
        ],
      ),
    );
  }

  void _showFolderOptions(BuildContext context, MemoFolder folder) {
    final s = S.read(context);
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(folder.name, textAlign: TextAlign.center),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MemoProvider>().toggleFolderStar(folder);
            },
            child: Row(
              children: [
                Icon(folder.isStarred
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded),
                const SizedBox(width: 12),
                Text(folder.isStarred
                    ? (s.isCn ? '取消标星' : 'Unstar')
                    : (s.isCn ? '标星' : 'Star')),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _showMoveDialog(context, folder: folder);
            },
            child: Row(
              children: [
                const Icon(Icons.drive_file_move_outlined),
                const SizedBox(width: 12),
                Text(s.moveTo),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _showRenameFolderDialog(context, folder);
            },
            child: Row(
              children: [
                const Icon(Icons.edit_outlined),
                const SizedBox(width: 12),
                Text(s.rename),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDeleteFolder(context, folder);
            },
            child: Row(
              children: [
                const Icon(Icons.delete_outline, color: Colors.red),
                const SizedBox(width: 12),
                Text(s.delete, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFolder(BuildContext context, MemoFolder folder) {
    final s = S.read(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.confirmDelete),
        content: Text(s.deleteFolderConfirm(folder.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<MemoProvider>().deleteFolder(folder.id);
              Navigator.pop(ctx);
            },
            child: Text(s.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRenameFolderDialog(BuildContext context, MemoFolder folder) {
    final ctrl = TextEditingController(text: folder.name);
    final s = S.read(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.renameFolder),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                context
                    .read<MemoProvider>()
                    .renameFolder(folder, ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text(s.ok),
          ),
        ],
      ),
    );
  }

  void _showMemoOptions(BuildContext context, Memo memo) {
    final s = S.read(context);
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(memo.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MemoProvider>().toggleStar(memo);
            },
            child: Row(
              children: [
                Icon(memo.isStarred
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded),
                const SizedBox(width: 12),
                Text(memo.isStarred
                    ? (s.isCn ? '取消标星' : 'Unstar')
                    : (s.isCn ? '标星' : 'Star')),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _showMoveDialog(context, memo: memo);
            },
            child: Row(
              children: [
                const Icon(Icons.drive_file_move_outlined),
                const SizedBox(width: 12),
                Text(s.moveTo),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MemoProvider>().deleteMemo(memo.id);
            },
            child: Row(
              children: [
                const Icon(Icons.delete_outline, color: Colors.red),
                const SizedBox(width: 12),
                Text(s.delete, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 显示移动对话框 — 树形文件夹选择器
  void _showMoveDialog(BuildContext context, {MemoFolder? folder, Memo? memo}) async {
    final provider = context.read<MemoProvider>();
    final s = S.read(context);
    final allFolders = await provider.getAllFolders();

    // 构建文件夹树：parentId → children
    final Map<String?, List<MemoFolder>> tree = {};
    for (final f in allFolders) {
      tree.putIfAbsent(f.parentId, () => []).add(f);
    }

    // 不能移动到自身或自身的子文件夹内
    Set<String> excludeIds = {};
    if (folder != null) {
      excludeIds.add(folder.id);
      void collectChildren(String parentId) {
        final children = tree[parentId] ?? [];
        for (final child in children) {
          excludeIds.add(child.id);
          collectChildren(child.id);
        }
      }
      collectChildren(folder.id);
    }

    String? selectedTargetId; // null = 根目录
    final itemName = folder?.name ?? memo?.title ?? '';

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            // 递归构建文件夹列表
            List<Widget> buildFolderList(String? parentId, int depth) {
              final children = tree[parentId] ?? [];
              final List<Widget> widgets = [];
              for (final f in children) {
                if (excludeIds.contains(f.id)) continue;
                final isSelected = selectedTargetId == f.id;
                widgets.add(
                  InkWell(
                    onTap: () => setDialogState(() => selectedTargetId = f.id),
                    child: Container(
                      padding: EdgeInsets.only(
                          left: 16.0 + depth * 24.0, top: 12, bottom: 12, right: 16),
                      color: isSelected
                          ? const Color(0xFF42A5F5).withAlpha(30)
                          : null,
                      child: Row(
                        children: [
                          Icon(Icons.folder_rounded,
                              size: 20,
                              color: isSelected
                                  ? const Color(0xFF42A5F5)
                                  : const Color(0xFFFFA000)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(f.name,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? const Color(0xFF42A5F5)
                                      : null,
                                )),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_rounded,
                                color: Color(0xFF42A5F5), size: 20),
                        ],
                      ),
                    ),
                  ),
                );
                widgets.addAll(buildFolderList(f.id, depth + 1));
              }
              return widgets;
            }

            final isRootSelected = selectedTargetId == null;

            return AlertDialog(
              title: Text('${s.moveToFolder} · $itemName',
                  style: const TextStyle(fontSize: 16)),
              contentPadding: const EdgeInsets.only(top: 12),
              content: SizedBox(
                width: double.maxFinite,
                height: 320,
                child: ListView(
                  children: [
                    // 根目录选项
                    InkWell(
                      onTap: () =>
                          setDialogState(() => selectedTargetId = null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        color: isRootSelected
                            ? const Color(0xFF42A5F5).withAlpha(30)
                            : null,
                        child: Row(
                          children: [
                            Icon(Icons.home_rounded,
                                size: 20,
                                color: isRootSelected
                                    ? const Color(0xFF42A5F5)
                                    : Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(s.rootFolder,
                                  style: TextStyle(
                                    fontWeight: isRootSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isRootSelected
                                        ? const Color(0xFF42A5F5)
                                        : null,
                                  )),
                            ),
                            if (isRootSelected)
                              const Icon(Icons.check_rounded,
                                  color: Color(0xFF42A5F5), size: 20),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ...buildFolderList(null, 0),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(s.cancel),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (folder != null) {
                      await provider.moveFolder(folder, selectedTargetId);
                    } else if (memo != null) {
                      await provider.moveMemo(memo, selectedTargetId);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.moved(itemName)),
                            duration: const Duration(seconds: 1)),
                      );
                    }
                  },
                  child: Text(s.ok),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

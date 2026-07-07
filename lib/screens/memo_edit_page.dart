import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/memo_provider.dart';
import '../models/memo.dart';
import '../l10n/app_strings.dart';

/// 行类型
enum LineType { text, checkbox, heading, divider }

/// 编辑行数据（文本内容由 TextEditingController 管理）
class _EditorLine {
  static int _nextId = 0;
  final int id;
  LineType type;
  bool checked;
  _EditorLine({this.type = LineType.text, this.checked = false})
      : id = _nextId++;
}

class MemoEditPage extends StatefulWidget {
  final Memo memo;
  const MemoEditPage({super.key, required this.memo});
  @override
  State<MemoEditPage> createState() => _MemoEditPageState();
}

class _MemoEditPageState extends State<MemoEditPage> {
  late TextEditingController _titleCtrl;
  bool _hasChanged = false;

  final List<_EditorLine> _lines = [];
  final List<TextEditingController> _ctrls = [];
  final List<FocusNode> _focuses = [];
  int _focusedIdx = -1;

  // ── undo / redo ──
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  bool _isUndoRedo = false;

  // ── 生命周期 ──

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.memo.title);
    _titleCtrl.addListener(_markChanged);
    _parseContent(widget.memo.content);
    // 保存初始快照用于撤销
    _undoStack.add(_serialize());
  }

  @override
  void dispose() {
    _save();
    _titleCtrl.dispose();
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final f in _focuses) {
      f.dispose();
    }
    super.dispose();
  }

  // ── 内容解析 / 序列化 ──

  void _parseContent(String content) {
    if (content.isEmpty) {
      _appendLine(LineType.text);
      return;
    }
    for (final raw in content.split('\n')) {
      if (raw.startsWith('☑ ')) {
        _appendLine(LineType.checkbox, text: raw.substring(2), checked: true);
      } else if (raw.startsWith('☐ ')) {
        _appendLine(LineType.checkbox, text: raw.substring(2));
      } else if (raw.startsWith('## ')) {
        _appendLine(LineType.heading, text: raw.substring(3));
      } else if (_isDivider(raw)) {
        _appendLine(LineType.divider);
      } else {
        _appendLine(LineType.text, text: raw);
      }
    }
  }

  bool _isDivider(String s) {
    final t = s.trim();
    if (t.length < 3) return false;
    return t.runes.every((r) => r == 0x2500 || r == 0x2D || r == 0x2014);
  }

  String _serialize() {
    final buf = StringBuffer();
    for (int i = 0; i < _lines.length; i++) {
      if (i > 0) buf.write('\n');
      final line = _lines[i];
      final text = _ctrls[i].text;
      switch (line.type) {
        case LineType.checkbox:
          buf.write('${line.checked ? '☑' : '☐'} $text');
        case LineType.heading:
          buf.write('## $text');
        case LineType.divider:
          buf.write('───────────');
        case LineType.text:
          buf.write(text);
      }
    }
    return buf.toString();
  }

  // ── 行管理 ──

  void _appendLine(LineType type,
      {String text = '', bool checked = false, int? at}) {
    final line = _EditorLine(type: type, checked: checked);
    final ctrl = TextEditingController(text: text);
    ctrl.addListener(_markChanged);
    final focus = _makeFocusNode();

    if (at != null) {
      _lines.insert(at, line);
      _ctrls.insert(at, ctrl);
      _focuses.insert(at, focus);
    } else {
      _lines.add(line);
      _ctrls.add(ctrl);
      _focuses.add(focus);
    }
  }

  FocusNode _makeFocusNode() {
    final focus = FocusNode();
    // 桌面端：拦截 Backspace 在行首时合并行
    focus.onKeyEvent = (node, event) {
      final idx = _focuses.indexOf(node);
      if (idx <= 0) return KeyEventResult.ignored;
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.backspace) {
        final c = _ctrls[idx];
        if (c.selection.isCollapsed && c.selection.baseOffset == 0) {
          _mergeWithPrevious(idx);
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
    focus.addListener(() {
      if (focus.hasFocus) {
        final idx = _focuses.indexOf(focus);
        if (idx != -1) setState(() => _focusedIdx = idx);
      }
    });
    return focus;
  }

  void _removeLine(int index) {
    if (_lines.length <= 1) return;
    _ctrls[index].dispose();
    _focuses[index].dispose();
    _lines.removeAt(index);
    _ctrls.removeAt(index);
    _focuses.removeAt(index);
    if (_focusedIdx >= _lines.length) _focusedIdx = _lines.length - 1;
  }

  void _markChanged() {
    if (_isUndoRedo) return;
    _pushUndo();
    if (!_hasChanged) setState(() => _hasChanged = true);
  }

  void _pushUndo() {
    _undoStack.add(_serialize());
    _redoStack.clear();
    // 限制栈深度
    if (_undoStack.length > 50) _undoStack.removeAt(0);
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_serialize());
    final snap = _undoStack.removeLast();
    _restoreSnapshot(snap);
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_serialize());
    final snap = _redoStack.removeLast();
    _restoreSnapshot(snap);
  }

  void _restoreSnapshot(String content) {
    _isUndoRedo = true;
    // 清空当前行
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final f in _focuses) {
      f.dispose();
    }
    _lines.clear();
    _ctrls.clear();
    _focuses.clear();
    _focusedIdx = -1;
    // 重新解析
    _parseContent(content);
    setState(() => _hasChanged = true);
    _isUndoRedo = false;
  }

  void _save() {
    if (!_hasChanged) return;
    final updated = widget.memo.copyWith(
      title: _titleCtrl.text.trim(),
      content: _serialize(),
    );
    context.read<MemoProvider>().updateMemo(updated);
  }

  // ── 行操作 ──

  // 检测编号前缀 "1. ", "12. " 等
  static final _numRe = RegExp(r'^(\d+)\.\s');

  /// 回车：拆行
  void _handleEnter(int index, String before, List<String> after) {
    final line = _lines[index];
    // 空 checkbox/heading 按回车 → 退回普通文本行
    if ((line.type == LineType.checkbox || line.type == LineType.heading) &&
        before.isEmpty &&
        after.every((s) => s.isEmpty)) {
      setState(() => line.type = LineType.text);
      return;
    }

    // 自动编号：当前行以 "N. " 开头时，新行自动 N+1
    final numMatch = _numRe.firstMatch(_ctrls[index].text);
    if (numMatch != null && line.type == LineType.text) {
      final curNum = int.parse(numMatch.group(1)!);
      final prefix = '${curNum + 1}. ';
      // 空编号行回车 → 取消编号
      final contentAfterNum = before.substring(numMatch.end);
      if (contentAfterNum.isEmpty && after.every((s) => s.isEmpty)) {
        _ctrls[index].text = '';
        setState(() {});
        return;
      }
      setState(() {
        for (int i = 0; i < after.length; i++) {
          _appendLine(LineType.text,
              text: i == 0 ? '$prefix${after[i]}' : after[i],
              at: index + 1 + i);
        }
      });
      _focusLine(index + 1, offset: prefix.length);
      _markChanged();
      return;
    }

    final newType =
        line.type == LineType.checkbox ? LineType.checkbox : LineType.text;
    setState(() {
      for (int i = 0; i < after.length; i++) {
        _appendLine(newType, text: after[i], at: index + 1 + i);
      }
    });
    _focusLine(index + 1, offset: 0);
    _markChanged();
  }

  /// 退格在行首：与上一行合并
  void _mergeWithPrevious(int index) {
    if (index <= 0) return;
    if (_lines[index - 1].type == LineType.divider) {
      setState(() => _removeLine(index - 1));
      _markChanged();
      return;
    }
    final text = _ctrls[index].text;
    final prev = _ctrls[index - 1];
    final mergePos = prev.text.length;
    prev.text = prev.text + text;
    setState(() => _removeLine(index));
    _focusLine(index - 1, offset: mergePos);
    _markChanged();
  }

  void _focusLine(int idx, {int? offset}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (idx >= 0 && idx < _focuses.length) {
        _focuses[idx].requestFocus();
        if (offset != null) {
          _ctrls[idx].selection = TextSelection.collapsed(offset: offset);
        }
      }
    });
  }

  // ── 工具栏 ──

  void _addCheckbox() {
    final idx = (_focusedIdx >= 0 ? _focusedIdx : _lines.length - 1) + 1;
    setState(() => _appendLine(LineType.checkbox, at: idx));
    _focusLine(idx);
    _markChanged();
  }

  void _addHeading() {
    final idx = (_focusedIdx >= 0 ? _focusedIdx : _lines.length - 1) + 1;
    setState(() => _appendLine(LineType.heading, at: idx));
    _focusLine(idx);
    _markChanged();
  }

  void _addDivider() {
    final idx = (_focusedIdx >= 0 ? _focusedIdx : _lines.length - 1) + 1;
    setState(() => _appendLine(LineType.divider, at: idx));
    _markChanged();
  }

  void _addNumbering() {
    final idx = (_focusedIdx >= 0 ? _focusedIdx : _lines.length - 1) + 1;
    setState(() => _appendLine(LineType.text, text: '1. ', at: idx));
    _focusLine(idx, offset: 3);
    _markChanged();
  }

  void _selectAllAndCopy() {
    final all = '${_titleCtrl.text}\n${_serialize()}';
    Clipboard.setData(ClipboardData(text: all));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.read(context).isCn ? '已复制全部内容' : 'All content copied'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ── 构建 UI ──

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _save();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.editMemo),
          actions: [
            IconButton(
              icon: const Icon(Icons.select_all_rounded),
              onPressed: _selectAllAndCopy,
            ),
            IconButton(
              icon: const Icon(Icons.undo_rounded),
              onPressed: _undoStack.isEmpty ? null : _undo,
            ),
            IconButton(
              icon: const Icon(Icons.redo_rounded),
              onPressed: _redoStack.isEmpty ? null : _redo,
            ),
            if (_hasChanged)
              IconButton(
                icon: const Icon(Icons.save_rounded),
                onPressed: () {
                  _save();
                  setState(() => _hasChanged = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(s.save),
                        duration: const Duration(seconds: 1)),
                  );
                },
              ),
          ],
        ),
        body: Column(
          children: [
            // ── 标题 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: _titleCtrl,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: '标题',
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(),
            ),
            // ── 行编辑区 ──
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  // 点击空白处 → 聚焦最后一行
                  if (_lines.isNotEmpty) {
                    _focusLine(_lines.length - 1);
                  }
                },
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _lines.length,
                  itemBuilder: (_, i) => _buildLine(i),
                ),
              ),
            ),
            // ── 工具栏 ──
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    width: 0.5,
                  ),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom > 0
                    ? 0
                    : MediaQuery.of(context).padding.bottom,
              ),
              child: Row(
                children: [
                  _toolBtn(Icons.check_box_outlined, _addCheckbox),
                  _toolBtn(Icons.title_rounded, _addHeading),
                  _toolBtn(Icons.format_list_numbered_rounded, _addNumbering),
                  _toolBtn(Icons.horizontal_rule_rounded, _addDivider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolBtn(IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }

  // ── 行渲染 ──

  Widget _buildLine(int i) {
    final line = _lines[i];
    switch (line.type) {
      case LineType.checkbox:
        return _checkboxLine(i, line);
      case LineType.heading:
        return _headingLine(i);
      case LineType.divider:
        return _dividerLine(i);
      case LineType.text:
        return _textLine(i);
    }
  }

  /// ☐/☑ 可点击勾选框 + 行内编辑
  Widget _checkboxLine(int i, _EditorLine line) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      key: ValueKey(line.id),
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() => line.checked = !line.checked);
              _markChanged();
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                line.checked
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 22,
                color: line.checked ? primary : Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _field(i,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  decoration:
                      line.checked ? TextDecoration.lineThrough : null,
                  color: line.checked ? Colors.grey : null,
                )),
          ),
        ],
      ),
    );
  }

  /// ## 标题行
  Widget _headingLine(int i) {
    return Padding(
      key: ValueKey(_lines[i].id),
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: _field(i,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, height: 1.5)),
    );
  }

  /// ── 分割线（长按删除）
  Widget _dividerLine(int i) {
    return GestureDetector(
      key: ValueKey(_lines[i].id),
      onLongPress: () {
        if (_lines.length > 1) {
          setState(() => _removeLine(i));
          _markChanged();
        }
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(thickness: 1),
      ),
    );
  }

  /// 普通文本行
  Widget _textLine(int i) {
    return Padding(
      key: ValueKey(_lines[i].id),
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: _field(i,
          style: const TextStyle(fontSize: 16, height: 1.6),
          hint: i == 0 && _lines.length == 1
              ? S.of(context).startWriting
              : null),
    );
  }

  /// 单行文本输入（拦截回车进行拆行）
  Widget _field(int i, {TextStyle? style, String? hint}) {
    return TextField(
      controller: _ctrls[i],
      focusNode: _focuses[i],
      maxLines: null,
      style: style,
      decoration: InputDecoration(
        border: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
        isDense: true,
        hintText: hint,
      ),
      inputFormatters: [
        _EnterSplitter(
            onEnter: (before, after) => _handleEnter(i, before, after)),
      ],
    );
  }
}

/// 拦截换行符，将一次回车转换为拆行回调
class _EnterSplitter extends TextInputFormatter {
  final void Function(String before, List<String> after) onEnter;
  _EnterSplitter({required this.onEnter});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.contains('\n')) {
      final parts = newValue.text.split('\n');
      final before = parts.first;
      final after = parts.sublist(1);
      WidgetsBinding.instance
          .addPostFrameCallback((_) => onEnter(before, after));
      return TextEditingValue(
        text: before,
        selection: TextSelection.collapsed(offset: before.length),
      );
    }
    return newValue;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/task_issue.dart';
import '../providers/task_issue_provider.dart';

enum _IssueLineType { text, checkbox, heading, divider }

class _IssueEditorLine {
  static int _nextId = 0;

  _IssueEditorLine({this.type = _IssueLineType.text, this.checked = false})
    : id = _nextId++;

  final int id;
  _IssueLineType type;
  bool checked;
}

class TaskIssueEditPage extends StatefulWidget {
  const TaskIssueEditPage({super.key, this.issue});

  final TaskIssue? issue;

  @override
  State<TaskIssueEditPage> createState() => _TaskIssueEditPageState();
}

class _TaskIssueEditPageState extends State<TaskIssueEditPage> {
  late final TextEditingController _titleController;
  final List<_IssueEditorLine> _lines = [];
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];

  int _focusedIndex = -1;
  bool _hasChanged = false;
  bool _restoring = false;
  bool _saving = false;
  String _lastSnapshot = '';
  TaskIssue? _savedIssue;

  static final _numberPrefix = RegExp(r'^(\d+)\.\s');

  @override
  void initState() {
    super.initState();
    _savedIssue = widget.issue;
    _titleController = TextEditingController(text: widget.issue?.title ?? '');
    _titleController.addListener(_markTitleChanged);
    _parseContent(widget.issue?.note ?? '');
    _lastSnapshot = _serialize();
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _parseContent(String content) {
    if (content.isEmpty) {
      _appendLine(_IssueLineType.text);
      return;
    }

    for (final raw in content.split('\n')) {
      if (raw.startsWith('☑ ')) {
        _appendLine(
          _IssueLineType.checkbox,
          text: raw.substring(2),
          checked: true,
        );
      } else if (raw.startsWith('☐ ')) {
        _appendLine(_IssueLineType.checkbox, text: raw.substring(2));
      } else if (raw.startsWith('## ')) {
        _appendLine(_IssueLineType.heading, text: raw.substring(3));
      } else if (_isDivider(raw)) {
        _appendLine(_IssueLineType.divider);
      } else {
        _appendLine(_IssueLineType.text, text: raw);
      }
    }
  }

  bool _isDivider(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 3) return false;
    return trimmed.runes.every(
      (rune) => rune == 0x2500 || rune == 0x2D || rune == 0x2014,
    );
  }

  String _serialize() {
    final buffer = StringBuffer();
    for (var index = 0; index < _lines.length; index++) {
      if (index > 0) buffer.write('\n');
      final line = _lines[index];
      final text = _controllers[index].text;
      switch (line.type) {
        case _IssueLineType.checkbox:
          buffer.write('${line.checked ? '☑' : '☐'} $text');
        case _IssueLineType.heading:
          buffer.write('## $text');
        case _IssueLineType.divider:
          buffer.write('───────────');
        case _IssueLineType.text:
          buffer.write(text);
      }
    }
    return buffer.toString();
  }

  void _appendLine(
    _IssueLineType type, {
    String text = '',
    bool checked = false,
    int? at,
  }) {
    final line = _IssueEditorLine(type: type, checked: checked);
    final controller = TextEditingController(text: text);
    controller.addListener(_markBodyChanged);
    final focusNode = _makeFocusNode();

    if (at == null) {
      _lines.add(line);
      _controllers.add(controller);
      _focusNodes.add(focusNode);
    } else {
      _lines.insert(at, line);
      _controllers.insert(at, controller);
      _focusNodes.insert(at, focusNode);
    }
  }

  FocusNode _makeFocusNode() {
    final focusNode = FocusNode();
    focusNode.onKeyEvent = (node, event) {
      final index = _focusNodes.indexOf(node);
      if (index <= 0) return KeyEventResult.ignored;
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.backspace) {
        final controller = _controllers[index];
        if (controller.selection.isCollapsed &&
            controller.selection.baseOffset == 0) {
          _mergeWithPrevious(index);
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        final index = _focusNodes.indexOf(focusNode);
        if (index != -1 && mounted) {
          setState(() => _focusedIndex = index);
        }
      }
    });
    return focusNode;
  }

  void _removeLine(int index) {
    if (_lines.length <= 1) return;
    _controllers[index].dispose();
    _focusNodes[index].dispose();
    _lines.removeAt(index);
    _controllers.removeAt(index);
    _focusNodes.removeAt(index);
    if (_focusedIndex >= _lines.length) {
      _focusedIndex = _lines.length - 1;
    }
  }

  void _markTitleChanged() {
    if (!_hasChanged && mounted) setState(() => _hasChanged = true);
  }

  void _markBodyChanged() {
    if (_restoring) return;
    final current = _serialize();
    if (current != _lastSnapshot) {
      _undoStack.add(_lastSnapshot);
      if (_undoStack.length > 50) _undoStack.removeAt(0);
      _redoStack.clear();
      _lastSnapshot = current;
    }
    if (!_hasChanged && mounted) setState(() => _hasChanged = true);
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_serialize());
    _restoreSnapshot(_undoStack.removeLast());
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_serialize());
    _restoreSnapshot(_redoStack.removeLast());
  }

  void _restoreSnapshot(String content) {
    _restoring = true;
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _lines.clear();
    _controllers.clear();
    _focusNodes.clear();
    _focusedIndex = -1;
    _parseContent(content);
    _lastSnapshot = content;
    _restoring = false;
    setState(() => _hasChanged = true);
  }

  Future<void> _save() async {
    if (_saving || !_hasChanged) return;
    final title = _titleController.text.trim();
    final note = _serialize().trimRight();
    if (title.isEmpty && note.isEmpty) return;

    _saving = true;
    final provider = context.read<TaskIssueProvider>();
    final displayTitle = title.isEmpty ? S.read(context).untitledIssue : title;
    if (_savedIssue == null) {
      _savedIssue = await provider.addIssue(title: displayTitle, note: note);
    } else {
      _savedIssue = await provider.updateIssue(
        _savedIssue!,
        title: displayTitle,
        note: note,
      );
    }
    _hasChanged = false;
    _saving = false;
    _lastSnapshot = note;
    if (mounted) setState(() {});
  }

  void _handleEnter(int index, String before, List<String> after) {
    final line = _lines[index];
    if ((line.type == _IssueLineType.checkbox ||
            line.type == _IssueLineType.heading) &&
        before.isEmpty &&
        after.every((value) => value.isEmpty)) {
      setState(() => line.type = _IssueLineType.text);
      _markBodyChanged();
      return;
    }

    final numberMatch = _numberPrefix.firstMatch(_controllers[index].text);
    if (numberMatch != null && line.type == _IssueLineType.text) {
      final currentNumber = int.parse(numberMatch.group(1)!);
      final prefix = '${currentNumber + 1}. ';
      final contentAfterNumber = before.substring(numberMatch.end);
      if (contentAfterNumber.isEmpty && after.every((value) => value.isEmpty)) {
        _controllers[index].text = '';
        return;
      }
      setState(() {
        for (var offset = 0; offset < after.length; offset++) {
          _appendLine(
            _IssueLineType.text,
            text: offset == 0 ? '$prefix${after[offset]}' : after[offset],
            at: index + 1 + offset,
          );
        }
      });
      _focusLine(index + 1, offset: prefix.length);
      _markBodyChanged();
      return;
    }

    final nextType = line.type == _IssueLineType.checkbox
        ? _IssueLineType.checkbox
        : _IssueLineType.text;
    setState(() {
      for (var offset = 0; offset < after.length; offset++) {
        _appendLine(nextType, text: after[offset], at: index + 1 + offset);
      }
    });
    _focusLine(index + 1);
    _markBodyChanged();
  }

  void _mergeWithPrevious(int index) {
    if (index <= 0) return;
    if (_lines[index - 1].type == _IssueLineType.divider) {
      setState(() => _removeLine(index - 1));
      _markBodyChanged();
      return;
    }
    final text = _controllers[index].text;
    final previous = _controllers[index - 1];
    final mergePosition = previous.text.length;
    previous.text += text;
    setState(() => _removeLine(index));
    _focusLine(index - 1, offset: mergePosition);
    _markBodyChanged();
  }

  void _focusLine(int index, {int? offset}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (index < 0 || index >= _focusNodes.length) return;
      _focusNodes[index].requestFocus();
      if (offset != null) {
        _controllers[index].selection = TextSelection.collapsed(offset: offset);
      }
    });
  }

  void _addCheckbox() => _insertLine(_IssueLineType.checkbox);

  void _addHeading() => _insertLine(_IssueLineType.heading);

  void _addDivider() => _insertLine(_IssueLineType.divider, focus: false);

  void _addNumbering() {
    _insertLine(_IssueLineType.text, text: '1. ', focusOffset: 3);
  }

  void _insertLine(
    _IssueLineType type, {
    String text = '',
    bool focus = true,
    int? focusOffset,
  }) {
    final index = (_focusedIndex >= 0 ? _focusedIndex : _lines.length - 1) + 1;
    setState(() => _appendLine(type, text: text, at: index));
    if (focus) _focusLine(index, offset: focusOffset);
    _markBodyChanged();
  }

  void _selectAllAndCopy() {
    Clipboard.setData(
      ClipboardData(text: '${_titleController.text}\n${_serialize()}'),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.read(context).copiedAllContent),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_hasChanged && !_saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && !_saving) {
          await _save();
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.issue == null ? s.newIssue : s.editIssue),
          actions: [
            IconButton(
              tooltip: s.copyAll,
              icon: const Icon(Icons.select_all_rounded),
              onPressed: _selectAllAndCopy,
            ),
            IconButton(
              tooltip: s.undo,
              icon: const Icon(Icons.undo_rounded),
              onPressed: _undoStack.isEmpty ? null : _undo,
            ),
            IconButton(
              tooltip: s.redo,
              icon: const Icon(Icons.redo_rounded),
              onPressed: _redoStack.isEmpty ? null : _redo,
            ),
            if (_hasChanged)
              IconButton(
                tooltip: s.save,
                icon: const Icon(Icons.save_rounded),
                onPressed: () async {
                  await _save();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(s.saved),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: _titleController,
                autofocus: widget.issue == null,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: s.issueTitleHint,
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
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _focusLine(_lines.length - 1),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: _lines.length,
                  itemBuilder: (context, index) => _buildLine(index),
                ),
              ),
            ),
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
                  _toolButton(Icons.check_box_outlined, _addCheckbox),
                  _toolButton(Icons.title_rounded, _addHeading),
                  _toolButton(
                    Icons.format_list_numbered_rounded,
                    _addNumbering,
                  ),
                  _toolButton(Icons.horizontal_rule_rounded, _addDivider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolButton(IconData icon, VoidCallback onTap) {
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

  Widget _buildLine(int index) {
    final line = _lines[index];
    switch (line.type) {
      case _IssueLineType.checkbox:
        return _checkboxLine(index, line);
      case _IssueLineType.heading:
        return _headingLine(index);
      case _IssueLineType.divider:
        return _dividerLine(index);
      case _IssueLineType.text:
        return _textLine(index);
    }
  }

  Widget _checkboxLine(int index, _IssueEditorLine line) {
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
              _markBodyChanged();
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
            child: _field(
              index,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                decoration: line.checked ? TextDecoration.lineThrough : null,
                color: line.checked ? Colors.grey : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headingLine(int index) {
    return Padding(
      key: ValueKey(_lines[index].id),
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: _field(
        index,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _dividerLine(int index) {
    return GestureDetector(
      key: ValueKey(_lines[index].id),
      onLongPress: () {
        if (_lines.length > 1) {
          setState(() => _removeLine(index));
          _markBodyChanged();
        }
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(thickness: 1),
      ),
    );
  }

  Widget _textLine(int index) {
    return Padding(
      key: ValueKey(_lines[index].id),
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: _field(
        index,
        style: const TextStyle(fontSize: 16, height: 1.6),
        hint: index == 0 && _lines.length == 1
            ? S.of(context).issueNoteHint
            : null,
      ),
    );
  }

  Widget _field(int index, {TextStyle? style, String? hint}) {
    return TextField(
      controller: _controllers[index],
      focusNode: _focusNodes[index],
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
        _IssueEnterSplitter(
          onEnter: (before, after) => _handleEnter(index, before, after),
        ),
      ],
    );
  }
}

class _IssueEnterSplitter extends TextInputFormatter {
  const _IssueEnterSplitter({required this.onEnter});

  final void Function(String before, List<String> after) onEnter;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.text.contains('\n')) return newValue;
    final parts = newValue.text.split('\n');
    final before = parts.first;
    final after = parts.sublist(1);
    WidgetsBinding.instance.addPostFrameCallback((_) => onEnter(before, after));
    return TextEditingValue(
      text: before,
      selection: TextSelection.collapsed(offset: before.length),
    );
  }
}

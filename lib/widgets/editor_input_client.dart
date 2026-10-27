import 'package:flutter/services.dart';
import '../models/document.dart';
import '../models/editor_model.dart';

int _rowColToOffset(List<String> lines, int row, int col) {
  var offset = 0;
  final r = row.clamp(0, lines.isEmpty ? 0 : lines.length - 1);
  for (var i = 0; i < r; i++) {
    offset += lines[i].length + 1;
  }
  final c = col.clamp(0, lines.isEmpty ? 0 : lines[r].length);
  return offset + c;
}

(int row, int col) _offsetToRowCol(List<String> lines, int offset) {
  if (lines.isEmpty) return (0, 0);
  var current = 0;
  for (var i = 0; i < lines.length; i++) {
    final len = lines[i].length;
    if (offset <= current + len) {
      return (i, offset - current);
    }
    current += len + 1;
  }
  return (lines.length - 1, lines.last.length);
}

/// Direct [DeltaTextInputClient] implementation for text editing without hidden
/// TextField sentinel hacks. Correctly handles complex IME deltas, selection, and
/// composing ranges (essential for soft gesture keyboards and phonetic IMEs like Bangla).
class EditorInputClient implements DeltaTextInputClient {
  EditorInputClient({
    required this.model,
    required this.onEditingChanged,
  }) {
    _syncValueFromModel();
  }

  final EditorModel model;
  final VoidCallback onEditingChanged;

  TextInputConnection? _connection;
  TextEditingValue _currentValue = TextEditingValue.empty;
  TextRange _composing = TextRange.empty;

  bool get isAttached => _connection != null && _connection!.attached;
  TextRange get composing => _composing;

  @override
  TextEditingValue? get currentTextEditingValue => _currentValue;

  void attach() {
    if (isAttached) return;

    _syncValueFromModel();
    _connection = TextInput.attach(
      this,
      const TextInputConfiguration(
        inputType: TextInputType.multiline,
        enableDeltaModel: true,
        autocorrect: false,
        enableSuggestions: false,
        inputAction: TextInputAction.newline,
      ),
    );
    _connection!.setEditingState(_currentValue);
    _connection!.show();
  }

  void detach() {
    if (_connection != null) {
      if (_connection!.attached) {
        _connection!.close();
      }
      _connection = null;
    }
  }

  void updateModelSelection(int row, int col) {
    model.moveTo(row, col);
    _syncValueFromModel();
    _connection?.setEditingState(_currentValue);
  }

  void _syncValueFromModel() {
    final text = model.text;
    final offset = _rowColToOffset(model.lines, model.row, model.col)
        .clamp(0, text.length);
    _currentValue = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
      composing: _composing,
    );
  }

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> deltas) {
    var newText = _currentValue.text;
    var selectionStart = _currentValue.selection.start;
    TextRange newComposing = _composing;
    var hasTextChanges = false;

    for (final delta in deltas) {
      if (delta is TextEditingDeltaInsertion) {
        final insertOffset = delta.insertionOffset;
        final inserted = delta.textInserted;
        newText = newText.replaceRange(insertOffset, insertOffset, inserted);
        selectionStart = insertOffset + inserted.length;
        newComposing = delta.composing;
        hasTextChanges = true;
      } else if (delta is TextEditingDeltaDeletion) {
        final start = delta.deletedRange.start;
        final end = delta.deletedRange.end;
        if (start >= 0 && end <= newText.length && start < end) {
          newText = newText.replaceRange(start, end, '');
          selectionStart = start;
        }
        newComposing = delta.composing;
        hasTextChanges = true;
      } else if (delta is TextEditingDeltaReplacement) {
        final start = delta.replacedRange.start;
        final end = delta.replacedRange.end;
        final replacement = delta.replacementText;
        if (start >= 0 && end <= newText.length && start <= end) {
          newText = newText.replaceRange(start, end, replacement);
          selectionStart = start + replacement.length;
        }
        newComposing = delta.composing;
        hasTextChanges = true;
      } else if (delta is TextEditingDeltaNonTextUpdate) {
        selectionStart = delta.selection.start;
        newComposing = delta.composing;
      }
    }

    _composing = newComposing;

    final lines = newText.split('\n');
    final (row, col) = _offsetToRowCol(lines, selectionStart);

    if (hasTextChanges) {
      if (model.text != newText) {
        const oldStart = TextPosition(0, 0);
        final oldEnd = model.document.offsetToPosition(model.text.length);
        model.document.replaceRange(oldStart, oldEnd, newText);
      }
      model.document.cursorPosition = TextPosition(row, col);
      model.dirty = true;
    } else {
      model.updateState(
        newLines: lines,
        newRow: row,
        newCol: col,
        isDirty: true,
      );
    }

    _syncValueFromModel();
    onEditingChanged();
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    _currentValue = value;
    _composing = value.composing;

    final lines = value.text.split('\n');
    final (row, col) = _offsetToRowCol(lines, value.selection.baseOffset);

    if (value.text != model.text) {
      const oldPosStart = TextPosition(0, 0);
      final oldPosEnd = model.document.offsetToPosition(model.text.length);
      model.document.replaceRange(oldPosStart, oldPosEnd, value.text);
      model.document.cursorPosition = TextPosition(row, col);
      model.dirty = true;
    } else {
      model.updateState(
        newLines: lines,
        newRow: row,
        newCol: col,
        isDirty: true,
      );
    }

    onEditingChanged();
  }

  @override
  void performAction(TextInputAction action) {
    if (action == TextInputAction.newline) {
      model.newline();
      _syncValueFromModel();
      _connection?.setEditingState(_currentValue);
      onEditingChanged();
    }
  }

  @override
  void connectionClosed() {
    _connection = null;
  }

  bool onFocusReceived() => true;

  @override
  void didChangeInputControl(TextInputControl? oldControl, TextInputControl? newControl) {}

  @override
  void performSelector(String selectorName) {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  void showAutocorrectPromptRect(int start, int end) {}

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}

  @override
  void insertTextPlaceholder(Size size) {}

  @override
  void removeTextPlaceholder() {}

  @override
  void showToolbar() {}

  @override
  void insertContent(KeyboardInsertedContent content) {}

  @override
  AutofillScope? get currentAutofillScope => null;
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/document.dart';
import '../models/editor_model.dart';
import 'code_view.dart' show rowColToOffset, offsetToRowCol;

/// Bridges the phone keyboard (IME) and [EditorModel].
///
/// The IME keeps its own copy of (text, selection). Two rules make Backspace,
/// Cut and "type over selection" work:
///  1. Use the delta model: the keyboard reports exact insert / delete /
///     replace operations (backspace == TextEditingDeltaDeletion).
///  2. Whenever caret or selection change outside the keyboard (tap, find,
///     go-to-line, handles, cut, paste ...) call [syncToIme] so the keyboard
///     knows the real caret. A stale caret is why Backspace did nothing.
///
/// The mirrored text is the whole document joined with '\n'. For very large
/// files (>200k chars) switch to a window around the caret.
class EditorInputClient with TextInputClient, DeltaTextInputClient {
  EditorInputClient({
    required this.model,
    required this.setCaret,
    required this.onEditingChanged,
  });

  final EditorModel model;

  /// Moves the model's caret. Wired in CodeView (_setCaretRaw).
  final void Function(int row, int col) setCaret;
  final VoidCallback onEditingChanged;

  TextInputConnection? _conn;
  TextEditingValue _value = TextEditingValue.empty;

  bool get attached => _conn?.attached ?? false;

  void attach() {
    if (attached) {
      _conn!.show();
      return;
    }
    _conn = TextInput.attach(
      this,
      const TextInputConfiguration(
        inputType: TextInputType.multiline,
        inputAction: TextInputAction.newline,
        enableDeltaModel: true,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.none,
      ),
    );
    syncToIme();
    _conn!.show();
  }

  void detach() {
    _conn?.close();
    _conn = null;
  }

  /// Push the current text + caret (or selection [a]..[b]) to the keyboard.
  void syncToIme([TextPosition? a, TextPosition? b]) {
    final conn = _conn;
    if (conn == null || !conn.attached) return;
    final lines = model.lines;
    final p1 = a ?? TextPosition(model.row, model.col);
    final p2 = b ?? p1;
    _value = TextEditingValue(
      text: lines.join('\n'),
      selection: TextSelection(
        baseOffset: rowColToOffset(lines, p1.row, p1.col),
        extentOffset: rowColToOffset(lines, p2.row, p2.col),
      ),
    );
    conn.setEditingState(_value);
  }

  void updateModelSelection(int row, int col) {
    setCaret(row, col);
    syncToIme();
    onEditingChanged();
  }

  // ---- keyboard -> model --------------------------------------------------

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> deltas) {
    final doc = model.document;
    for (final d in deltas) {
      final lines = model.lines;

      void replace(int from, int to, String text) {
        final s = offsetToRowCol(lines, from);
        final e = offsetToRowCol(lines, to);
        doc.replaceRange(
            TextPosition(s.$1, s.$2), TextPosition(e.$1, e.$2), text);
      }

      if (d is TextEditingDeltaInsertion) {
        replace(d.insertionOffset, d.insertionOffset, d.textInserted);
      } else if (d is TextEditingDeltaDeletion) {
        // Backspace, Delete, Cut, delete-selection
        replace(d.deletedRange.start, d.deletedRange.end, '');
      } else if (d is TextEditingDeltaReplacement) {
        // Typing over a selection, autocorrect, composing (Bengali etc.)
        replace(d.replacedRange.start, d.replacedRange.end, d.replacementText);
      }
      // TextEditingDeltaNonTextUpdate: only the caret moved (handled below).
    }
    if (deltas.isNotEmpty) {
      final sel = deltas.last.selection;
      if (sel.isValid) {
        final rc = offsetToRowCol(model.lines, sel.extentOffset);
        setCaret(rc.$1, rc.$2);
      }
      _value = TextEditingValue(
        text: model.lines.join('\n'),
        selection: deltas.last.selection,
        composing: deltas.last.composing,
      );
    }
    onEditingChanged();
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    // Unused: delta model delivers changes via updateEditingValueWithDeltas.
  }

  @override
  TextEditingValue get currentTextEditingValue => _value;

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  void performAction(TextInputAction action) {
    if (action == TextInputAction.newline) model.insert('\n');
  }

  @override
  void connectionClosed() => _conn = null;

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}

  @override
  void showToolbar() {}

  @override
  void insertTextPlaceholder(Size size) {}

  @override
  void removeTextPlaceholder() {}

  @override
  void didChangeInputControl(
      TextInputControl? oldControl, TextInputControl? newControl) {}

  @override
  void performSelector(String selectorName) {}
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;
import '../services/code_forge_service.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

class CodeForgePanel extends StatefulWidget {
  const CodeForgePanel({
    super.key,
    required this.fileName,
    required this.currentCode,
    this.selectedCode,
    required this.onInsertCode,
    required this.onReplaceCode,
    required this.onClose,
    this.service,
  });

  final String fileName;
  final String currentCode;
  final String? selectedCode;
  final ValueChanged<String> onInsertCode;
  final ValueChanged<String> onReplaceCode;
  final VoidCallback onClose;
  final CodeForgeService? service;

  @override
  State<CodeForgePanel> createState() => _CodeForgePanelState();
}

class _CodeForgePanelState extends State<CodeForgePanel> {
  final TextEditingController _promptController = TextEditingController();
  CodeForgeAction _selectedAction = CodeForgeAction.generate;
  CodeForgeResult? _result;
  bool _isProcessing = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  late final CodeForgeService _service;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? CodeForgeService();
  }

  void _runAction(CodeForgeAction action) {
    setState(() {
      _selectedAction = action;
      _isProcessing = true;
    });

    final res = _service.processPrompt(
      prompt: _promptController.text.trim(),
      fileName: widget.fileName,
      currentCode: widget.currentCode,
      selectedCode: widget.selectedCode,
      action: action,
    );

    setState(() {
      _result = res;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final media = MediaQuery.of(context);

    final height = (media.size.height * 0.65).clamp(280.0, 500.0);

    return SizedBox(
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: c.raised,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: c.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: iconoir.Cpu(color: Colors.white, width: 18, height: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CodeForge AI Assistant',
                          style: LatticeText.ui(15,
                              weight: FontWeight.w600, color: c.text)),
                      Text('Target: ${widget.fileName}',
                          style: LatticeText.ui(11, color: c.textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: iconoir.Xmark(color: c.textMuted, width: 18, height: 18),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),

          // Action selection chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _ActionChip(
                  label: 'Generate',
                  icon: iconoir.Flash(
                    color: _selectedAction == CodeForgeAction.generate
                        ? Colors.white
                        : c.textMuted,
                    width: 14,
                    height: 14,
                  ),
                  selected: _selectedAction == CodeForgeAction.generate,
                  onTap: () => _runAction(CodeForgeAction.generate),
                ),
                const SizedBox(width: 6),
                _ActionChip(
                  label: 'Fix Errors',
                  icon: iconoir.Wrench(
                    color: _selectedAction == CodeForgeAction.fixErrors
                        ? Colors.white
                        : c.textMuted,
                    width: 14,
                    height: 14,
                  ),
                  selected: _selectedAction == CodeForgeAction.fixErrors,
                  onTap: () => _runAction(CodeForgeAction.fixErrors),
                ),
                const SizedBox(width: 6),
                _ActionChip(
                  label: 'Refactor',
                  icon: iconoir.DesignPencil(
                    color: _selectedAction == CodeForgeAction.refactor
                        ? Colors.white
                        : c.textMuted,
                    width: 14,
                    height: 14,
                  ),
                  selected: _selectedAction == CodeForgeAction.refactor,
                  onTap: () => _runAction(CodeForgeAction.refactor),
                ),
                const SizedBox(width: 6),
                _ActionChip(
                  label: 'Add Tests',
                  icon: iconoir.CheckCircle(
                    color: _selectedAction == CodeForgeAction.addTests
                        ? Colors.white
                        : c.textMuted,
                    width: 14,
                    height: 14,
                  ),
                  selected: _selectedAction == CodeForgeAction.addTests,
                  onTap: () => _runAction(CodeForgeAction.addTests),
                ),
                const SizedBox(width: 6),
                _ActionChip(
                  label: 'Explain',
                  icon: iconoir.InfoCircle(
                    color: _selectedAction == CodeForgeAction.explain
                        ? Colors.white
                        : c.textMuted,
                    width: 14,
                    height: 14,
                  ),
                  selected: _selectedAction == CodeForgeAction.explain,
                  onTap: () => _runAction(CodeForgeAction.explain),
                ),
              ],
            ),
          ),

          // Prompt input row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Container(
              height: 42,
              padding: const EdgeInsets.only(left: 12, right: 4),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promptController,
                      style: LatticeText.ui(13, color: c.text),
                      cursorColor: c.accent,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Describe code to generate or refactor…',
                        hintStyle: LatticeText.ui(13, color: c.textFaint),
                      ),
                      onSubmitted: (_) => _runAction(_selectedAction),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ask CodeForge',
                    icon: iconoir.Send(color: c.accent, width: 18, height: 18),
                    onPressed: () => _runAction(_selectedAction),
                  ),
                ],
              ),
            ),
          ),

          // Output Section
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: _isProcessing
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _result == null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                iconoir.Flash(
                                    color: c.textFaint, width: 32, height: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'Select an action or enter a prompt to forge code.',
                                  style: LatticeText.ui(12, color: c.textMuted),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Explanation box
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: c.accentSoft,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: c.accent.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _result!.explanation,
                                style: LatticeText.ui(12, color: c.text),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Generated code preview block
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: c.bg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: c.border),
                              ),
                              child: SelectableText(
                                _result!.generatedCode,
                                style: LatticeText.mono(12, color: c.synPlain),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Actions row (Insert / Replace / Copy)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: iconoir.PagePlus(
                                        color: c.text, width: 14, height: 14),
                                    label: Text('Insert at Cursor',
                                        style: LatticeText.ui(12, color: c.text)),
                                    onPressed: () {
                                      widget.onInsertCode(
                                          _result!.generatedCode);
                                      widget.onClose();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: c.accent,
                                    ),
                                    icon: const iconoir.Refresh(
                                        color: Colors.white,
                                        width: 14,
                                        height: 14),
                                    label: Text('Replace Code',
                                        style: LatticeText.ui(12,
                                            color: Colors.white)),
                                    onPressed: () {
                                      widget.onReplaceCode(
                                          _result!.generatedCode);
                                      widget.onClose();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Copy Code',
                                  icon: iconoir.Copy(
                                      color: c.textMuted,
                                      width: 16,
                                      height: 16),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                        text: _result!.generatedCode));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Copied code to clipboard'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.accent : c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c.accent : c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 5),
            Text(
              label,
              style: LatticeText.ui(
                12,
                weight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? Colors.white : c.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

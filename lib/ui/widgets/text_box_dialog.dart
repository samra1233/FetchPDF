import 'package:flutter/material.dart';

class TextBoxDialogResult {
  final String text;
  final double fontSize;
  final Color textColor;
  final Color? fillColor;

  TextBoxDialogResult({
    required this.text,
    required this.fontSize,
    required this.textColor,
    this.fillColor,
  });
}

class TextBoxDialog extends StatefulWidget {
  final String initialText;
  final double initialFontSize;
  final Color initialTextColor;
  final Color? initialFillColor;

  const TextBoxDialog({
    this.initialText = '',
    this.initialFontSize = 14.0,
    this.initialTextColor = Colors.black,
    this.initialFillColor = const Color(0x33FFFF00),
    super.key,
  });

  static Future<TextBoxDialogResult?> show(
    BuildContext context, {
    String initialText = '',
    double initialFontSize = 14.0,
    Color initialTextColor = Colors.black,
    Color? initialFillColor = const Color(0x33FFFF00),
  }) {
    return showDialog<TextBoxDialogResult>(
      context: context,
      builder: (context) => TextBoxDialog(
        initialText: initialText,
        initialFontSize: initialFontSize,
        initialTextColor: initialTextColor,
        initialFillColor: initialFillColor,
      ),
    );
  }

  @override
  State<TextBoxDialog> createState() => _TextBoxDialogState();
}

class _TextBoxDialogState extends State<TextBoxDialog> {
  late final TextEditingController _controller;
  late double _fontSize;
  late Color _textColor;
  late Color? _fillColor;

  final List<Color> _colors = const [
    Colors.black,
    Color(0xFF0078D4),
    Color(0xFFD83B01),
    Color(0xFF107C41),
    Color(0xFF5C2D91),
    Colors.white,
  ];

  final List<Color?> _fillColors = const [
    null,
    Color(0x33FFFF00), // light yellow
    Color(0x330078D4), // light blue
    Color(0x33107C41), // light green
    Color(0x33D83B01), // light red
    Color(0xCCFFFFFF), // solid white
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _fontSize = widget.initialFontSize;
    _textColor = widget.initialTextColor;
    _fillColor = widget.initialFillColor;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      title: const Row(
        children: [
          Icon(Icons.text_fields_rounded, color: Color(0xFF0078D4), size: 22),
          SizedBox(width: 8),
          Text('Insert Text Box', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Note: This inserts a new text annotation onto the page.',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 4,
              autofocus: true,
              style: TextStyle(
                fontSize: _fontSize,
                color: isDark && _textColor == Colors.black ? Colors.white : _textColor,
              ),
              decoration: InputDecoration(
                hintText: 'Type text here...',
                filled: true,
                fillColor: _fillColor ?? (isDark ? const Color(0xFF383838) : const Color(0xFFF5F5F5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Font Size:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                DropdownButton<double>(
                  value: _fontSize,
                  underline: const SizedBox(),
                  items: [10.0, 12.0, 14.0, 16.0, 18.0, 24.0, 32.0].map((s) {
                    return DropdownMenuItem(value: s, child: Text('${s.toInt()} pt'));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _fontSize = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Text Color:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                ..._colors.map((c) {
                  final isSelected = _textColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _textColor = c),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0078D4) : Colors.grey,
                          width: isSelected ? 2.5 : 1.0,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Background:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                ..._fillColors.map((c) {
                  final isSelected = _fillColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _fillColor = c),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: c ?? Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0078D4) : Colors.grey,
                          width: isSelected ? 2.5 : 1.0,
                        ),
                      ),
                      child: c == null ? const Icon(Icons.close, size: 14, color: Colors.grey) : null,
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0078D4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: () {
            if (_controller.text.trim().isEmpty) return;
            Navigator.of(context).pop(TextBoxDialogResult(
              text: _controller.text.trim(),
              fontSize: _fontSize,
              textColor: _textColor,
              fillColor: _fillColor,
            ));
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

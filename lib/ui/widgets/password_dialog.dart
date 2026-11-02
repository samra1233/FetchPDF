import 'package:flutter/material.dart';

class PasswordDialog extends StatefulWidget {
  final String fileName;

  const PasswordDialog({required this.fileName, super.key});

  static Future<String?> show(BuildContext context, String fileName) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordDialog(fileName: fileName),
    );
  }

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _controller = TextEditingController();
  bool _obscureText = true;

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
      title: Row(
        children: [
          const Icon(Icons.lock_outline, color: Color(0xFF0078D4), size: 24),
          const SizedBox(width: 10),
          const Text('Password Required', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The document "${widget.fileName}" is password protected. Please enter the password to open it.',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: _obscureText,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter password',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              suffixIcon: IconButton(
                icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off, size: 20),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              ),
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
          ),
        ],
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
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Unlock'),
        ),
      ],
    );
  }
}

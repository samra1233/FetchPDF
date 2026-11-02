import 'package:flutter/material.dart';

enum DiscardChoice {
  save,
  discard,
  cancel,
}

class ConfirmDiscardDialog extends StatelessWidget {
  final String fileName;

  const ConfirmDiscardDialog({required this.fileName, super.key});

  static Future<DiscardChoice?> show(BuildContext context, String fileName) {
    return showDialog<DiscardChoice>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmDiscardDialog(fileName: fileName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
          const SizedBox(width: 10),
          const Text('Save Changes?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Text(
        'Do you want to save changes to "$fileName" before closing?\nYour modifications will be lost if you do not save them.',
        style: const TextStyle(fontSize: 13),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(DiscardChoice.cancel),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(DiscardChoice.discard),
          child: const Text("Don't Save", style: TextStyle(color: Colors.redAccent)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0078D4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: () => Navigator.of(context).pop(DiscardChoice.save),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

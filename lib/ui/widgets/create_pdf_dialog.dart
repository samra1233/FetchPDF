import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/document_creation_service.dart';

class CreatePdfDialog extends StatefulWidget {
  final Function({
    required PageSizePreset size,
    required PageOrientationPreset orientation,
    required PagePatternPreset pattern,
    required int pageCount,
    required String fileName,
  }) onCreated;

  const CreatePdfDialog({required this.onCreated, super.key});

  @override
  State<CreatePdfDialog> createState() => _CreatePdfDialogState();
}

class _CreatePdfDialogState extends State<CreatePdfDialog> {
  final _nameController = TextEditingController(text: 'Untitled.pdf');
  PageSizePreset _selectedSize = PageSizePreset.a4;
  PageOrientationPreset _selectedOrientation = PageOrientationPreset.portrait;
  PagePatternPreset _selectedPattern = PagePatternPreset.blank;
  int _pageCount = 1;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.note_add_outlined, color: AppColors.brandPrimary),
          SizedBox(width: 10),
          Text('Create New PDF Document', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document Name
              const Text('Document Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: 'Document name...',
                ),
              ),

              const SizedBox(height: 16),

              // Page Size
              const Text('Page Size', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<PageSizePreset>(
                initialValue: _selectedSize,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: PageSizePreset.values.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s.label, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSize = val);
                },
              ),

              const SizedBox(height: 16),

              // Orientation
              const Text('Orientation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedOrientation = PageOrientationPreset.portrait),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedOrientation == PageOrientationPreset.portrait ? AppColors.brandPrimary : const Color(0xFFE2E8F0),
                            width: _selectedOrientation == PageOrientationPreset.portrait ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedOrientation == PageOrientationPreset.portrait ? Icons.radio_button_checked : Icons.radio_button_off,
                              size: 16,
                              color: _selectedOrientation == PageOrientationPreset.portrait ? AppColors.brandPrimary : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            const Text('Portrait', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedOrientation = PageOrientationPreset.landscape),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedOrientation == PageOrientationPreset.landscape ? AppColors.brandPrimary : const Color(0xFFE2E8F0),
                            width: _selectedOrientation == PageOrientationPreset.landscape ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedOrientation == PageOrientationPreset.landscape ? Icons.radio_button_checked : Icons.radio_button_off,
                              size: 16,
                              color: _selectedOrientation == PageOrientationPreset.landscape ? AppColors.brandPrimary : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            const Text('Landscape', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Pattern
              const Text('Page Style', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<PagePatternPreset>(
                initialValue: _selectedPattern,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: PagePatternPreset.values.map((p) {
                  return DropdownMenuItem(value: p, child: Text(p.label, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPattern = val);
                },
              ),

              const SizedBox(height: 16),

              // Page Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Page Count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: _pageCount > 1 ? () => setState(() => _pageCount--) : null,
                      ),
                      Text('$_pageCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: _pageCount < 50 ? () => setState(() => _pageCount++) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Create PDF'),
          onPressed: () {
            var name = _nameController.text.trim();
            if (name.isEmpty) name = 'Untitled.pdf';
            if (!name.toLowerCase().endsWith('.pdf')) name += '.pdf';

            Navigator.pop(context);
            widget.onCreated(
              size: _selectedSize,
              orientation: _selectedOrientation,
              pattern: _selectedPattern,
              pageCount: _pageCount,
              fileName: name,
            );
          },
        ),
      ],
    );
  }
}

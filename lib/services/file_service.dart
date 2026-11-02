import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../models/document_tab.dart';
import 'pdf_modifier_service.dart';

class FileService {
  /// Prompts the native Windows File Picker dialog to select a PDF file
  static Future<String?> pickPdfFile() async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Open PDF Document',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result.isNotEmpty && result.first.path != null) {
        return result.first.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Saves changes back to the document's file path. If no path exists, triggers Save As.
  static Future<bool> saveDocument(DocumentTab tab) async {
    if (tab.filePath == null || tab.filePath!.isEmpty) {
      return saveAsDocument(tab);
    }

    try {
      final modifiedBytes = await PdfModifierService.applyModifications(tab);
      
      // Atomic save: write to temp file first, then replace
      final originalFile = File(tab.filePath!);
      final tempFile = File('${tab.filePath!}.tmp');
      await tempFile.writeAsBytes(modifiedBytes, flush: true);

      if (await originalFile.exists()) {
        await originalFile.delete();
      }
      await tempFile.rename(tab.filePath!);

      tab.markSaved(updatedBytes: modifiedBytes);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Prompts the native Windows Save File dialog to save a copy
  static Future<bool> saveAsDocument(DocumentTab tab) async {
    try {
      var suggestedName = tab.fileName;
      if (!suggestedName.toLowerCase().endsWith('.pdf')) {
        suggestedName = '$suggestedName.pdf';
      }

      final modifiedBytes = await PdfModifierService.applyModifications(tab);

      final uri = await FilePicker.saveFile(
        dialogTitle: 'Save PDF As',
        fileName: suggestedName,
        bytes: modifiedBytes,
        mimeType: 'application/pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (uri == null) return false;

      final savedPath = uri.toFilePath();
      tab.markSaved(
        newPath: savedPath,
        newFileName: p.basename(savedPath),
        updatedBytes: modifiedBytes,
      );
      return true;
    } catch (e) {
      rethrow;
    }
  }
}

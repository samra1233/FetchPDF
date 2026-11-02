import 'package:flutter_test/flutter_test.dart';
import 'package:fetchpdf/services/sample_pdf_generator.dart';
import 'package:fetchpdf/services/pdf_document_service.dart';
import 'package:fetchpdf/state/editor_tab_controller.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  test('pdfrx controller state and safe searcher initialization', () {
    final controller = PdfViewerController();
    expect(controller.isReady, false);

    // Verify EditorTabController safely guards textSearcher until viewer is ready
    final bytes = SamplePdfGenerator.createSampleDocument();
    final tab = PdfDocumentService.parseDocument(bytes, fileName: 'Test.pdf');
    final tabController = EditorTabController(tab: tab);

    expect(tabController.pdfViewerController.isReady, false);
    expect(tabController.textSearcher, null);

    tabController.dispose();
    tab.dispose();
  });
}

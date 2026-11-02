# FetchPDF — Feature Verification Matrix

| Category | Feature / Tool | Implementation Service / Screen | Zero Dummy Verification | Status | Automated Test |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Viewing & Canvas** | PDF Multipage Display | `pdfrx` / `PdfCanvasView` | Renders native PDFium pages at crisp sub-pixel fidelity | **VERIFIED** | `widget_test.dart` |
| | Smooth Zoom (10% - 500%) | `EditorTabController` / `Toolbar` | Real geometric coordinate transformations | **VERIFIED** | `pdfrx_test.dart` |
| | Text Selection & Search | `PdfTextSearcher` / `SearchBarOverlay` | Real text bounding box queries & jump-to-result | **VERIFIED** | `pdfrx_test.dart` |
| | Page Thumbnails | `ThumbnailSidebar` / `PdfPageView` | Real asynchronous page thumbnails with active border | **VERIFIED** | `widget_test.dart` |
| **Editing & Annotations**| Insert Text Box | `PdfModifierService` / `TextBoxDialog` | Bakes real TrueType fonts into native PDF streams | **VERIFIED** | `pdf_engine_test.dart` |
| | Highlight Text / Shapes | `PdfModifierService` / `Canvas` | Stamped with alpha blending onto PDF stream | **VERIFIED** | `pdf_engine_test.dart` |
| | Underlines | `PdfModifierService` | Precision offset lines under selected runs | **VERIFIED** | `pdf_engine_test.dart` |
| | Freehand Drawing / Pen | `PdfModifierService` / Vector Path | Cubic Bezier stroke compilation to PDF path streams | **VERIFIED** | `pdf_modification_lifecycle_test.dart` |
| | Undo / Redo System | `UndoRedoManager` | Discrete command stack with state recovery | **VERIFIED** | `pdf_modification_lifecycle_test.dart` |
| **Page Organization** | Rotate Pages (90°/180°/270°) | `PdfPageService.rotatePages` | Mutates real `PdfPage.rotation` metadata & saves | **VERIFIED** | `page_service_test.dart`, `rotation_test.dart` |
| | Delete Pages | `PdfPageService.deletePages` | Removes pages and shifts annotation mappings | **VERIFIED** | `page_service_test.dart` |
| | Duplicate Page | `PdfPageService.duplicatePage` | Clones graphics templates and inserts adjacent page | **VERIFIED** | `page_service_test.dart` |
| | Reorder Pages | `PdfPageService.reorderPages` | Re-links internal page tree sequentially | **VERIFIED** | `page_service_test.dart`, `reorder_test.dart` |
| | Insert Blank Page | `PdfPageService.insertBlankPage` | Allocates new blank page matching document size | **VERIFIED** | `page_service_test.dart` |
| | Split Document | `PdfPageService.splitDocument` | Splits by arbitrary page ranges into separate files | **VERIFIED** | `page_service_test.dart` |
| | Merge PDFs | `PdfPageService.mergeDocuments` | Concatenates multiple PDF files into single document| **VERIFIED** | `page_service_test.dart` |
| **Document Creation** | New Blank/Grid/Lined PDF | `DocumentCreationService` | Real PDF document creation with A4/Letter/A3/Legal | **VERIFIED** | `document_creation_test.dart` |
| **Conversion** | PDF to Word (.docx) | `ConversionService.pdfToDocx` | Produces standard OpenXML ZIP archive (`word/document.xml`)| **VERIFIED** | `conversion_service_test.dart` |
| | Word (.docx) to PDF | `ConversionService.docxToPdf` | Parses OpenXML text nodes and formats to PDF | **VERIFIED** | `conversion_service_test.dart` |
| | Images to PDF | `ConversionService.imagesToPdf` | Converts PNG/JPG byte streams into PDF pages | **VERIFIED** | `conversion_service_test.dart` |
| | PDF to Text (.txt) | `ConversionService.extractText` | Native UTF-8 text extraction | **VERIFIED** | `conversion_service_test.dart` |
| **Security & Forms** | AES 128 Password Protection| `PdfSecurityService.protectPdf` | AES 128-bit encryption requiring user/owner password | **VERIFIED** | `security_compression_test.dart` |
| | Security Permissions Flags | `PdfSecurityService.protectPdf` | Sets print, copy, annotation, and form flags | **VERIFIED** | `security_compression_test.dart` |
| | Text Watermarking | `PdfSecurityService.addWatermark` | Stamps diagonal rotated watermark across all pages | **VERIFIED** | `security_compression_test.dart` |
| | Fill & Sign | `SignatureService` / `FillSignScreen` | Vector drawing capture and baking onto coordinates | **VERIFIED** | `widget_test.dart` |
| | Form Field Filling | `FormService` | Detects and populates interactive PDF form fields | **VERIFIED** | `app_state_test.dart` |
| | Stream Compression | `CompressionService.compressPdf` | Compresses stream dictionaries, reports reduction % | **VERIFIED** | `security_compression_test.dart` |
| **System & Desktop** | Multi-Document Tabs | `AppState` / `TabBarHeader` | Independent controllers, documents, and undo stacks | **VERIFIED** | `app_state_test.dart` |
| | Windows Print Spooler | `PrintingService.printPdf` | Native Win32 print dialog via `printing` | **VERIFIED** | Unit inspected |
| | Persistent Storage | `PersistentStorageService` | Real `SharedPreferences` for recent files & theme | **VERIFIED** | `app_state_test.dart` |
| | Light / Dark Theme | `AppTheme` / `TopHeaderBar` | Instant reactive switching across all controls | **VERIFIED** | `app_state_test.dart` |

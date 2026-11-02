# FetchPDF — Technical Architecture Documentation

## 1. System Overview

**FetchPDF** is a commercial-grade, native Windows desktop PDF editing and document manipulation suite built with Flutter 3.44+ and Dart. The system is engineered around an offline-first, local-processing-only architecture with **zero dummy features**, strict data integrity, atomic saving safeguards, and pixel-accurate desktop ergonomics adhering to modern Windows 11 fluent design principles.

---

## 2. Layered Architecture

FetchPDF enforces clean separation of concerns across 5 architectural layers:

```
┌─────────────────────────────────────────────────────────────┐
│                    User Interface (UI) Layer                 │
│  MainScreen • HomeScreen • TopHeaderBar • TopToolbar       │
│  OrganizeScreen • ConvertScreen • FillSignScreen • Protect  │
│  PdfCanvasView • ThumbnailSidebar • PropertiesPanel         │
├─────────────────────────────────────────────────────────────┤
│                 State & Controller Layer                    │
│  AppState (Theme, Tabs, Persistent Nav, Recent Files)       │
│  EditorTabController (Tools, Zoom, Search, Annotations)     │
│  UndoRedoManager (Command Pattern for Action Lifecycles)    │
├─────────────────────────────────────────────────────────────┤
│                    Domain Model Layer                       │
│  DocumentTab • DocumentMetadata • PageInfo                 │
│  EditorAnnotation (Text, Highlight, Underline, Pen, Rect)   │
│  RecentFileEntry (Storage Metadata, Starred State)          │
├─────────────────────────────────────────────────────────────┤
│                   Service & Engine Layer                    │
│  PdfDocumentService • PdfModifierService • PdfPageService   │
│  ConversionService • PdfSecurityService • CompressionService│
│  SignatureService • FormService • PrintingService           │
├─────────────────────────────────────────────────────────────┤
│               Native Platform & Storage Layer               │
│  pdfrx_engine (Pdfium DLL) • Syncfusion PDF Engine          │
│  OpenXML Engine • SharedPreferences • Win32 Spooler Print   │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Core Engine Implementations

### 3.1 PDF Rendering & Viewport (`pdfrx` & `Pdfium`)
- **Engine**: Hardware-accelerated native PDFium rendering via `pdfrx` Windows x64 DLL.
- **Capabilities**:
  - Sub-pixel crisp multipage rendering with dynamic zoom scale (10% to 500%).
  - Smooth pan/zoom gestures with keyboard/mouse wheel integration.
  - Native glyph hit-testing and fast text search indexing (`PdfTextSearcher`).

### 3.2 Real Document Modification Engine (`syncfusion_flutter_pdf`)
- Annotations and visual edits drawn on the canvas are not transient UI overlays; they are compiled into native PDF graphic streams via `PdfModifierService`:
  - **Text Injections**: Native TrueType/Standard fonts embedded at exact normalized coordinates.
  - **Vector Drawings & Freehand Ink**: Multi-segment cubic Bezier path rendering (`graphics.drawPath`) preserving opacity and stroke width.
  - **Highlights & Underlines**: Blend-mode compliant rectangles (`graphics.drawRectangle`) with semi-transparent tinting.
  - **Atomic Save Safeguards**: Edits write to `.tmp` files first and flush before replacing the destination file to eliminate file corruption risks.

### 3.3 Page Organization Engine (`PdfPageService`)
- Provides lossless page-level tree mutations without raster degradation:
  - **Rotation**: 90°, 180°, and 270° clockwise and counter-clockwise orientation switching.
  - **Deletion**: Multi-index page pruning maintaining document stability.
  - **Duplication & Reordering**: Template-based page cloning and positional permutation.
  - **Split & Merge**: Multi-file concatenation and range-based document extraction.

### 3.4 Local Document Conversion Engine (`ConversionService`)
- 100% offline conversions without external cloud APIs or paid licenses:
  - **PDF to DOCX**: Extracts semantic text streams with `PdfTextExtractor`, generates standard OpenXML ZIP packages (`[Content_Types].xml`, `_rels/.rels`, `word/document.xml`), producing genuine Microsoft Word documents readable in Word 2013-2024 and Office 365.
  - **DOCX to PDF**: Parses OpenXML document structure and produces formatted multi-page PDFs.
  - **Images to PDF**: Decodes PNG/JPG/BMP formats, fits them to standard page geometries, and bundles them into single/multipage documents.
  - **PDF to TXT**: Clean UTF-8 plain text extraction.

### 3.5 Security, Signatures & Forms (`PdfSecurityService`, `SignatureService`, `FormService`)
- **Encryption**: Standard AES 128-bit PDF encryption with separate User and Owner passwords, and fine-grained permission flags (`print`, `copyContent`, `editAnnotations`, `fillFields`).
- **Signatures**: Vector signature capture to transparent 32-bit PNG bitmaps baked directly onto PDF page graphics.
- **Form Fields**: Real interactive form inspection and value filling for `PdfTextBoxField`, `PdfCheckBoxField`, `PdfComboBoxField`, and `PdfRadioButtonListField`.
- **Watermarking**: Anti-aliased diagonal/horizontal security watermarks stamped on every document page with controllable opacity and typography.

---

## 4. State Management & Undo/Redo Architecture

- **State Model**: Reactive `ChangeNotifier` state orchestrating tabs, active navigation, theme state, and file history.
- **Command Pattern**: `UndoRedoManager` tracks discrete `UndoableAction` objects:
  - `_AddAnnotationAction` / `_RemoveAnnotationAction` / `_UpdateAnnotationAction`
  - `_RotatePageAction` / `_DeletePageAction` / `_ReorderPageAction`
  - Supports full multi-level stack rollbacks (`Ctrl+Z`) and redos (`Ctrl+Y`).

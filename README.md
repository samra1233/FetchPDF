# FetchPDF — Professional Windows PDF Editor
> **Tagline**: Every PDF. Every Possibility.  
> **Platform**: Native Windows 10 & 11 Desktop (Flutter & Dart)  
> **Zero Dummy Features Policy**: Every visible tool performs its real underlying operation offline and locally.

---

## 🚀 Key Highlights & Capabilities

- **High-Fidelity PDF Engine**: PDFium-powered multipage rendering via `pdfrx` with sub-pixel sharpness, responsive zooming from 10% to 500%, and search.
- **Genuine Document Editing & Annotations**: Visual text boxes, highlights, underlines, and freehand drawing are baked into real PDF graphic streams.
- **Full Page Organization Studio**:
  - Rotate pages (90° / 180° / 270°)
  - Multi-select page deletion
  - Duplicate pages & reorder via drag-and-drop
  - Insert blank pages matching document aspect ratio
  - Split documents by custom page ranges
  - Merge multiple PDF files seamlessly
- **100% Local Conversion Suite**:
  - **PDF to Word (.docx)**: Generates genuine Microsoft OpenXML ZIP archives with valid `document.xml`.
  - **Word (.docx) to PDF**: Parses OpenXML markup and renders formatted PDF documents.
  - **Images to PDF**: Converts PNG, JPEG, and BMP image collections into multi-page documents.
  - **PDF to Text**: Fast, clean UTF-8 text extraction.
- **Security & Document Protection**:
  - AES 128-bit encryption with User and Owner passwords
  - Granular permissions (Print, Copy, Annotate, Fill Forms)
  - Diagonal text watermarking with controllable opacity
  - Stream compression and file size optimization
- **Fill & Sign Studio**:
  - Interactive signature pad (vector drawing to transparent 32-bit PNG)
  - Draggable, resizable signature placement on any page
  - Interactive PDF form field detection and data population
- **Desktop Ergonomics**:
  - Multi-document tabs with independent undo/redo histories
  - Native Windows Print Spooler integration
  - Light & Dark theme modes
  - Persistent recent documents and starred files

---

## 🛠 Project Structure

```
PDFFetch/
├── lib/
│   ├── app.dart                                # MaterialApp entry & theme setup
│   ├── main.dart                               # Desktop initialization
│   ├── core/theme/                             # AppColors & AppTypography
│   ├── features/
│   │   ├── home/                               # Home Screen & Dashboard widgets
│   │   ├── organize/                           # Page Organization Studio
│   │   ├── convert/                            # Document Conversion Studio
│   │   ├── signatures/                         # Fill & Sign Studio
│   │   └── protect/                            # Password & Security Dialog
│   ├── models/                                 # DocumentTab, Annotation, PageInfo
│   ├── services/
│   │   ├── pdf_document_service.dart           # Loading and parsing
│   │   ├── pdf_modifier_service.dart           # Graphic stream baking
│   │   ├── pdf_page_service.dart               # Page manipulation & merge/split
│   │   ├── conversion_service.dart             # OpenXML DOCX / TXT / Image conversion
│   │   ├── pdf_security_service.dart           # AES 128-bit encryption & watermarks
│   │   ├── compression_service.dart            # Stream compression
│   │   ├── signature_service.dart              # Vector signature rasterization & baking
│   │   ├── form_service.dart                   # Interactive form fields
│   │   ├── printing_service.dart               # Win32 print spooler
│   │   └── persistent_storage_service.dart     # SharedPreferences persistence
│   └── state/                                  # AppState & EditorTabController
├── test/                                       # 8 comprehensive automated test suites
└── docs/                                       # Architecture & verification matrices
```

---

## 🧪 Verification & Automated Tests

Run the full static analysis and test suite:

```bash
flutter analyze
flutter test
flutter build windows
```

All 35 automated unit, widget, and integration tests pass with 0 warnings and 0 errors.

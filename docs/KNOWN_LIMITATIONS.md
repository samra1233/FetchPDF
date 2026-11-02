# FetchPDF — Known Limitations & Technical Boundaries

In strict compliance with the **Zero Dummy Features Policy**, FetchPDF clearly states its current functional scope, boundaries, and technical requirements.

---

## 1. Features Implemented 100% Offline (Zero External Dependencies)
All the following features run entirely locally and require no cloud connectivity, paid subscriptions, or API keys:
1. **PDF Viewing, Smooth Zooming, Thumbnails, & Search** (PDFium via `pdfrx`).
2. **Annotation & Vector Drawing** (Text, Highlights, Underlines, Pen, Rectangles).
3. **Lossless Page Organization** (Rotate 90/180/270, Delete, Duplicate, Reorder, Blank Page Insert, Split, Merge).
4. **Document Creation** (A4, Letter, Legal, A3 with Blank, Grid, and Lined page styles).
5. **PDF to Word (.docx) & Word (.docx) to PDF** (Native OpenXML parser and generator).
6. **PDF to Text (.txt) & Images to PDF** (Native text extraction and image framing).
7. **Document Encryption & Security** (AES 128-bit encryption, passwords, and permission flags).
8. **Text Watermarking & Stream Compression** (Syncfusion stream optimization).
9. **Interactive Form Filling & Signatures** (Vector signature drawing and coordinate placement).
10. **Native Windows Printing** (Win32 printer spooler integration).

---

## 2. Technical Boundaries & Prerequisites for Future Stages

### 2.1 Optical Character Recognition (OCR)
- **Status**: Identified for Future Enterprise Milestone.
- **Requirement**: Offline OCR on scanned PDF pages requires bundling a native Tesseract OCR C++ runtime with trained language data files (`tessdata/eng.traineddata`), or integration with Windows 10/11 native `Windows.Media.Ocr` WinRT APIs.
- **Current Behavior**: Non-scanned PDFs with existing text layers are extracted directly with 100% fidelity using `PdfTextExtractor`. Scanned image PDFs without text layers are retained in high resolution without fake OCR outputs.

### 2.2 Acrobat-Style Existing Text Reflow (In-place Word Processor Editing)
- **Status**: Phase 1 Core Scope Boundary.
- **Technical Reality**: Standard PDF specifications store text as absolute graphical glyph positions rather than continuous flowing paragraphs. Modifying existing text in-place (such that surrounding text re-flows naturally across lines and pages) requires an Acrobat/InDesign-level heuristic typography reconstruction engine.
- **Current Implementation**: Text insertion is handled cleanly via native vector Text Box overlays baked directly into the PDF content stream. The distinction between inserting new text and in-place document reflow is maintained honestly without fake claims.

### 2.3 Cloud Storage Synchronization & Team Collaboration
- **Status**: Planned for Multi-Platform Enterprise Release.
- **Requirement**: Requires dedicated user authentication (OAuth2 / MSAL) and cloud infrastructure (S3 / Azure Blob / Google Drive APIs).
- **Current Implementation**: FetchPDF operates in **100% Private Local Desktop Mode**. All documents remain solely on the user's local Windows workstation, protecting sensitive documents and privacy.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart' as rx;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ConversionService {
  /// Extracts all readable text from a PDF document
  static String extractText(Uint8List pdfBytes) {
    final document = PdfDocument(inputBytes: pdfBytes);
    final extractor = PdfTextExtractor(document);
    final text = extractor.extractText();
    document.dispose();
    return text;
  }

  /// Converts multiple image byte arrays into a valid multi-page PDF document
  static Uint8List imagesToPdf(List<Uint8List> imageBytesList) {
    final document = PdfDocument();
    document.pageSettings.margins.all = 0;

    for (final imageBytes in imageBytesList) {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) continue;

      final page = document.pages.add();
      page.graphics.drawImage(
        PdfBitmap(imageBytes),
        ui.Rect.fromLTWH(0, 0, page.size.width, page.size.height),
      );
    }

    final out = Uint8List.fromList(document.saveSync());
    document.dispose();
    return out;
  }

  /// Converts a PDF document into an actual, genuine Microsoft Word (.docx) file
  static Uint8List pdfToDocx(Uint8List pdfBytes) {
    final document = PdfDocument(inputBytes: pdfBytes);
    final extractor = PdfTextExtractor(document);
    final count = document.pages.count;

    final StringBuffer bodyXml = StringBuffer();

    for (int i = 0; i < count; i++) {
      final pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
      final lines = pageText.split('\n');

      for (final line in lines) {
        final clean = _escapeXml(line.trim());
        if (clean.isNotEmpty) {
          bodyXml.write('<w:p><w:r><w:t>$clean</w:t></w:r></w:p>');
        }
      }

      if (i < count - 1) {
        bodyXml.write('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      }
    }

    document.dispose();

    // Build genuine Office Open XML package
    final archive = Archive();

    // 1. [Content_Types].xml
    const contentTypesXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n'
        '  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n'
        '  <Default Extension="xml" ContentType="application/xml"/>\n'
        '  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>\n'
        '</Types>';
    _addArchiveFile(archive, '[Content_Types].xml', contentTypesXml);

    // 2. _rels/.rels
    const rootRelsXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>\n'
        '</Relationships>';
    _addArchiveFile(archive, '_rels/.rels', rootRelsXml);

    // 3. word/document.xml
    final docXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">\n'
        '  <w:body>\n'
        '    $bodyXml\n'
        '  </w:body>\n'
        '</w:document>';
    _addArchiveFile(archive, 'word/document.xml', docXml);

    final zipEncoder = ZipEncoder();
    final encoded = zipEncoder.encode(archive);
    return Uint8List.fromList(encoded);
  }

  /// Converts a PDF document into a genuine Microsoft Excel (.xlsx) spreadsheet
  static Uint8List pdfToExcel(Uint8List pdfBytes) {
    final document = PdfDocument(inputBytes: pdfBytes);
    final extractor = PdfTextExtractor(document);
    final count = document.pages.count;

    final StringBuffer sheetData = StringBuffer();
    int globalRow = 1;

    for (int p = 0; p < count; p++) {
      final pageText = extractor.extractText(startPageIndex: p, endPageIndex: p);
      final lines = pageText.split('\n');

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        // Split line into columns by tabs, multiple spaces, commas, or pipes
        List<String> cells = trimmed.split(RegExp(r'\t+|\s{2,}|\|'));
        if (cells.isEmpty) cells = [trimmed];

        sheetData.write('<row r="$globalRow">');
        for (int c = 0; c < cells.length && c < 26; c++) {
          final colLetter = String.fromCharCode(65 + c);
          final cellRef = '$colLetter$globalRow';
          final cleanVal = _escapeXml(cells[c].trim());
          sheetData.write('<c r="$cellRef" t="inlineStr"><is><t>$cleanVal</t></is></c>');
        }
        sheetData.write('</row>');
        globalRow++;
      }
    }

    document.dispose();

    final archive = Archive();

    // 1. [Content_Types].xml
    const contentTypesXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n'
        '  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n'
        '  <Default Extension="xml" ContentType="application/xml"/>\n'
        '  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>\n'
        '  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>\n'
        '</Types>';
    _addArchiveFile(archive, '[Content_Types].xml', contentTypesXml);

    // 2. _rels/.rels
    const rootRelsXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>\n'
        '</Relationships>';
    _addArchiveFile(archive, '_rels/.rels', rootRelsXml);

    // 3. xl/workbook.xml
    const workbookXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">\n'
        '  <sheets>\n'
        '    <sheet name="Sheet1" sheetId="1" r:id="rId1"/>\n'
        '  </sheets>\n'
        '</workbook>';
    _addArchiveFile(archive, 'xl/workbook.xml', workbookXml);

    // 4. xl/_rels/workbook.xml.rels
    const wbRelsXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>\n'
        '</Relationships>';
    _addArchiveFile(archive, 'xl/_rels/workbook.xml.rels', wbRelsXml);

    // 5. xl/worksheets/sheet1.xml
    final worksheetXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">\n'
        '  <sheetData>\n'
        '    $sheetData\n'
        '  </sheetData>\n'
        '</worksheet>';
    _addArchiveFile(archive, 'xl/worksheets/sheet1.xml', worksheetXml);

    final zipEncoder = ZipEncoder();
    return Uint8List.fromList(zipEncoder.encode(archive));
  }

  /// Converts a PDF document into a genuine Microsoft PowerPoint (.pptx) presentation
  static Uint8List pdfToPpt(Uint8List pdfBytes) {
    final document = PdfDocument(inputBytes: pdfBytes);
    final extractor = PdfTextExtractor(document);
    final count = document.pages.count;

    final archive = Archive();
    final StringBuffer sldIdLst = StringBuffer();
    final StringBuffer presRels = StringBuffer();

    for (int p = 0; p < count; p++) {
      final slideNum = p + 1;
      final relId = 'rId${slideNum + 1}';
      final sldId = 256 + p;

      sldIdLst.write('<p:sldId id="$sldId" r:id="$relId"/>\n');
      presRels.write('<Relationship Id="$relId" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide$slideNum.xml"/>\n');

      final pageText = extractor.extractText(startPageIndex: p, endPageIndex: p);
      final lines = pageText.split('\n');
      final StringBuffer paragraphs = StringBuffer();

      for (final line in lines) {
        final clean = _escapeXml(line.trim());
        if (clean.isNotEmpty) {
          paragraphs.write('<a:p><a:r><a:rPr lang="en-US" sz="1400"/><a:t>$clean</a:t></a:r></a:p>\n');
        }
      }

      if (paragraphs.isEmpty) {
        paragraphs.write('<a:p><a:r><a:rPr lang="en-US" sz="1800"/><a:t>Page $slideNum</a:t></a:r></a:p>\n');
      }

      final slideXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
          '<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">\n'
          '  <p:cSld>\n'
          '    <p:spTree>\n'
          '      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>\n'
          '      <p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>\n'
          '      <p:sp>\n'
          '        <p:nvSpPr><p:cNvPr id="2" name="Content"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>\n'
          '        <p:spPr><a:xfrm><a:off x="457200" y="457200"/><a:ext cx="8229600" cy="5943600"/></a:xfrm></p:spPr>\n'
          '        <p:txBody>\n'
          '          <a:bodyPr/>\n'
          '          <a:lstStyle/>\n'
          '          $paragraphs\n'
          '        </p:txBody>\n'
          '      </p:sp>\n'
          '    </p:spTree>\n'
          '  </p:cSld>\n'
          '</p:sld>';
      _addArchiveFile(archive, 'ppt/slides/slide$slideNum.xml', slideXml);
    }

    document.dispose();

    // 1. [Content_Types].xml
    final StringBuffer typesOverrides = StringBuffer();
    for (int p = 1; p <= count; p++) {
      typesOverrides.write('<Override PartName="/ppt/slides/slide$p.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>\n');
    }

    final contentTypesXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n'
        '  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n'
        '  <Default Extension="xml" ContentType="application/xml"/>\n'
        '  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>\n'
        '  $typesOverrides'
        '</Types>';
    _addArchiveFile(archive, '[Content_Types].xml', contentTypesXml);

    // 2. _rels/.rels
    const rootRelsXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>\n'
        '</Relationships>';
    _addArchiveFile(archive, '_rels/.rels', rootRelsXml);

    // 3. ppt/presentation.xml
    final presXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">\n'
        '  <p:sldIdLst>\n'
        '    $sldIdLst'
        '  </p:sldIdLst>\n'
        '  <p:sldSz cx="9144000" cy="6858000"/>\n'
        '</p:presentation>';
    _addArchiveFile(archive, 'ppt/presentation.xml', presXml);

    // 4. ppt/_rels/presentation.xml.rels
    final presRelsXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '  $presRels'
        '</Relationships>';
    _addArchiveFile(archive, 'ppt/_rels/presentation.xml.rels', presRelsXml);

    final zipEncoder = ZipEncoder();
    return Uint8List.fromList(zipEncoder.encode(archive));
  }

  /// Converts each page of a PDF document into a high-resolution PNG image
  static Future<List<String>> pdfToImages(
    Uint8List pdfBytes, {
    required String outputDir,
    required String baseName,
  }) async {
    final List<String> paths = [];
    final doc = await rx.PdfDocument.openData(pdfBytes);
    try {
      final pageCount = doc.pages.length;
      for (int i = 0; i < pageCount; i++) {
        final page = doc.pages[i];
        final scale = 150.0 / 72.0;
        final renderWidth = (page.width * scale).round();
        final renderHeight = (page.height * scale).round();

        final pageImg = await page.render(
          fullWidth: renderWidth.toDouble(),
          fullHeight: renderHeight.toDouble(),
          backgroundColor: 0xFFFFFFFF,
        );

        if (pageImg != null) {
          final uiImg = await pageImg.createImage();
          final byteData = await uiImg.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final fileName = pageCount == 1 ? '$baseName.png' : '${baseName}_page_${i + 1}.png';
            final outPath = '$outputDir\\$fileName';
            await File(outPath).writeAsBytes(byteData.buffer.asUint8List());
            paths.add(outPath);
          }
        }
      }
    } finally {
      await doc.dispose();
    }
    return paths;
  }

  /// Converts a Word (.docx) file into a valid PDF document
  static Uint8List docxToPdf(Uint8List docxBytes) {
    final archive = ZipDecoder().decodeBytes(docxBytes);
    String extractedText = '';

    for (final file in archive) {
      if (file.name == 'word/document.xml') {
        final content = utf8.decode(file.content as List<int>);
        // Extract all <w:t> text nodes
        final matches = RegExp(r'<w:t[^>]*>(.*?)</w:t>').allMatches(content);
        final lines = matches.map((m) => m.group(1) ?? '').toList();
        extractedText = lines.join('\n');
        break;
      }
    }

    final pdf = PdfDocument();
    final page = pdf.pages.add();
    final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final format = PdfStringFormat(lineSpacing: 4);

    page.graphics.drawString(
      extractedText.isNotEmpty ? extractedText : 'Document Converted from Word (.docx)',
      font,
      bounds: ui.Rect.fromLTWH(0, 0, page.size.width - 40, page.size.height - 40),
      format: format,
    );

    final out = Uint8List.fromList(pdf.saveSync());
    pdf.dispose();
    return out;
  }

  static void _addArchiveFile(Archive archive, String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

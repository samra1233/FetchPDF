import 'dart:typed_data';
import 'package:flutter/material.dart';

enum AnnotationType {
  textBox,
  highlight,
  underline,
  strikethrough,
  drawing,
  line,
  arrow,
  rectangle,
  ellipse,
  stickyNote,
  stamp,
  image,
  existingText,
}

class EditorAnnotation {
  final String id;
  final int pageNumber; // 1-indexed
  final AnnotationType type;

  // Normalized coordinates (0.0 to 1.0 relative to page size) to ensure resolution & zoom independence
  double normalizedX;
  double normalizedY;
  double normalizedWidth;
  double normalizedHeight;

  // For drawing / ink annotations: list of normalized points (x, y) relative to page
  List<Offset> normalizedPoints;

  // Styling properties
  String text;
  double fontSize;
  Color color;
  Color? fillColor;
  double strokeWidth;
  double opacity;

  // Extended typography & metadata
  String fontFamily;
  bool isBold;
  bool isItalic;
  TextAlign alignment;
  String author;
  double rotation; // Degrees
  String stampText;
  Uint8List? imageBytes;

  EditorAnnotation({
    required this.id,
    required this.pageNumber,
    required this.type,
    this.normalizedX = 0,
    this.normalizedY = 0,
    this.normalizedWidth = 0,
    this.normalizedHeight = 0,
    List<Offset>? normalizedPoints,
    this.text = '',
    this.fontSize = 14.0,
    this.color = Colors.black,
    this.fillColor,
    this.strokeWidth = 2.0,
    this.opacity = 1.0,
    this.fontFamily = 'Segoe UI',
    this.isBold = false,
    this.isItalic = false,
    this.alignment = TextAlign.left,
    this.author = 'FetchPDF User',
    this.rotation = 0.0,
    this.stampText = 'APPROVED',
    this.imageBytes,
  }) : normalizedPoints = normalizedPoints ?? [];

  static const Object _sentinel = Object();

  EditorAnnotation copyWith({
    String? id,
    int? pageNumber,
    AnnotationType? type,
    double? normalizedX,
    double? normalizedY,
    double? normalizedWidth,
    double? normalizedHeight,
    List<Offset>? normalizedPoints,
    String? text,
    double? fontSize,
    Color? color,
    Object? fillColor = _sentinel,
    double? strokeWidth,
    double? opacity,
    String? fontFamily,
    bool? isBold,
    bool? isItalic,
    TextAlign? alignment,
    String? author,
    double? rotation,
    String? stampText,
    Uint8List? imageBytes,
  }) {
    return EditorAnnotation(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      type: type ?? this.type,
      normalizedX: normalizedX ?? this.normalizedX,
      normalizedY: normalizedY ?? this.normalizedY,
      normalizedWidth: normalizedWidth ?? this.normalizedWidth,
      normalizedHeight: normalizedHeight ?? this.normalizedHeight,
      normalizedPoints: normalizedPoints ?? List.from(this.normalizedPoints),
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      fillColor: identical(fillColor, _sentinel) ? this.fillColor : (fillColor as Color?),
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      fontFamily: fontFamily ?? this.fontFamily,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      alignment: alignment ?? this.alignment,
      author: author ?? this.author,
      rotation: rotation ?? this.rotation,
      stampText: stampText ?? this.stampText,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }

  Rect toActualRect(Size pageSize) {
    return Rect.fromLTWH(
      normalizedX * pageSize.width,
      normalizedY * pageSize.height,
      normalizedWidth * pageSize.width,
      normalizedHeight * pageSize.height,
    );
  }

  static EditorAnnotation createTextBox({
    required String id,
    required int pageNumber,
    required double normX,
    required double normY,
    required double normWidth,
    required double normHeight,
    required String text,
    double fontSize = 14.0,
    Color color = Colors.black,
    Color? fillColor,
    String fontFamily = 'Helvetica',
    bool isBold = false,
    bool isItalic = false,
    TextAlign alignment = TextAlign.left,
  }) {
    return EditorAnnotation(
      id: id,
      pageNumber: pageNumber,
      type: AnnotationType.textBox,
      normalizedX: normX,
      normalizedY: normY,
      normalizedWidth: normWidth,
      normalizedHeight: normHeight,
      text: text,
      fontSize: fontSize,
      color: color,
      fillColor: fillColor,
      fontFamily: fontFamily,
      isBold: isBold,
      isItalic: isItalic,
      alignment: alignment,
    );
  }

  static EditorAnnotation createHighlight({
    required String id,
    required int pageNumber,
    required double normX,
    required double normY,
    required double normWidth,
    required double normHeight,
    Color color = const Color(0x66FFEB3B),
  }) {
    return EditorAnnotation(
      id: id,
      pageNumber: pageNumber,
      type: AnnotationType.highlight,
      normalizedX: normX,
      normalizedY: normY,
      normalizedWidth: normWidth,
      normalizedHeight: normHeight,
      color: color,
      fillColor: color,
      opacity: 0.5,
    );
  }

  static EditorAnnotation createUnderline({
    required String id,
    required int pageNumber,
    required double normX,
    required double normY,
    required double normWidth,
    required double normHeight,
    Color color = const Color(0xFFE53935),
    double strokeWidth = 2.0,
  }) {
    return EditorAnnotation(
      id: id,
      pageNumber: pageNumber,
      type: AnnotationType.underline,
      normalizedX: normX,
      normalizedY: normY,
      normalizedWidth: normWidth,
      normalizedHeight: normHeight,
      color: color,
      strokeWidth: strokeWidth,
    );
  }

  static EditorAnnotation createStrikethrough({
    required String id,
    required int pageNumber,
    required double normX,
    required double normY,
    required double normWidth,
    required double normHeight,
    Color color = const Color(0xFFE53935),
    double strokeWidth = 2.0,
  }) {
    return EditorAnnotation(
      id: id,
      pageNumber: pageNumber,
      type: AnnotationType.strikethrough,
      normalizedX: normX,
      normalizedY: normY,
      normalizedWidth: normWidth,
      normalizedHeight: normHeight,
      color: color,
      strokeWidth: strokeWidth,
    );
  }

  static EditorAnnotation createDrawing({
    required String id,
    required int pageNumber,
    required List<Offset> normalizedPoints,
    Color color = const Color(0xFF1E88E5),
    double strokeWidth = 3.0,
  }) {
    return EditorAnnotation(
      id: id,
      pageNumber: pageNumber,
      type: AnnotationType.drawing,
      normalizedPoints: normalizedPoints,
      color: color,
      strokeWidth: strokeWidth,
    );
  }

  static EditorAnnotation createLine({
    required String id,
    required int pageNumber,
    required double normX,
    required double normY,
    required double normWidth,
    required double normHeight,
    Color color = const Color(0xFF1E88E5),
    double strokeWidth = 2.0,
  }) {
    return EditorAnnotation(
      id: id,
      pageNumber: pageNumber,
      type: AnnotationType.line,
      normalizedX: normX,
      normalizedY: normY,
      normalizedWidth: normWidth,
      normalizedHeight: normHeight,
      color: color,
      strokeWidth: strokeWidth,
    );
  }

  static EditorAnnotation createArrow({
    required String id,
    required int pageNumber,
    required double normX,
    required double normY,
    required double normWidth,
    required double normHeight,
    Color color = const Color(0xFF1E88E5),
    double strokeWidth = 2.0,
  }) {
    return EditorAnnotation(
      id: id,
      pageNumber: pageNumber,
      type: AnnotationType.arrow,
      normalizedX: normX,
      normalizedY: normY,
      normalizedWidth: normWidth,
      normalizedHeight: normHeight,
      color: color,
      strokeWidth: strokeWidth,
    );
  }

  static EditorAnnotation createRectangle({
    required String id,
    required int pageNumber,
    required double normX,
    required double normY,
    required double normWidth,
    required double normHeight,
    Color color = const Color(0xFF43A047),
    Color? fillColor,
    double strokeWidth = 2.0,
  }) {
    return EditorAnnotation(
      id: id,
      pageNumber: pageNumber,
      type: AnnotationType.rectangle,
      normalizedX: normX,
      normalizedY: normY,
      normalizedWidth: normWidth,
      normalizedHeight: normHeight,
      color: color,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
    );
  }

  static EditorAnnotation createEllipse({
    required String id,
    required int pageNumber,
    required double normX,
    required double normY,
    required double normWidth,
    required double normHeight,
    Color color = const Color(0xFF43A047),
    Color? fillColor,
    double strokeWidth = 2.0,
  }) {
    return EditorAnnotation(
      id: id,
      pageNumber: pageNumber,
      type: AnnotationType.ellipse,
      normalizedX: normX,
      normalizedY: normY,
      normalizedWidth: normWidth,
      normalizedHeight: normHeight,
      color: color,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
    );
  }

  static EditorAnnotation createStickyNote({
    required String id,
    required int pageNumber,
    required double normX,
    required double normY,
    required String text,
    Color color = const Color(0xFFF59E0B),
    String author = 'FetchPDF User',
  }) {
    return EditorAnnotation(
      id: id,
      pageNumber: pageNumber,
      type: AnnotationType.stickyNote,
      normalizedX: normX,
      normalizedY: normY,
      normalizedWidth: 0.05,
      normalizedHeight: 0.05,
      text: text,
      color: color,
      author: author,
    );
  }

  static EditorAnnotation createStamp({
    required String id,
    required int pageNumber,
    required double normX,
    required double normY,
    double normWidth = 0.25,
    double normHeight = 0.07,
    required String stampText,
    Color color = const Color(0xFF10B981),
  }) {
    return EditorAnnotation(
      id: id,
      pageNumber: pageNumber,
      type: AnnotationType.stamp,
      normalizedX: normX,
      normalizedY: normY,
      normalizedWidth: normWidth,
      normalizedHeight: normHeight,
      stampText: stampText,
      color: color,
      strokeWidth: 2.5,
    );
  }

  static EditorAnnotation createImage({
    required String id,
    required int pageNumber,
    required double normX,
    required double normY,
    required double normWidth,
    required double normHeight,
    required Uint8List imageBytes,
    double opacity = 1.0,
    double rotation = 0.0,
  }) {
    return EditorAnnotation(
      id: id,
      pageNumber: pageNumber,
      type: AnnotationType.image,
      normalizedX: normX,
      normalizedY: normY,
      normalizedWidth: normWidth,
      normalizedHeight: normHeight,
      imageBytes: imageBytes,
      opacity: opacity,
      rotation: rotation,
    );
  }
}

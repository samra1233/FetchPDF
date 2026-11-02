import 'dart:ui';

class PageInfo {
  final int pageNumber; // 1-indexed
  final Size sizeInPoints;
  final int rotationAngle; // 0, 90, 180, 270

  const PageInfo({
    required this.pageNumber,
    required this.sizeInPoints,
    required this.rotationAngle,
  });

  double get widthInInches => sizeInPoints.width / 72.0;
  double get heightInInches => sizeInPoints.height / 72.0;

  double get widthInMm => widthInInches * 25.4;
  double get heightInMm => heightInInches * 25.4;

  String get standardSizeName {
    final w = sizeInPoints.width;
    final h = sizeInPoints.height;
    if ((w - 612).abs() < 5 && (h - 792).abs() < 5) return 'US Letter (8.5 × 11 in)';
    if ((w - 595).abs() < 5 && (h - 842).abs() < 5) return 'A4 (210 × 297 mm)';
    if ((w - 612).abs() < 5 && (h - 1008).abs() < 5) return 'US Legal (8.5 × 14 in)';
    if ((w - 842).abs() < 5 && (h - 1191).abs() < 5) return 'A3 (297 × 420 mm)';
    return '${widthInInches.toStringAsFixed(1)} × ${heightInInches.toStringAsFixed(1)} in';
  }

  String get orientation => sizeInPoints.width > sizeInPoints.height ? 'Landscape' : 'Portrait';

  PageInfo copyWith({
    int? pageNumber,
    Size? sizeInPoints,
    int? rotationAngle,
  }) {
    return PageInfo(
      pageNumber: pageNumber ?? this.pageNumber,
      sizeInPoints: sizeInPoints ?? this.sizeInPoints,
      rotationAngle: rotationAngle ?? this.rotationAngle,
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';

class FetchPdfLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool showShadow;

  const FetchPdfLogo({
    this.size = 32.0,
    this.borderRadius = 8.0,
    this.showShadow = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Image.asset(
      'assets/icons/app_icon.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        final file = File('assets/icons/app_icon.png');
        if (file.existsSync()) {
          return Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, err, stack) => _fallbackWidget(),
          );
        }
        return _fallbackWidget();
      },
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: const Color(0xFFEF4444).withAlpha(50),
                  blurRadius: size * 0.25,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      ),
    );
  }

  Widget _fallbackWidget() {
    return Container(
      color: const Color(0xFFEF4444),
      child: Center(
        child: Icon(
          Icons.pets_rounded,
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }
}

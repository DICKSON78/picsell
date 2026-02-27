import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Burns product caption as a clean overlay onto [photo].
///
/// Caption is positioned at the **top-left** of the image.
/// Text is white with a strong black shadow — readable on any background
/// without needing a gradient or semi-transparent overlay.
/// Returns a new [File] with the caption embedded.
Future<File> addCaptionWatermark(
  File photo, {
  required String productName,
  required String price,
  String seller = '',
  String size = '',
}) async {
  // Decode source image
  final bytes = await photo.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;

  final w = image.width.toDouble();
  final h = image.height.toDouble();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));

  // Draw original image
  canvas.drawImage(image, Offset.zero, Paint());

  final hasCaption = productName.isNotEmpty ||
      price.isNotEmpty ||
      seller.isNotEmpty ||
      size.isNotEmpty;

  if (hasCaption) {
    final padding = w * 0.045;
    // Unified font size — all lines equally large and readable
    final fontSize = (w * 0.058).clamp(22.0, 60.0);

    // Build lines top → bottom order
    final lines = <_CaptionLine>[];

    if (productName.isNotEmpty) {
      lines.add(_CaptionLine(
        text: productName,
        fontSize: fontSize,
        weight: FontWeight.bold,
        color: Colors.white,
      ));
    }
    if (price.isNotEmpty) {
      lines.add(_CaptionLine(
        // price already includes currency + /= from caller e.g. "100,000/=TZS"
        text: price,
        fontSize: fontSize,
        weight: FontWeight.w700,
        color: Colors.white,
      ));
    }
    if (seller.isNotEmpty) {
      lines.add(_CaptionLine(
        text: seller,
        fontSize: fontSize,
        weight: FontWeight.w600,
        color: Colors.white,
      ));
    }
    if (size.isNotEmpty) {
      lines.add(_CaptionLine(
        text: 'Size: $size',
        fontSize: fontSize,
        weight: FontWeight.w600,
        color: Colors.white,
      ));
    }

    // Build paragraphs
    final paragraphs = lines
        .map((l) => _buildParagraph(
              l.text,
              l.fontSize,
              l.weight,
              l.color,
              w - padding * 2,
            ))
        .toList();

    final lineSpacing = padding * 0.35;

    // Draw paragraphs top-down from the top-left corner
    double currentY = padding;
    for (int i = 0; i < paragraphs.length; i++) {
      final p = paragraphs[i];
      canvas.drawParagraph(p, Offset(padding, currentY));
      currentY += p.height;
      if (i < paragraphs.length - 1) currentY += lineSpacing;
    }
  }

  // Export to PNG
  final picture = recorder.endRecording();
  final resultImage = await picture.toImage(w.toInt(), h.toInt());
  final byteData = await resultImage.toByteData(format: ui.ImageByteFormat.png);
  final resultBytes = byteData!.buffer.asUint8List();

  final tempDir = await getTemporaryDirectory();
  final outFile = File(
    '${tempDir.path}/picha_shared_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await outFile.writeAsBytes(resultBytes);
  return outFile;
}

class _CaptionLine {
  final String text;
  final double fontSize;
  final FontWeight weight;
  final Color color;
  const _CaptionLine({
    required this.text,
    required this.fontSize,
    required this.weight,
    required this.color,
  });
}

ui.Paragraph _buildParagraph(
  String text,
  double fontSize,
  FontWeight weight,
  Color color,
  double maxWidth,
) {
  final builder = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    ),
  )
    ..pushStyle(ui.TextStyle(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      shadows: [
        // Strong black outline shadow — works on ANY background
        ui.Shadow(color: Colors.black.withAlpha(220), blurRadius: 4,  offset: const Offset( 1,  1)),
        ui.Shadow(color: Colors.black.withAlpha(220), blurRadius: 4,  offset: const Offset(-1,  1)),
        ui.Shadow(color: Colors.black.withAlpha(220), blurRadius: 4,  offset: const Offset( 1, -1)),
        ui.Shadow(color: Colors.black.withAlpha(220), blurRadius: 4,  offset: const Offset(-1, -1)),
        // Soft diffuse halo for extra readability
        ui.Shadow(color: Colors.black.withAlpha(160), blurRadius: 12, offset: Offset.zero),
      ],
    ))
    ..addText(text);
  final paragraph = builder.build();
  paragraph.layout(ui.ParagraphConstraints(width: maxWidth.clamp(1, double.infinity)));
  return paragraph;
}

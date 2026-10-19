// Genera assets/images/splash_android12.png: lienzo 1152x1152 con el logo
// centrado y contenido dentro del círculo seguro de 768 px
// (2/3 del lienzo), que es la zona visible tras el enmascaramiento circular
// que Android 12+ aplica al icono del splash.
//
// Ejecutar: dart run tool/gen_splash12.dart
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

const String sourcePath = 'assets/images/logo_512_blanco.png';
const String outputPath = 'assets/images/splash_android12.png';

const int canvasSize = 1152; // Lienzo recomendado por Android 12+
const int safeCircle = 768; // Diámetro seguro (2/3 del lienzo)
const double safetyMargin = 0.98; // Deja un 2% de holgura

void main() {
  final img.Image? source =
      img.decodePng(File(sourcePath).readAsBytesSync());
  if (source == null) {
    stderr.writeln('No se pudo decodificar $sourcePath');
    exit(1);
  }

  // Escala para que la diagonal del contenido quepa en el círculo seguro.
  final double diagonal =
      sqrt(source.width * source.width + source.height * source.height);
  final double scale =
      (safeCircle * safetyMargin) / diagonal;

  final int w = (source.width * scale).round();
  final int h = (source.height * scale).round();

  final img.Image resized = img.copyResize(
    source,
    width: w,
    height: h,
    interpolation: img.Interpolation.cubic,
  );

  final img.Image canvas =
      img.Image(width: canvasSize, height: canvasSize, numChannels: 4);
  // Lienzo transparente por defecto; el fondo lo aporta el tema (#1565C0).
  img.compositeImage(
    canvas,
    resized,
    dstX: ((canvasSize - w) / 2).round(),
    dstY: ((canvasSize - h) / 2).round(),
  );

  File(outputPath).writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln('Generado $outputPath (${canvasSize}x$canvasSize), '
      'logo $w x $h (diagonal ${(sqrt(w * w + h * h)).toStringAsFixed(0)} '
      'de $safeCircle px seguros)');
}

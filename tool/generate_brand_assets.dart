import 'dart:io';

import 'package:image/image.dart' as image;

void main() {
  const markPath = 'assets/branding/khmerstay_mark.png';
  const splashPath = 'assets/branding/splash_logo.png';
  const iconPath = 'assets/branding/app_icon.png';

  final mark = image.decodePng(File(markPath).readAsBytesSync());
  if (mark == null) {
    throw StateError('Could not decode $markPath');
  }

  // Preserve the generated silhouette while enforcing the exact brand gold.
  for (final pixel in mark) {
    final alpha = pixel.a.toInt();
    pixel
      ..r = 0xB8
      ..g = 0x8A
      ..b = 0x44
      ..a = alpha < 8 ? 0 : alpha;
  }

  final encodedMark = image.encodePng(mark);
  File(markPath).writeAsBytesSync(encodedMark);
  File(splashPath).writeAsBytesSync(encodedMark);

  final icon = image.Image(width: 1024, height: 1024, numChannels: 4);
  image.fill(icon, color: image.ColorRgba8(0x2B, 0x21, 0x18, 0xFF));
  final resizedMark = image.copyResize(
    mark,
    width: 1024,
    height: 1024,
    interpolation: image.Interpolation.cubic,
  );
  image.compositeImage(icon, resizedMark);
  File(iconPath).writeAsBytesSync(image.encodePng(icon));
}

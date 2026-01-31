import 'package:flutter/material.dart';

Paint pixelPaint({double opacity = 1.0}) {
  return Paint()
    ..color = Color.fromRGBO(255, 255, 255, opacity)
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;
}

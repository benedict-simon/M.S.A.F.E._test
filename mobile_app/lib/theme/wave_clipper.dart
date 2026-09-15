import 'package:flutter/material.dart';

class WaveHeaderClipper extends CustomClipper<Path> {
  const WaveHeaderClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..lineTo(0, h - 34)
      ..quadraticBezierTo(w * 0.24, h, w * 0.5, h - 24)
      ..quadraticBezierTo(w * 0.76, h - 50, w, h - 12)
      ..lineTo(w, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class CardWaveTopClipper extends CustomClipper<Path> {
  const CardWaveTopClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    return Path()
      ..moveTo(0, 34)
      ..quadraticBezierTo(w * 0.24, 0, w * 0.5, 24)
      ..quadraticBezierTo(w * 0.76, 50, w, 12)
      ..lineTo(w, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

const double waveMaxCutDepth = 50;

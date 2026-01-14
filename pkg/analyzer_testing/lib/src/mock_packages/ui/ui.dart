// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

/// The set of compilation units that make up the mock 'ui' package.
final List<MockLibraryUnit> units = [_uiLibrary];

final _uiLibrary = MockLibraryUnit('lib/ui.dart', r'''
library dart.ui;

class Radius {
  static const Radius zero = Radius.circular(0.0);

  final double x;

  final double y;

  const Radius.circular(double radius) : this.elliptical(radius, radius);

  const Radius.elliptical(this.x, this.y);
}

class Size {
  final double width;

  final double height;

  const Size(this.width, this.height);
}

enum BlendMode {
  clear,
  src,
  dst,
  srcOver,
  dstOver,
  srcIn,
  dstIn,
  srcOut,
  dstOut,
  srcATop,
  dstATop,
  xor,
  plus,
  modulate,
  screen,
  overlay,
  darken,
  lighten,
  colorDodge,
  colorBurn,
  hardLight,
  softLight,
  difference,
  exclusion,
  multiply,
  hue,
  saturation,
  color,
  luminosity,
}

class Color {
  final double a;

  final double r;

  final double g;

  final double b;

  final ColorSpace colorSpace;

  const Color(int value)
    : this._fromARGBC(
        value >> 24,
        value >> 16,
        value >> 8,
        value,
        ColorSpace.sRGB,
      );

  const Color.from({
    required double alpha,
    required double red,
    required double green,
    required double blue,
    this.colorSpace = ColorSpace.sRGB,
  }) : a = alpha,
       r = red,
       g = green,
       b = blue;

  const Color.fromARGB(int a, int r, int g, int b)
    : this._fromARGBC(a, r, g, b, ColorSpace.sRGB);

  const Color.fromRGBO(int r, int g, int b, double opacity)
    : this._fromRGBOC(r, g, b, opacity, ColorSpace.sRGB);

  const Color._fromARGBC(
    int alpha,
    int red,
    int green,
    int blue,
    ColorSpace colorSpace,
  ) : this._fromRGBOC(red, green, blue, (alpha & 0xff) / 255, colorSpace);

  const Color._fromRGBOC(int r, int g, int b, double opacity, this.colorSpace)
    : a = opacity,
      r = (r & 0xff) / 255,
      g = (g & 0xff) / 255,
      b = (b & 0xff) / 255;

  @Deprecated('Use (*.a * 255.0).round() & 0xff')
  int get alpha => throw 0;

  @Deprecated('Use (*.b * 255.0).round() & 0xff')
  int get blue => throw 0;

  @Deprecated('Use (*.g * 255.0).round() & 0xff')
  int get green => throw 0;

  @override
  int get hashCode => throw 0;

  @Deprecated('Use .a.')
  double get opacity => throw 0;

  @Deprecated('Use (*.r * 255.0).round() & 0xff')
  int get red => throw 0;

  @Deprecated(
    'Use component accessors like .r or .g, or toARGB32 for an explicit conversion',
  )
  int get value => throw 0;

  @override
  bool operator ==(Object other) => throw 0;

  @override
  String toString() => throw 0;

  Color withAlpha(int a) => throw 0;

  Color withBlue(int b) => throw 0;

  Color withGreen(int g) => throw 0;

  @Deprecated('Use .withValues() to avoid precision loss.')
  Color withOpacity(double opacity) => throw 0;

  Color withRed(int r) => throw 0;

  Color withValues({
    double? alpha,
    double? red,
    double? green,
    double? blue,
    ColorSpace? colorSpace,
  }) => throw 0;

  static int _floatToInt8(double x) => throw 0;
}

enum FontStyle { normal, italic }

class FontWeight {
  static const FontWeight w100 = FontWeight._(0, 100);

  static const FontWeight w200 = FontWeight._(1, 200);

  static const FontWeight w300 = FontWeight._(2, 300);

  static const FontWeight w400 = FontWeight._(3, 400);

  static const FontWeight w500 = FontWeight._(4, 500);

  static const FontWeight w600 = FontWeight._(5, 600);

  static const FontWeight w700 = FontWeight._(6, 700);

  static const FontWeight w800 = FontWeight._(7, 800);

  static const FontWeight w900 = FontWeight._(8, 900);

  static const FontWeight normal = w400;

  static const FontWeight bold = w700;

  static const List<FontWeight> values = <FontWeight>[
    w100,
    w200,
    w300,
    w400,
    w500,
    w600,
    w700,
    w800,
    w900,
  ];

  final int index;

  const FontWeight._(this.index, int value);

  @override
  String toString() => throw 0;
}

enum TextAlign { left, right, center, justify, start, end }

enum TextBaseline { alphabetic, ideographic }

enum TextDirection { rtl, ltr }

typedef VoidCallback = void Function();
''');

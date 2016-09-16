// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utility library for creating web colors.

library sourcemaps.colors;

/// A web color.
abstract class Color {
  /// The css code for the color.
  String get toCss;
}

/// A web color defined as RGB.
class RGB implements Color {
  final double r;
  final double g;
  final double b;

  /// Creates a color defined by the amount of red [r], green [g], and blue [b]
  /// all in range 0..1.
  const RGB(this.r, this.g, this.b);

  String get toCss {
    StringBuffer sb = new StringBuffer();
    sb.write('#');

    void writeHex(double value) {
      int i = (value * 255.0).round();
      if (i < 16) {
        sb.write('0');
      }
      sb.write(i.toRadixString(16));
    }

    writeHex(r);
    writeHex(g);
    writeHex(b);

    return sb.toString();
  }

  String toString() => 'rgb($r,$g,$b)';
}

class RGBA extends RGB {
  final double a;

  const RGBA(double r, double g, double b, this.a) : super(r, g, b);

  String get toCss {
    StringBuffer sb = new StringBuffer();

    void writeInt(double value) {
      int i = (value * 255.0).round();
      if (i < 16) {
        sb.write('0');
      }
      sb.write(i);
    }

    sb.write('rgba(');
    writeInt(r);
    sb.write(', ');
    writeInt(g);
    sb.write(', ');
    writeInt(b);
    sb.write(', ');
    sb.write(a);
    sb.write(')');

    return sb.toString();
  }
}

/// A web color defined as HSV.
class HSV implements Color {
  final double h;
  final double s;
  final double v;

  /// Creates a color defined by the hue [h] in range 0..360 (360 excluded),
  /// saturation [s] in range 0..1, and value [v] in range 0..1.
  const HSV(this.h, this.s, this.v);

  String get toCss => toRGB(this).toCss;

  static RGB toRGB(HSV hsv) {
    double h = hsv.h;
    double s = hsv.s;
    double v = hsv.v;
    if (s == 0.0) {
      // Grey.
      return new RGB(v, v, v);
    }
    h /= 60.0; // Sector 0 to 5.
    int i = h.floor();
    double f = h - i; // Factorial part of [h].
    double p = v * (1.0 - s);
    double q = v * (1.0 - s * f);
    double t = v * (1.0 - s * (1.0 - f));
    switch (i) {
      case 0:
        return new RGB(v, t, p);
      case 1:
        return new RGB(q, v, p);
      case 2:
        return new RGB(p, v, t);
      case 3:
        return new RGB(p, q, v);
      case 4:
        return new RGB(t, p, v);
      default: // case 5:
        return new RGB(v, p, q);
    }
  }

  String toString() => 'hsv($h,$s,$v)';
}

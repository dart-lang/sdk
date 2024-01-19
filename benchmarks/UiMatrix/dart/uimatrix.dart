// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Taken from https://github.com/yjbanov/uimatrix/blob/fd7244e09febe7e1f0dc8967b1e301adf2ebb833/lib/uimatrix.dart

library uimatrix;

import 'package:meta/meta.dart';

// Matrix shapes:

// Identity:
//   1  0  0  0
//   0  1  0  0
//   0  0  1  0
//   0  0  0  1

// Translation 2D:
//   1  0  0  x
//   0  1  0  y
//   0  0  1  0
//   0  0  0  1

// General 2D:
//   sx k1 0  x
//   k2 sy 0  y
//   0  0  1  0
//   0  0  0  1

// Most general case:
//   m00 m01 m02 m03
//   m10 m11 m12 m13
//   m20 m21 m22 m23
//   m30 m31 m32 m33
//
//   sx k1 m8 x
//   k2 sy m9 y
//   m2 m6 sz z
//   p1 p2 p3 w

//     class UiMatrix {
//       m00 (scaleX)
//       m11 (scaleY)
//       m03 (dx)
//       m13 (dy)
//       _MatrixExtension? rest
//     }
//
//     class _MatrixExtension {
//           m01 m02
//       m10     m12
//       m20 m21 m22 m23
//       m30 m31 m32 m33
//     }

@immutable
final class UiMatrix {
  /// The identity transform.
  ///
  /// Has the following shape:
  ///
  ///     1  0  0  0
  ///     0  1  0  0
  ///     0  0  1  0
  ///     0  0  0  1
  static const UiMatrix identity = UiMatrix._(m00: 1, m11: 1, m03: 0, m13: 0);

  /// Instantiates a 2D translation matrix.
  ///
  /// A 2D translation matrix has the following shape:
  ///
  ///     1  0  0  dx
  ///     0  1  0  dy
  ///     0  0  1  0
  ///     0  0  0  1
  ///
  /// If both `x` and `y` are zero, returns the [identity] constant.
  static UiMatrix translation2d({required double dx, required double dy}) {
    if (dx == 0 && dy == 0) {
      return identity;
    }
    return UiMatrix._(m00: 1, m11: 1, m03: dx, m13: dy);
  }

  /// Instantiates a 2D transformation that includes scaling and translation.
  ///
  /// A simple 2D transformation has the following shape:
  ///
  ///     sx 0  0  dx
  ///     0  sy 0  dy
  ///     0  0  1  0
  ///     0  0  0  1
  ///
  /// If both `x` and `y` are zero, returns the [identity] constant.
  static UiMatrix simple2d({
    required double scaleX,
    required double scaleY,
    required double dx,
    required double dy,
  }) {
    if (scaleX == 1 && scaleY == 1) {
      return UiMatrix.translation2d(dx: dx, dy: dy);
    }
    return UiMatrix._(m00: scaleX, m11: scaleY, m03: dx, m13: dy);
  }

  /// Instantiates a general 2D transform matrix.
  ///
  /// A general 2D transform matrix has the following shape:
  ///
  ///     sx k1 0  dx
  ///     k2 sy 0  dy
  ///     0  0  1  0
  ///     0  0  0  1
  ///
  /// If the values of `sx` and `sy` and equal to 1, and the values of `k1` and
  /// `k2` are equal to zero, this matrix returns the equivalent of invoking
  /// [UiMatrix.translation2d]. If, in addition, the values of `x` and `y` are
  /// zero, returns the [identity] constant.
  static UiMatrix transform2d({
    required double scaleX,
    required double scaleY,
    required double dx,
    required double dy,
    required double k1,
    required double k2,
  }) {
    if (k1 == 0 && k2 == 0) {
      return UiMatrix.simple2d(scaleX: scaleX, scaleY: scaleY, dx: dx, dy: dy);
    }

    return UiMatrix._(
      m00: scaleX,
      m11: scaleY,
      m03: dx,
      m13: dy,
      rest: _MatrixExtension(
        m01: k1,
        m02: 0,
        m10: k2,
        m12: 0,
        m20: 0,
        m21: 0,
        m22: 1,
        m23: 0,
        m30: 0,
        m31: 0,
        m32: 0,
        m33: 1,
      ),
    );
  }

  /// Instantiates a general 3D transform matrix from its components.
  ///
  /// A general 3D transform matrix has the following shape:
  ///
  ///     m00 m01 m02 m03
  ///     m10 m11 m12 m13
  ///     m20 m21 m22 m23
  ///     m30 m31 m32 m33
  ///
  /// If values of `sx`, `sy`, `k1`, and `k2` are all zero, this matrix returns
  /// the equivalent of invoking [UiMatrix.translation2d]. If, in addition, the
  /// values of `x` and `y` are zero, returns the [identity] constant.
  static UiMatrix transform({
    required double m00,
    required double m01,
    required double m02,
    required double m03,
    required double m10,
    required double m11,
    required double m12,
    required double m13,
    required double m20,
    required double m21,
    required double m22,
    required double m23,
    required double m30,
    required double m31,
    required double m32,
    required double m33,
  }) {
    // Lower to simplae 2D if possible to avoid allocation of extension.
    //     *  0  0  *
    //     0  *  0  *
    //     0  0  1  0
    //     0  0  0  1
    if (m01 == 0 &&
        m02 == 0 &&
        m10 == 0 &&
        m12 == 0 &&
        m20 == 0 &&
        m21 == 0 &&
        m22 == 1 &&
        m23 == 0 &&
        m30 == 0 &&
        m31 == 0 &&
        m32 == 0 &&
        m33 == 1) {
      return UiMatrix.simple2d(
        scaleX: m00,
        scaleY: m11,
        dx: m03,
        dy: m13,
      );
    }

    return UiMatrix._(
      m00: m00,
      m11: m11,
      m03: m03,
      m13: m13,
      rest: _MatrixExtension(
        m01: m01,
        m02: m02,
        m10: m10,
        m12: m12,
        m20: m20,
        m21: m21,
        m22: m22,
        m23: m23,
        m30: m30,
        m31: m31,
        m32: m32,
        m33: m33,
      ),
    );
  }

  const UiMatrix._({
    required double m00,
    required double m11,
    required double m03,
    required double m13,
    _MatrixExtension? rest,
  })  : _m00 = m00,
        _m11 = m11,
        _m03 = m03,
        _m13 = m13,
        _rest = rest;

  final double _m00;
  final double _m11;
  final double _m03;
  final double _m13;
  final _MatrixExtension? _rest;

  double get scaleX => _m00;
  double get scaleY => _m11;
  double get dx => _m03;
  double get dy => _m13;

  /// Computes a matrix equal to the negated `this`.
  UiMatrix operator -() {
    return UiMatrix._(
      m00: -_m00,
      m11: -_m11,
      m03: -_m03,
      m13: -_m13,
      rest: _rest?._negate(),
    );
  }

  /// Computes a matrix equal to the sum of `this` + `other`.
  UiMatrix operator +(UiMatrix other) {
    final _MatrixExtension? selfRest = _rest;
    final _MatrixExtension? otherRest = other._rest;

    // TODO: possible specializations
    //   * We're already paying the branch cost of null checking extensions. If
    //     one of extensions is null, extension addition can be avoided for free.
    //   * The final result may be simpler than the inputs and can be lowered to
    //     enable future specializations.
    _MatrixExtension? rest;
    if (otherRest != null || selfRest != null) {
      rest = (selfRest ?? _MatrixExtension._identityExtension) +
          (otherRest ?? _MatrixExtension._identityExtension);
    }

    return UiMatrix._(
      m00: _m00 + other._m00,
      m11: _m11 + other._m11,
      m03: _m03 + other._m03,
      m13: _m13 + other._m13,
      rest: rest,
    );
  }

  /// Computes a matrix equal to the product `this` * `other`.
  UiMatrix operator *(UiMatrix other) {
    if (identical(other, UiMatrix.identity)) {
      return this;
    }

    if (identical(this, UiMatrix.identity)) {
      return other;
    }

    final _MatrixExtension? selfRest = _rest;
    final _MatrixExtension? otherRest = other._rest;

    if (otherRest == null) {
      final double n00 = other._m00;
      final double n11 = other._m11;
      final double n03 = other._m03;
      final double n13 = other._m13;
      if (selfRest == null) {
        return UiMatrix._(
          m00: _m00 * n00,
          m11: _m11 * n11,
          m03: _m03 + _m00 * n03,
          m13: _m13 + _m11 * n13,
        );
      } else {
        return _generalMultiply(
            this, selfRest, other, _MatrixExtension._identityExtension);
      }
    } else {
      if (selfRest == null) {
        return _generalMultiply(
            this, _MatrixExtension._identityExtension, other, otherRest);
      } else {
        return _generalMultiply(this, selfRest, other, otherRest);
      }
    }
  }

  /// Computes the determinant of this matrix.
  double determinant() {
    final _MatrixExtension? rest = _rest;
    if (rest == null) {
      return _m00 * _m11;
    } else {
      return _generalDeterminant(this, rest);
    }
  }

  /// Inverts this matrix.
  ///
  /// If this matrix cannot be inverted, i.e. its [determinant] is zero, returns
  /// null.
  UiMatrix? invert() {
    if (identical(this, UiMatrix.identity)) {
      return this;
    }

    final _MatrixExtension? rest = _rest;
    if (rest == null) {
      final double a00 = _m00;
      final double a11 = _m11;
      final double a30 = _m03;
      final double a31 = _m13;
      final double det = a00 * a11;

      if (det == 0.0) {
        return null;
      }
      final double invDet = 1.0 / det;

      return UiMatrix.simple2d(
        scaleX: a11 * invDet,
        scaleY: a00 * invDet,
        dx: -a11 * a30 * invDet,
        dy: -a00 * a31 * invDet,
      );
    } else {
      return _generalInvert(this, rest);
    }
  }
}

@immutable
final class _MatrixExtension {
  static const _MatrixExtension _identityExtension = _MatrixExtension(
    m01: 0,
    m02: 0,
    m10: 0,
    m12: 0,
    m20: 0,
    m21: 0,
    m22: 1,
    m23: 0,
    m30: 0,
    m31: 0,
    m32: 0,
    m33: 1,
  );

  const _MatrixExtension({
    required double m01,
    required double m02,
    required double m10,
    required double m12,
    required double m20,
    required double m21,
    required double m22,
    required double m23,
    required double m30,
    required double m31,
    required double m32,
    required double m33,
  })  : _m01 = m01,
        _m02 = m02,
        _m10 = m10,
        _m12 = m12,
        _m20 = m20,
        _m21 = m21,
        _m22 = m22,
        _m23 = m23,
        _m30 = m30,
        _m31 = m31,
        _m32 = m32,
        _m33 = m33;

  final double _m01;
  final double _m02;
  final double _m10;
  final double _m12;
  final double _m20;
  final double _m21;
  final double _m22;
  final double _m23;
  final double _m30;
  final double _m31;
  final double _m32;
  final double _m33;

  _MatrixExtension _negate() {
    return _MatrixExtension(
      m01: -_m01,
      m02: -_m02,
      m10: -_m10,
      m12: -_m12,
      m20: -_m20,
      m21: -_m21,
      m22: -_m22,
      m23: -_m23,
      m30: -_m30,
      m31: -_m31,
      m32: -_m32,
      m33: -_m33,
    );
  }

  _MatrixExtension operator +(_MatrixExtension other) {
    return _MatrixExtension(
      m01: _m01 + other._m01,
      m02: _m02 + other._m02,
      m10: _m10 + other._m10,
      m12: _m12 + other._m12,
      m20: _m20 + other._m20,
      m21: _m21 + other._m21,
      m22: _m22 + other._m22,
      m23: _m23 + other._m23,
      m30: _m30 + other._m30,
      m31: _m31 + other._m31,
      m32: _m32 + other._m32,
      m33: _m33 + other._m33,
    );
  }
}

UiMatrix _generalMultiply(
    UiMatrix m, _MatrixExtension mExt, UiMatrix n, _MatrixExtension nExt) {
  final double m00 = m._m00;
  final double m01 = mExt._m01;
  final double m02 = mExt._m02;
  final double m03 = m._m03;

  final double m10 = mExt._m10;
  final double m11 = m._m11;
  final double m12 = mExt._m12;
  final double m13 = m._m13;

  final double m20 = mExt._m20;
  final double m21 = mExt._m21;
  final double m22 = mExt._m22;
  final double m23 = mExt._m23;

  final double m30 = mExt._m30;
  final double m31 = mExt._m31;
  final double m32 = mExt._m32;
  final double m33 = mExt._m33;

  final double n00 = n._m00;
  final double n01 = nExt._m01;
  final double n02 = nExt._m02;
  final double n03 = n._m03;

  final double n10 = nExt._m10;
  final double n11 = n._m11;
  final double n12 = nExt._m12;
  final double n13 = n._m13;

  final double n20 = nExt._m20;
  final double n21 = nExt._m21;
  final double n22 = nExt._m22;
  final double n23 = nExt._m23;

  final double n30 = nExt._m30;
  final double n31 = nExt._m31;
  final double n32 = nExt._m32;
  final double n33 = nExt._m33;

  final double v00 = (m00 * n00) + (m01 * n10) + (m02 * n20) + (m03 * n30);
  final double v01 = (m00 * n01) + (m01 * n11) + (m02 * n21) + (m03 * n31);
  final double v02 = (m00 * n02) + (m01 * n12) + (m02 * n22) + (m03 * n32);
  final double v03 = (m00 * n03) + (m01 * n13) + (m02 * n23) + (m03 * n33);
  final double v10 = (m10 * n00) + (m11 * n10) + (m12 * n20) + (m13 * n30);
  final double v11 = (m10 * n01) + (m11 * n11) + (m12 * n21) + (m13 * n31);
  final double v12 = (m10 * n02) + (m11 * n12) + (m12 * n22) + (m13 * n32);
  final double v13 = (m10 * n03) + (m11 * n13) + (m12 * n23) + (m13 * n33);
  final double v20 = (m20 * n00) + (m21 * n10) + (m22 * n20) + (m23 * n30);
  final double v21 = (m20 * n01) + (m21 * n11) + (m22 * n21) + (m23 * n31);
  final double v22 = (m20 * n02) + (m21 * n12) + (m22 * n22) + (m23 * n32);
  final double v23 = (m20 * n03) + (m21 * n13) + (m22 * n23) + (m23 * n33);
  final double v30 = (m30 * n00) + (m31 * n10) + (m32 * n20) + (m33 * n30);
  final double v31 = (m30 * n01) + (m31 * n11) + (m32 * n21) + (m33 * n31);
  final double v32 = (m30 * n02) + (m31 * n12) + (m32 * n22) + (m33 * n32);
  final double v33 = (m30 * n03) + (m31 * n13) + (m32 * n23) + (m33 * n33);

  return UiMatrix.transform(
    m00: v00,
    m01: v01,
    m02: v02,
    m03: v03,
    m10: v10,
    m11: v11,
    m12: v12,
    m13: v13,
    m20: v20,
    m21: v21,
    m22: v22,
    m23: v23,
    m30: v30,
    m31: v31,
    m32: v32,
    m33: v33,
  );
}

double _generalDeterminant(UiMatrix matrix, _MatrixExtension rest) {
  final double a00 = matrix._m00;
  final double a01 = rest._m10;
  final double a02 = rest._m20;
  final double a03 = rest._m30;
  final double a10 = rest._m01;
  final double a11 = matrix._m11;
  final double a12 = rest._m21;
  final double a13 = rest._m31;
  final double a20 = rest._m02;
  final double a21 = rest._m12;
  final double a22 = rest._m22;
  final double a23 = rest._m32;
  final double a30 = matrix._m03;
  final double a31 = matrix._m13;
  final double a32 = rest._m23;
  final double a33 = rest._m33;

  final double b00 = a00 * a11 - a01 * a10;
  final double b01 = a00 * a12 - a02 * a10;
  final double b02 = a00 * a13 - a03 * a10;
  final double b03 = a01 * a12 - a02 * a11;
  final double b04 = a01 * a13 - a03 * a11;
  final double b05 = a02 * a13 - a03 * a12;
  final double b06 = a20 * a31 - a21 * a30;
  final double b07 = a20 * a32 - a22 * a30;
  final double b08 = a20 * a33 - a23 * a30;
  final double b09 = a21 * a32 - a22 * a31;
  final double b10 = a21 * a33 - a23 * a31;
  final double b11 = a22 * a33 - a23 * a32;
  return b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
}

UiMatrix? _generalInvert(UiMatrix matrix, _MatrixExtension rest) {
  final double a00 = matrix._m00;
  final double a01 = rest._m10;
  final double a02 = rest._m20;
  final double a03 = rest._m30;
  final double a10 = rest._m01;
  final double a11 = matrix._m11;
  final double a12 = rest._m21;
  final double a13 = rest._m31;
  final double a20 = rest._m02;
  final double a21 = rest._m12;
  final double a22 = rest._m22;
  final double a23 = rest._m32;
  final double a30 = matrix._m03;
  final double a31 = matrix._m13;
  final double a32 = rest._m23;
  final double a33 = rest._m33;

  final double b00 = a00 * a11 - a01 * a10;
  final double b01 = a00 * a12 - a02 * a10;
  final double b02 = a00 * a13 - a03 * a10;
  final double b03 = a01 * a12 - a02 * a11;
  final double b04 = a01 * a13 - a03 * a11;
  final double b05 = a02 * a13 - a03 * a12;
  final double b06 = a20 * a31 - a21 * a30;
  final double b07 = a20 * a32 - a22 * a30;
  final double b08 = a20 * a33 - a23 * a30;
  final double b09 = a21 * a32 - a22 * a31;
  final double b10 = a21 * a33 - a23 * a31;
  final double b11 = a22 * a33 - a23 * a32;
  final double det =
      b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
  if (det == 0.0) {
    return null;
  }
  final double invDet = 1.0 / det;

  // Inverse of a general matrix is guaranteed to be a general matrix, so we can
  // instantiate a general matrix directly rather than trying to use
  // constructors that attempt to lower the matrix to simpler kinds.
  return UiMatrix._(
    m00: (a11 * b11 - a12 * b10 + a13 * b09) * invDet,
    m11: (a00 * b11 - a02 * b08 + a03 * b07) * invDet,
    m03: (-a10 * b09 + a11 * b07 - a12 * b06) * invDet,
    m13: (a00 * b09 - a01 * b07 + a02 * b06) * invDet,
    rest: _MatrixExtension(
      m01: (-a10 * b11 + a12 * b08 - a13 * b07) * invDet,
      m02: (a10 * b10 - a11 * b08 + a13 * b06) * invDet,
      m10: (-a01 * b11 + a02 * b10 - a03 * b09) * invDet,
      m12: (-a00 * b10 + a01 * b08 - a03 * b06) * invDet,
      m20: (a31 * b05 - a32 * b04 + a33 * b03) * invDet,
      m21: (-a30 * b05 + a32 * b02 - a33 * b01) * invDet,
      m22: (a30 * b04 - a31 * b02 + a33 * b00) * invDet,
      m23: (-a30 * b03 + a31 * b01 - a32 * b00) * invDet,
      m30: (-a21 * b05 + a22 * b04 - a23 * b03) * invDet,
      m31: (a20 * b05 - a22 * b02 + a23 * b01) * invDet,
      m32: (-a20 * b04 + a21 * b02 - a23 * b00) * invDet,
      m33: (a20 * b03 - a21 * b01 + a22 * b00) * invDet,
    ),
  );
}

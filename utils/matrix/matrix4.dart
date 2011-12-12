// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// based on code from 
// http://code.google.com/p/closure-library/source/browse/trunk/closure/goog/vec/mat4.js  

/**
 * Thrown if you attempt to normalize a zero length vector.
 */
class ZeroLengthVectorException implements Exception {
  ZeroLengthVectorException() {}
}

/**
 * Thrown if you attempt to invert a singular matrix.  (A
 * singular matrix has no inverse.)
 */
class SingularMatrixException implements Exception {
  SingularMatrixException() {}
}

/**
 * 3 dimensional vector.
 */
class Vector3 {
  final double x;
  final double y;
  final double z;

  // TODO - should be const, but cannot because of
  // bug http://code.google.com/p/dart/issues/detail?id=777

  // TODO - switch to initializing formal syntax once we have type
  // checking for this.x style constructors.  See bug
  // http://code.google.com/p/dart/issues/detail?id=464
  Vector3(double x, double y, double z) : x = x, y = y, z = z;

  double magnitude() => Math.sqrt(x*x + y*y + z*z);

  Vector3 normalize() {
    double len = magnitude();
    if (len == 0.0) {
      throw new ZeroLengthVectorException();
    }
    return new Vector3(x/len, y/len, z/len);
  }

  Vector3 operator negate() {
    return new Vector3(-x, -y, -z);
  }

  Vector3 operator -(Vector3 other) {
    return new Vector3(x - other.x, y - other.y, z - other.z);
  }

  Vector3 cross(Vector3 other) {
    double xResult = y * other.z - z * other.y;
    double yResult = z * other.x - x * other.z;
    double zResult = x * other.y - y * other.x;
    return new Vector3(xResult, yResult, zResult);
  }

  String toString() {
    return "Vector3($x,$y,$z)";
  }
}

/**
 * A 4x4 transformation matrix (for use with webgl)
 *
 * We label the elements of the matrix as follows:
 *
 *     m00 m01 m02 m03
 *     m10 m11 m12 m13
 *     m20 m21 m22 m23
 *     m30 m31 m32 m33
 *
 * These are stored in a 16 element [Float32Array], in column major
 * order, so they are ordered like this:
 *
 * [ m00,m10,m20,m30, m11,m21,m31,m41, m02,m12,m22,m32, m03,m13,m23,m33 ]
 *   0   1   2   3    4   5   6   7    8   9   10  11   12  13  14  15
 *
 * We use column major order because that is what WebGL APIs expect.
 *
 */
class Matrix4 {
  final Float32Array buf;

  /**
   * Constructs a new Matrix4 with all entries initialized
   * to zero.
   */
  Matrix4() : buf = new Float32Array(16);

  /**
   * returns the index into [buf] for a given
   * row and column.
   */
  static int rc(int row, int col) => row + col * 4;

  double get m00() => buf[rc(0, 0)];
  double get m01() => buf[rc(0, 1)];
  double get m02() => buf[rc(0, 2)];
  double get m03() => buf[rc(0, 3)];
  double get m10() => buf[rc(1, 0)];
  double get m11() => buf[rc(1, 1)];
  double get m12() => buf[rc(1, 2)];
  double get m13() => buf[rc(1, 3)];
  double get m20() => buf[rc(2, 0)];
  double get m21() => buf[rc(2, 1)];
  double get m22() => buf[rc(2, 2)];
  double get m23() => buf[rc(2, 3)];
  double get m30() => buf[rc(3, 0)];
  double get m31() => buf[rc(3, 1)];
  double get m32() => buf[rc(3, 2)];
  double get m33() => buf[rc(3, 3)];

  void set m00(double m) { buf[rc(0, 0)] = m; }
  void set m01(double m) { buf[rc(0, 1)] = m; }
  void set m02(double m) { buf[rc(0, 2)] = m; }
  void set m03(double m) { buf[rc(0, 3)] = m; }
  void set m10(double m) { buf[rc(1, 0)] = m; }
  void set m11(double m) { buf[rc(1, 1)] = m; }
  void set m12(double m) { buf[rc(1, 2)] = m; }
  void set m13(double m) { buf[rc(1, 3)] = m; }
  void set m20(double m) { buf[rc(2, 0)] = m; }
  void set m21(double m) { buf[rc(2, 1)] = m; }
  void set m22(double m) { buf[rc(2, 2)] = m; }
  void set m23(double m) { buf[rc(2, 3)] = m; }
  void set m30(double m) { buf[rc(3, 0)] = m; }
  void set m31(double m) { buf[rc(3, 1)] = m; }
  void set m32(double m) { buf[rc(3, 2)] = m; }
  void set m33(double m) { buf[rc(3, 3)] = m; }

  String toString() {
    List<String> rows = new List();
    for (int row = 0; row < 4; row++) {
      List<String> items = new List();
      for (int col = 0; col < 4; col++) {
        double v = buf[rc(row, col)];
        if (v.abs() < 1e-16) {
          v = 0.0;
        }
        String display;
        try {
          display = v.toStringAsPrecision(4);
        } catch (Object e) {
          // TODO - remove this once toStringAsPrecision is implemented in vm
          display = v.toString();
        }
        items.add(display);
      }
      rows.add("| ${Strings.join(items, ", ")} |");
    }
    return "Matrix4:\n${Strings.join(rows, '\n')}";
  }

  /**
   * Cosntructs a new Matrix4 that represents the identity transformation
   * (all the diagonal entries are 1, and everything else is zero).
   */
  static Matrix4 identity() {
    Matrix4 m = new Matrix4();
    m.m00 = 1.0;
    m.m11 = 1.0;
    m.m22 = 1.0;
    m.m33 = 1.0;
    return m;
  }

  /**
   * Constructs a new Matrix4 that represents a rotation around an axis.
   *
   * [degrees] number of degrees to rotate
   * [axis] direction of axis of rotation (must not be zero length)
   */
  static Matrix4 rotation(double degrees, Vector3 axis) {
    double radians = degrees / 180.0 * Math.PI;
    axis = axis.normalize();

    double x = axis.x;
    double y = axis.y;
    double z = axis.z;
    double s = Math.sin(radians);
    double c = Math.cos(radians);
    double t = 1 - c;

    Matrix4 m = new Matrix4();
    m.m00 = x * x * t + c;
    m.m10 = x * y * t + z * s;
    m.m20 = x * z * t - y * s;

    m.m01 = x * y * t - z * s;
    m.m11 = y * y * t + c;
    m.m21 = y * z * t + x * s;

    m.m02 = x * z * t + y * s;
    m.m12 = y * z * t - x * s;
    m.m22 = z * z * t + c;

    m.m33 = 1.0;
    return m;
  }

  /**
   * Constructs a new Matrix4 that represents a translation.
   *
   * [v] vector representing which direction to move and how much to move
   */
  static Matrix4 translation(Vector3 v) {
    Matrix4 m = identity();
    m.m03 = v.x;
    m.m13 = v.y;
    m.m23 = v.z;
    return m;
  }

  /**
   * returns the transpose of this matrix
   */
  Matrix4 transpose() {
    Matrix4 m = new Matrix4();
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4; col++) {
        m.buf[rc(col, row)] = this.buf[rc(row, col)];
      }
    }
    return m;
  }

  /**
   * Returns result of multiplication of this matrix
   * by another matrix.
   *
   * In this equation:
   *
   * C = A * B
   *
   * C is the result of multiplying A * B.
   * A is this matrix
   * B is another matrix
   *
   */
  Matrix4 operator *(Matrix4 matrixB) {
    Matrix4 matrixC = new Matrix4();
    Float32Array bufA = this.buf;
    Float32Array bufB = matrixB.buf;
    Float32Array bufC = matrixC.buf;
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4; col++) {
        for (int i = 0; i < 4; i++) {
          bufC[rc(row, col)] += bufA[rc(row, i)] * bufB[rc(i, col)];
        }
      }
    }
    return matrixC;
  }

  /**
   * Constructs a 4x4 matrix matrix so that the eye is 'looking at' a
   * given center point.  (What this means is that the returned matrix can be
   * used transform points from world coordinates to a new coordinate system
   * where the eye is at the origin, and the negative z-axis of the new
   * coordinate system goes from the eye towards the center point.)
   *
   * [eye] position of the eye (i.e. camera origin).
   * [center] point to aim the camera at.
   * [up] vector that identifies the up direction of the camera
   */
  static Matrix4 lookAt(Vector3 eye, Vector3 center, Vector3 up) {
    // Compute the z basis vector.  (The z-axis negative direction is
    // from eye to center point.)
    Vector3 zBasis = (eye - center).normalize();

    // Compute x basis.  (The positive x-axis points right.)
    Vector3 xBasis = up.cross(zBasis).normalize();

    // Compute the y basis.  (The positive y-axis points approximately the same
    // direction as the supplied [up] direction, and is perpendicular to z and
    // x.)
    Vector3 yBasis = zBasis.cross(xBasis);

    // We now have an orthonormal basis.
    Matrix4 b = new Matrix4();
    b.m00 = xBasis.x; b.m01 = xBasis.y; b.m02 = xBasis.z;
    b.m10 = yBasis.x; b.m11 = yBasis.y; b.m12 = yBasis.z;
    b.m20 = zBasis.x; b.m21 = zBasis.y; b.m22 = zBasis.z;
    b.m33 = 1.0;

    // Before switching to the new basis, first translate by the negation
    // of the eye point.  (This will put the eye at the origin of the
    // new coordinate system.)
    return b * Matrix4.translation(-eye);
  }

  /**
   * Makse a 4x4 matrix perspective projection matrix given a field of view and
   * aspect ratio.
   *
   * [fovyDegrees] field of view (in degrees) of the y-axis
   * [aspectRatio] width to height aspect ratio.
   * [zNear] distance to the near clipping plane.
   * [zFar] distance to the far clipping plane.
   */
  static Matrix4 perspective(double fovyDegrees, double aspectRatio,
      double zNear, double zFar) {
    double yTop = Math.tan(fovyDegrees * Math.PI / 180.0 / 2.0) * zNear;
    double xRight = aspectRatio * yTop;
    double zDepth = zFar - zNear;

    Matrix4 m = new Matrix4();
    m.m00 = zNear / xRight;
    m.m11 = zNear / yTop;
    m.m22 = -(zFar + zNear) / zDepth;
    m.m23 = -(2 * zNear * zFar) / zDepth;
    m.m32 = -1;
    return m;
  }

  /**
   * Returns the inverse of this matrix.
   */
  Matrix4 inverse() {
    double a0 = m00 * m11 - m10 * m01;
    double a1 = m00 * m21 - m20 * m01;
    double a2 = m00 * m31 - m30 * m01;
    double a3 = m10 * m21 - m20 * m11;
    double a4 = m10 * m31 - m30 * m11;
    double a5 = m20 * m31 - m30 * m21;

    double b0 = m02 * m13 - m12 * m03;
    double b1 = m02 * m23 - m22 * m03;
    double b2 = m02 * m33 - m32 * m03;
    double b3 = m12 * m23 - m22 * m13;
    double b4 = m12 * m33 - m32 * m13;
    double b5 = m22 * m33 - m32 * m23;

    // compute determinant
    double det = a0 * b5 - a1 * b4 + a2 * b3 + a3 * b2 - a4 * b1 + a5 * b0;
    if (det == 0) {
      throw new SingularMatrixException();
    }

    Matrix4 m = new Matrix4();
    m.m00 = (m11 * b5 - m21 * b4 + m31 * b3) / det;
    m.m10 = (-m10 * b5 + m20 * b4 - m30 * b3) / det;
    m.m20 = (m13 * a5 - m23 * a4 + m33 * a3) / det;
    m.m30 = (-m12 * a5 + m22 * a4 - m32 * a3) / det;

    m.m01 = (-m01 * b5 + m21 * b2 - m31 * b1) / det;
    m.m11 = (m00 * b5 - m20 * b2 + m30 * b1) / det;
    m.m21 = (-m03 * a5 + m23 * a2 - m33 * a1) / det;
    m.m31 = (m02 * a5 - m22 * a2 + m32 * a1) / det;

    m.m02 = (m01 * b4 - m11 * b2 + m31 * b0) / det;
    m.m12 = (-m00 * b4 + m10 * b2 - m30 * b0) / det;
    m.m22 = (m03 * a4 - m13 * a2 + m33 * a0) / det;
    m.m32 = (-m02 * a4 + m12 * a2 - m32 * a0) / det;

    m.m03 = (-m01 * b3 + m11 * b1 - m21 * b0) / det;
    m.m13 = (m00 * b3 - m10 * b1 + m20 * b0) / det;
    m.m23 = (-m03 * a3 + m13 * a1 - m23 * a0) / det;
    m.m33 = (m02 * a3 - m12 * a1 + m22 * a0) / det;

    return m;
  }
}

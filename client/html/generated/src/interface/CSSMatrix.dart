// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSMatrix factory CSSMatrixWrappingImplementation {
  CSSMatrix([String cssValue]);

  num get a();

  void set a(num value);

  num get b();

  void set b(num value);

  num get c();

  void set c(num value);

  num get d();

  void set d(num value);

  num get e();

  void set e(num value);

  num get f();

  void set f(num value);

  num get m11();

  void set m11(num value);

  num get m12();

  void set m12(num value);

  num get m13();

  void set m13(num value);

  num get m14();

  void set m14(num value);

  num get m21();

  void set m21(num value);

  num get m22();

  void set m22(num value);

  num get m23();

  void set m23(num value);

  num get m24();

  void set m24(num value);

  num get m31();

  void set m31(num value);

  num get m32();

  void set m32(num value);

  num get m33();

  void set m33(num value);

  num get m34();

  void set m34(num value);

  num get m41();

  void set m41(num value);

  num get m42();

  void set m42(num value);

  num get m43();

  void set m43(num value);

  num get m44();

  void set m44(num value);

  CSSMatrix inverse();

  CSSMatrix multiply(CSSMatrix secondMatrix);

  CSSMatrix rotate(num rotX, num rotY, num rotZ);

  CSSMatrix rotateAxisAngle(num x, num y, num z, num angle);

  CSSMatrix scale(num scaleX, num scaleY, num scaleZ);

  void setMatrixValue(String string);

  CSSMatrix skewX(num angle);

  CSSMatrix skewY(num angle);

  String toString();

  CSSMatrix translate(num x, num y, num z);
}

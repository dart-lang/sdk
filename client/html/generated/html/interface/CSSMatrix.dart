// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSMatrix default _CSSMatrixFactoryProvider {

  CSSMatrix([String cssValue]);

  num a;

  num b;

  num c;

  num d;

  num e;

  num f;

  num m11;

  num m12;

  num m13;

  num m14;

  num m21;

  num m22;

  num m23;

  num m24;

  num m31;

  num m32;

  num m33;

  num m34;

  num m41;

  num m42;

  num m43;

  num m44;

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

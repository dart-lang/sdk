// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGMatrix {

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

  SVGMatrix flipX();

  SVGMatrix flipY();

  SVGMatrix inverse();

  SVGMatrix multiply(SVGMatrix secondMatrix);

  SVGMatrix rotate(num angle);

  SVGMatrix rotateFromVector(num x, num y);

  SVGMatrix scale(num scaleFactor);

  SVGMatrix scaleNonUniform(num scaleFactorX, num scaleFactorY);

  SVGMatrix skewX(num angle);

  SVGMatrix skewY(num angle);

  SVGMatrix translate(num x, num y);
}

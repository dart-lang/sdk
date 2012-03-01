// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGMatrix {

  num a;

  num b;

  num c;

  num d;

  num e;

  num f;

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

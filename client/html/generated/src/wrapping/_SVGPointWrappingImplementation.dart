// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPointWrappingImplementation extends DOMWrapperBase implements SVGPoint {
  SVGPointWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }

  SVGPoint matrixTransform(SVGMatrix matrix) {
    return LevelDom.wrapSVGPoint(_ptr.matrixTransform(LevelDom.unwrap(matrix)));
  }
}

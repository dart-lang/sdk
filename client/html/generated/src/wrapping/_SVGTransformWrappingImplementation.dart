// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGTransformWrappingImplementation extends DOMWrapperBase implements SVGTransform {
  SVGTransformWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get angle() { return _ptr.angle; }

  SVGMatrix get matrix() { return LevelDom.wrapSVGMatrix(_ptr.matrix); }

  int get type() { return _ptr.type; }

  void setMatrix(SVGMatrix matrix) {
    _ptr.setMatrix(LevelDom.unwrap(matrix));
    return;
  }

  void setRotate(num angle, num cx, num cy) {
    _ptr.setRotate(angle, cx, cy);
    return;
  }

  void setScale(num sx, num sy) {
    _ptr.setScale(sx, sy);
    return;
  }

  void setSkewX(num angle) {
    _ptr.setSkewX(angle);
    return;
  }

  void setSkewY(num angle) {
    _ptr.setSkewY(angle);
    return;
  }

  void setTranslate(num tx, num ty) {
    _ptr.setTranslate(tx, ty);
    return;
  }
}

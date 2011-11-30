// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGTransformableWrappingImplementation extends _SVGLocatableWrappingImplementation implements SVGTransformable {
  _SVGTransformableWrappingImplementation() : super() {}

  static create__SVGTransformableWrappingImplementation() native {
    return new _SVGTransformableWrappingImplementation();
  }

  SVGAnimatedTransformList get transform() { return _get_transform(this); }
  static SVGAnimatedTransformList _get_transform(var _this) native;

  String get typeName() { return "SVGTransformable"; }
}

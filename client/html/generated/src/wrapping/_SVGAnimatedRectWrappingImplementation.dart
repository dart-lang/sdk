// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimatedRectWrappingImplementation extends DOMWrapperBase implements SVGAnimatedRect {
  SVGAnimatedRectWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGRect get animVal() { return LevelDom.wrapSVGRect(_ptr.animVal); }

  SVGRect get baseVal() { return LevelDom.wrapSVGRect(_ptr.baseVal); }
}

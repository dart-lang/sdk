// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimatedLengthListWrappingImplementation extends DOMWrapperBase implements SVGAnimatedLengthList {
  SVGAnimatedLengthListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGLengthList get animVal() { return LevelDom.wrapSVGLengthList(_ptr.animVal); }

  SVGLengthList get baseVal() { return LevelDom.wrapSVGLengthList(_ptr.baseVal); }
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimatedAngleWrappingImplementation extends DOMWrapperBase implements SVGAnimatedAngle {
  SVGAnimatedAngleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAngle get animVal() { return LevelDom.wrapSVGAngle(_ptr.animVal); }

  SVGAngle get baseVal() { return LevelDom.wrapSVGAngle(_ptr.baseVal); }
}

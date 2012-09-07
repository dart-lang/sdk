// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGElementInstanceWrappingImplementation extends EventTargetWrappingImplementation implements SVGElementInstance {
  SVGElementInstanceWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGElementInstanceList get childNodes { return LevelDom.wrapSVGElementInstanceList(_ptr.childNodes); }

  SVGElement get correspondingElement { return LevelDom.wrapSVGElement(_ptr.correspondingElement); }

  SVGUseElement get correspondingUseElement { return LevelDom.wrapSVGUseElement(_ptr.correspondingUseElement); }

  SVGElementInstance get firstChild { return LevelDom.wrapSVGElementInstance(_ptr.firstChild); }

  SVGElementInstance get lastChild { return LevelDom.wrapSVGElementInstance(_ptr.lastChild); }

  SVGElementInstance get nextSibling { return LevelDom.wrapSVGElementInstance(_ptr.nextSibling); }

  SVGElementInstance get parentNode { return LevelDom.wrapSVGElementInstance(_ptr.parentNode); }

  SVGElementInstance get previousSibling { return LevelDom.wrapSVGElementInstance(_ptr.previousSibling); }

}

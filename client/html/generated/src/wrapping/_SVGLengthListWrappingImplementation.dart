// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGLengthListWrappingImplementation extends DOMWrapperBase implements SVGLengthList {
  SVGLengthListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get numberOfItems() { return _ptr.numberOfItems; }

  SVGLength appendItem(SVGLength item) {
    return LevelDom.wrapSVGLength(_ptr.appendItem(LevelDom.unwrap(item)));
  }

  void clear() {
    _ptr.clear();
    return;
  }

  SVGLength getItem(int index) {
    return LevelDom.wrapSVGLength(_ptr.getItem(index));
  }

  SVGLength initialize(SVGLength item) {
    return LevelDom.wrapSVGLength(_ptr.initialize(LevelDom.unwrap(item)));
  }

  SVGLength insertItemBefore(SVGLength item, int index) {
    return LevelDom.wrapSVGLength(_ptr.insertItemBefore(LevelDom.unwrap(item), index));
  }

  SVGLength removeItem(int index) {
    return LevelDom.wrapSVGLength(_ptr.removeItem(index));
  }

  SVGLength replaceItem(SVGLength item, int index) {
    return LevelDom.wrapSVGLength(_ptr.replaceItem(LevelDom.unwrap(item), index));
  }
}

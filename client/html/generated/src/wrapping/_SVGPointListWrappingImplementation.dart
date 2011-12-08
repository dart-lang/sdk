// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPointListWrappingImplementation extends DOMWrapperBase implements SVGPointList {
  SVGPointListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get numberOfItems() { return _ptr.numberOfItems; }

  SVGPoint appendItem(SVGPoint item) {
    return LevelDom.wrapSVGPoint(_ptr.appendItem(LevelDom.unwrap(item)));
  }

  void clear() {
    _ptr.clear();
    return;
  }

  SVGPoint getItem(int index) {
    return LevelDom.wrapSVGPoint(_ptr.getItem(index));
  }

  SVGPoint initialize(SVGPoint item) {
    return LevelDom.wrapSVGPoint(_ptr.initialize(LevelDom.unwrap(item)));
  }

  SVGPoint insertItemBefore(SVGPoint item, int index) {
    return LevelDom.wrapSVGPoint(_ptr.insertItemBefore(LevelDom.unwrap(item), index));
  }

  SVGPoint removeItem(int index) {
    return LevelDom.wrapSVGPoint(_ptr.removeItem(index));
  }

  SVGPoint replaceItem(SVGPoint item, int index) {
    return LevelDom.wrapSVGPoint(_ptr.replaceItem(LevelDom.unwrap(item), index));
  }
}

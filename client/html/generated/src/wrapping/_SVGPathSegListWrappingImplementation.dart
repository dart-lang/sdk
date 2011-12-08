// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegListWrappingImplementation extends DOMWrapperBase implements SVGPathSegList {
  SVGPathSegListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get numberOfItems() { return _ptr.numberOfItems; }

  SVGPathSeg appendItem(SVGPathSeg newItem) {
    return LevelDom.wrapSVGPathSeg(_ptr.appendItem(LevelDom.unwrap(newItem)));
  }

  void clear() {
    _ptr.clear();
    return;
  }

  SVGPathSeg getItem(int index) {
    return LevelDom.wrapSVGPathSeg(_ptr.getItem(index));
  }

  SVGPathSeg initialize(SVGPathSeg newItem) {
    return LevelDom.wrapSVGPathSeg(_ptr.initialize(LevelDom.unwrap(newItem)));
  }

  SVGPathSeg insertItemBefore(SVGPathSeg newItem, int index) {
    return LevelDom.wrapSVGPathSeg(_ptr.insertItemBefore(LevelDom.unwrap(newItem), index));
  }

  SVGPathSeg removeItem(int index) {
    return LevelDom.wrapSVGPathSeg(_ptr.removeItem(index));
  }

  SVGPathSeg replaceItem(SVGPathSeg newItem, int index) {
    return LevelDom.wrapSVGPathSeg(_ptr.replaceItem(LevelDom.unwrap(newItem), index));
  }
}

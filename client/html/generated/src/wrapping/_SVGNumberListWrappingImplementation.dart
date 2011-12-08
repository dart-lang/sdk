// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGNumberListWrappingImplementation extends DOMWrapperBase implements SVGNumberList {
  SVGNumberListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get numberOfItems() { return _ptr.numberOfItems; }

  SVGNumber appendItem(SVGNumber item) {
    return LevelDom.wrapSVGNumber(_ptr.appendItem(LevelDom.unwrap(item)));
  }

  void clear() {
    _ptr.clear();
    return;
  }

  SVGNumber getItem(int index) {
    return LevelDom.wrapSVGNumber(_ptr.getItem(index));
  }

  SVGNumber initialize(SVGNumber item) {
    return LevelDom.wrapSVGNumber(_ptr.initialize(LevelDom.unwrap(item)));
  }

  SVGNumber insertItemBefore(SVGNumber item, int index) {
    return LevelDom.wrapSVGNumber(_ptr.insertItemBefore(LevelDom.unwrap(item), index));
  }

  SVGNumber removeItem(int index) {
    return LevelDom.wrapSVGNumber(_ptr.removeItem(index));
  }

  SVGNumber replaceItem(SVGNumber item, int index) {
    return LevelDom.wrapSVGNumber(_ptr.replaceItem(LevelDom.unwrap(item), index));
  }
}

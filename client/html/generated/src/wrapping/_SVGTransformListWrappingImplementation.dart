// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGTransformListWrappingImplementation extends DOMWrapperBase implements SVGTransformList {
  SVGTransformListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get numberOfItems() { return _ptr.numberOfItems; }

  SVGTransform appendItem(SVGTransform item) {
    return LevelDom.wrapSVGTransform(_ptr.appendItem(LevelDom.unwrap(item)));
  }

  void clear() {
    _ptr.clear();
    return;
  }

  SVGTransform consolidate() {
    return LevelDom.wrapSVGTransform(_ptr.consolidate());
  }

  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix) {
    return LevelDom.wrapSVGTransform(_ptr.createSVGTransformFromMatrix(LevelDom.unwrap(matrix)));
  }

  SVGTransform getItem(int index) {
    return LevelDom.wrapSVGTransform(_ptr.getItem(index));
  }

  SVGTransform initialize(SVGTransform item) {
    return LevelDom.wrapSVGTransform(_ptr.initialize(LevelDom.unwrap(item)));
  }

  SVGTransform insertItemBefore(SVGTransform item, int index) {
    return LevelDom.wrapSVGTransform(_ptr.insertItemBefore(LevelDom.unwrap(item), index));
  }

  SVGTransform removeItem(int index) {
    return LevelDom.wrapSVGTransform(_ptr.removeItem(index));
  }

  SVGTransform replaceItem(SVGTransform item, int index) {
    return LevelDom.wrapSVGTransform(_ptr.replaceItem(LevelDom.unwrap(item), index));
  }
}

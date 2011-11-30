// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGTransformListWrappingImplementation extends DOMWrapperBase implements SVGTransformList {
  _SVGTransformListWrappingImplementation() : super() {}

  static create__SVGTransformListWrappingImplementation() native {
    return new _SVGTransformListWrappingImplementation();
  }

  int get numberOfItems() { return _get_numberOfItems(this); }
  static int _get_numberOfItems(var _this) native;

  SVGTransform appendItem(SVGTransform item) {
    return _appendItem(this, item);
  }
  static SVGTransform _appendItem(receiver, item) native;

  void clear() {
    _clear(this);
    return;
  }
  static void _clear(receiver) native;

  SVGTransform consolidate() {
    return _consolidate(this);
  }
  static SVGTransform _consolidate(receiver) native;

  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix) {
    return _createSVGTransformFromMatrix(this, matrix);
  }
  static SVGTransform _createSVGTransformFromMatrix(receiver, matrix) native;

  SVGTransform getItem(int index) {
    return _getItem(this, index);
  }
  static SVGTransform _getItem(receiver, index) native;

  SVGTransform initialize(SVGTransform item) {
    return _initialize(this, item);
  }
  static SVGTransform _initialize(receiver, item) native;

  SVGTransform insertItemBefore(SVGTransform item, int index) {
    return _insertItemBefore(this, item, index);
  }
  static SVGTransform _insertItemBefore(receiver, item, index) native;

  SVGTransform removeItem(int index) {
    return _removeItem(this, index);
  }
  static SVGTransform _removeItem(receiver, index) native;

  SVGTransform replaceItem(SVGTransform item, int index) {
    return _replaceItem(this, item, index);
  }
  static SVGTransform _replaceItem(receiver, item, index) native;

  String get typeName() { return "SVGTransformList"; }
}

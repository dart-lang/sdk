// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGPointListWrappingImplementation extends DOMWrapperBase implements SVGPointList {
  _SVGPointListWrappingImplementation() : super() {}

  static create__SVGPointListWrappingImplementation() native {
    return new _SVGPointListWrappingImplementation();
  }

  int get numberOfItems() { return _get_numberOfItems(this); }
  static int _get_numberOfItems(var _this) native;

  SVGPoint appendItem(SVGPoint item) {
    return _appendItem(this, item);
  }
  static SVGPoint _appendItem(receiver, item) native;

  void clear() {
    _clear(this);
    return;
  }
  static void _clear(receiver) native;

  SVGPoint getItem(int index) {
    return _getItem(this, index);
  }
  static SVGPoint _getItem(receiver, index) native;

  SVGPoint initialize(SVGPoint item) {
    return _initialize(this, item);
  }
  static SVGPoint _initialize(receiver, item) native;

  SVGPoint insertItemBefore(SVGPoint item, int index) {
    return _insertItemBefore(this, item, index);
  }
  static SVGPoint _insertItemBefore(receiver, item, index) native;

  SVGPoint removeItem(int index) {
    return _removeItem(this, index);
  }
  static SVGPoint _removeItem(receiver, index) native;

  SVGPoint replaceItem(SVGPoint item, int index) {
    return _replaceItem(this, item, index);
  }
  static SVGPoint _replaceItem(receiver, item, index) native;

  String get typeName() { return "SVGPointList"; }
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGLengthListWrappingImplementation extends DOMWrapperBase implements SVGLengthList {
  _SVGLengthListWrappingImplementation() : super() {}

  static create__SVGLengthListWrappingImplementation() native {
    return new _SVGLengthListWrappingImplementation();
  }

  int get numberOfItems() { return _get_numberOfItems(this); }
  static int _get_numberOfItems(var _this) native;

  SVGLength appendItem(SVGLength item) {
    return _appendItem(this, item);
  }
  static SVGLength _appendItem(receiver, item) native;

  void clear() {
    _clear(this);
    return;
  }
  static void _clear(receiver) native;

  SVGLength getItem(int index) {
    return _getItem(this, index);
  }
  static SVGLength _getItem(receiver, index) native;

  SVGLength initialize(SVGLength item) {
    return _initialize(this, item);
  }
  static SVGLength _initialize(receiver, item) native;

  SVGLength insertItemBefore(SVGLength item, int index) {
    return _insertItemBefore(this, item, index);
  }
  static SVGLength _insertItemBefore(receiver, item, index) native;

  SVGLength removeItem(int index) {
    return _removeItem(this, index);
  }
  static SVGLength _removeItem(receiver, index) native;

  SVGLength replaceItem(SVGLength item, int index) {
    return _replaceItem(this, item, index);
  }
  static SVGLength _replaceItem(receiver, item, index) native;

  String get typeName() { return "SVGLengthList"; }
}

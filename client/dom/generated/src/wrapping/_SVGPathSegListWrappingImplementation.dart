// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGPathSegListWrappingImplementation extends DOMWrapperBase implements SVGPathSegList {
  _SVGPathSegListWrappingImplementation() : super() {}

  static create__SVGPathSegListWrappingImplementation() native {
    return new _SVGPathSegListWrappingImplementation();
  }

  int get numberOfItems() { return _get_numberOfItems(this); }
  static int _get_numberOfItems(var _this) native;

  SVGPathSeg appendItem(SVGPathSeg newItem) {
    return _appendItem(this, newItem);
  }
  static SVGPathSeg _appendItem(receiver, newItem) native;

  void clear() {
    _clear(this);
    return;
  }
  static void _clear(receiver) native;

  SVGPathSeg getItem(int index) {
    return _getItem(this, index);
  }
  static SVGPathSeg _getItem(receiver, index) native;

  SVGPathSeg initialize(SVGPathSeg newItem) {
    return _initialize(this, newItem);
  }
  static SVGPathSeg _initialize(receiver, newItem) native;

  SVGPathSeg insertItemBefore(SVGPathSeg newItem, int index) {
    return _insertItemBefore(this, newItem, index);
  }
  static SVGPathSeg _insertItemBefore(receiver, newItem, index) native;

  SVGPathSeg removeItem(int index) {
    return _removeItem(this, index);
  }
  static SVGPathSeg _removeItem(receiver, index) native;

  SVGPathSeg replaceItem(SVGPathSeg newItem, int index) {
    return _replaceItem(this, newItem, index);
  }
  static SVGPathSeg _replaceItem(receiver, newItem, index) native;

  String get typeName() { return "SVGPathSegList"; }
}

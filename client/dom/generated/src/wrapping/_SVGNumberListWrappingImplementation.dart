// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGNumberListWrappingImplementation extends DOMWrapperBase implements SVGNumberList {
  _SVGNumberListWrappingImplementation() : super() {}

  static create__SVGNumberListWrappingImplementation() native {
    return new _SVGNumberListWrappingImplementation();
  }

  int get numberOfItems() { return _get_numberOfItems(this); }
  static int _get_numberOfItems(var _this) native;

  SVGNumber appendItem(SVGNumber item) {
    return _appendItem(this, item);
  }
  static SVGNumber _appendItem(receiver, item) native;

  void clear() {
    _clear(this);
    return;
  }
  static void _clear(receiver) native;

  SVGNumber getItem(int index) {
    return _getItem(this, index);
  }
  static SVGNumber _getItem(receiver, index) native;

  SVGNumber initialize(SVGNumber item) {
    return _initialize(this, item);
  }
  static SVGNumber _initialize(receiver, item) native;

  SVGNumber insertItemBefore(SVGNumber item, int index) {
    return _insertItemBefore(this, item, index);
  }
  static SVGNumber _insertItemBefore(receiver, item, index) native;

  SVGNumber removeItem(int index) {
    return _removeItem(this, index);
  }
  static SVGNumber _removeItem(receiver, index) native;

  SVGNumber replaceItem(SVGNumber item, int index) {
    return _replaceItem(this, item, index);
  }
  static SVGNumber _replaceItem(receiver, item, index) native;

  String get typeName() { return "SVGNumberList"; }
}

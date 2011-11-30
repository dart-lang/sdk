// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGStringListWrappingImplementation extends DOMWrapperBase implements SVGStringList {
  _SVGStringListWrappingImplementation() : super() {}

  static create__SVGStringListWrappingImplementation() native {
    return new _SVGStringListWrappingImplementation();
  }

  int get numberOfItems() { return _get_numberOfItems(this); }
  static int _get_numberOfItems(var _this) native;

  String appendItem(String item) {
    return _appendItem(this, item);
  }
  static String _appendItem(receiver, item) native;

  void clear() {
    _clear(this);
    return;
  }
  static void _clear(receiver) native;

  String getItem(int index) {
    return _getItem(this, index);
  }
  static String _getItem(receiver, index) native;

  String initialize(String item) {
    return _initialize(this, item);
  }
  static String _initialize(receiver, item) native;

  String insertItemBefore(String item, int index) {
    return _insertItemBefore(this, item, index);
  }
  static String _insertItemBefore(receiver, item, index) native;

  String removeItem(int index) {
    return _removeItem(this, index);
  }
  static String _removeItem(receiver, index) native;

  String replaceItem(String item, int index) {
    return _replaceItem(this, item, index);
  }
  static String _replaceItem(receiver, item, index) native;

  String get typeName() { return "SVGStringList"; }
}

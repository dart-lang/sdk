// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DOMPluginArrayWrappingImplementation extends DOMWrapperBase implements DOMPluginArray {
  _DOMPluginArrayWrappingImplementation() : super() {}

  static create__DOMPluginArrayWrappingImplementation() native {
    return new _DOMPluginArrayWrappingImplementation();
  }

  int get length() { return _get__DOMPluginArray_length(this); }
  static int _get__DOMPluginArray_length(var _this) native;

  DOMPlugin item([int index = null]) {
    if (index === null) {
      return _item(this);
    } else {
      return _item_2(this, index);
    }
  }
  static DOMPlugin _item(receiver) native;
  static DOMPlugin _item_2(receiver, index) native;

  DOMPlugin namedItem([String name = null]) {
    if (name === null) {
      return _namedItem(this);
    } else {
      return _namedItem_2(this, name);
    }
  }
  static DOMPlugin _namedItem(receiver) native;
  static DOMPlugin _namedItem_2(receiver, name) native;

  void refresh([bool reload = null]) {
    if (reload === null) {
      _refresh(this);
      return;
    } else {
      _refresh_2(this, reload);
      return;
    }
  }
  static void _refresh(receiver) native;
  static void _refresh_2(receiver, reload) native;

  String get typeName() { return "DOMPluginArray"; }
}

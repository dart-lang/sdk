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

  DOMPlugin item(int index) {
    return _item(this, index);
  }
  static DOMPlugin _item(receiver, index) native;

  DOMPlugin namedItem(String name) {
    return _namedItem(this, name);
  }
  static DOMPlugin _namedItem(receiver, name) native;

  void refresh(bool reload) {
    _refresh(this, reload);
    return;
  }
  static void _refresh(receiver, reload) native;

  String get typeName() { return "DOMPluginArray"; }
}

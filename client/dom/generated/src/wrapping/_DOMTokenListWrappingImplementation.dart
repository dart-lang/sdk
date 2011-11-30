// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DOMTokenListWrappingImplementation extends DOMWrapperBase implements DOMTokenList {
  _DOMTokenListWrappingImplementation() : super() {}

  static create__DOMTokenListWrappingImplementation() native {
    return new _DOMTokenListWrappingImplementation();
  }

  int get length() { return _get_length(this); }
  static int _get_length(var _this) native;

  void add(String token) {
    _add(this, token);
    return;
  }
  static void _add(receiver, token) native;

  bool contains(String token) {
    return _contains(this, token);
  }
  static bool _contains(receiver, token) native;

  String item(int index) {
    return _item(this, index);
  }
  static String _item(receiver, index) native;

  void remove(String token) {
    _remove(this, token);
    return;
  }
  static void _remove(receiver, token) native;

  String toString() {
    return _toString(this);
  }
  static String _toString(receiver) native;

  bool toggle(String token) {
    return _toggle(this, token);
  }
  static bool _toggle(receiver, token) native;

  String get typeName() { return "DOMTokenList"; }
}

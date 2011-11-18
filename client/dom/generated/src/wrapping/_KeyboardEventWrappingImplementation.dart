// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _KeyboardEventWrappingImplementation extends _UIEventWrappingImplementation implements KeyboardEvent {
  _KeyboardEventWrappingImplementation() : super() {}

  static create__KeyboardEventWrappingImplementation() native {
    return new _KeyboardEventWrappingImplementation();
  }

  bool get altGraphKey() { return _get_altGraphKey(this); }
  static bool _get_altGraphKey(var _this) native;

  bool get altKey() { return _get_altKey(this); }
  static bool _get_altKey(var _this) native;

  bool get ctrlKey() { return _get_ctrlKey(this); }
  static bool _get_ctrlKey(var _this) native;

  String get keyIdentifier() { return _get_keyIdentifier(this); }
  static String _get_keyIdentifier(var _this) native;

  int get keyLocation() { return _get_keyLocation(this); }
  static int _get_keyLocation(var _this) native;

  bool get metaKey() { return _get_metaKey(this); }
  static bool _get_metaKey(var _this) native;

  bool get shiftKey() { return _get_shiftKey(this); }
  static bool _get_shiftKey(var _this) native;

  void initKeyboardEvent(String type, bool canBubble, bool cancelable, DOMWindow view, String keyIdentifier, int keyLocation, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, bool altGraphKey) {
    _initKeyboardEvent(this, type, canBubble, cancelable, view, keyIdentifier, keyLocation, ctrlKey, altKey, shiftKey, metaKey, altGraphKey);
    return;
  }
  static void _initKeyboardEvent(receiver, type, canBubble, cancelable, view, keyIdentifier, keyLocation, ctrlKey, altKey, shiftKey, metaKey, altGraphKey) native;

  String get typeName() { return "KeyboardEvent"; }
}

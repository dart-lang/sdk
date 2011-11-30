// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _UIEventWrappingImplementation extends _EventWrappingImplementation implements UIEvent {
  _UIEventWrappingImplementation() : super() {}

  static create__UIEventWrappingImplementation() native {
    return new _UIEventWrappingImplementation();
  }

  int get charCode() { return _get_charCode(this); }
  static int _get_charCode(var _this) native;

  int get detail() { return _get_detail(this); }
  static int _get_detail(var _this) native;

  int get keyCode() { return _get_keyCode(this); }
  static int _get_keyCode(var _this) native;

  int get layerX() { return _get_layerX(this); }
  static int _get_layerX(var _this) native;

  int get layerY() { return _get_layerY(this); }
  static int _get_layerY(var _this) native;

  int get pageX() { return _get_pageX(this); }
  static int _get_pageX(var _this) native;

  int get pageY() { return _get_pageY(this); }
  static int _get_pageY(var _this) native;

  DOMWindow get view() { return _get_view(this); }
  static DOMWindow _get_view(var _this) native;

  int get which() { return _get_which(this); }
  static int _get_which(var _this) native;

  void initUIEvent(String type, bool canBubble, bool cancelable, DOMWindow view, int detail) {
    _initUIEvent(this, type, canBubble, cancelable, view, detail);
    return;
  }
  static void _initUIEvent(receiver, type, canBubble, cancelable, view, detail) native;

  String get typeName() { return "UIEvent"; }
}

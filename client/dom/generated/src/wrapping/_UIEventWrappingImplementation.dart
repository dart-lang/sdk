// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _UIEventWrappingImplementation extends _EventWrappingImplementation implements UIEvent {
  _UIEventWrappingImplementation() : super() {}

  static create__UIEventWrappingImplementation() native {
    return new _UIEventWrappingImplementation();
  }

  int get charCode() { return _get__UIEvent_charCode(this); }
  static int _get__UIEvent_charCode(var _this) native;

  int get detail() { return _get__UIEvent_detail(this); }
  static int _get__UIEvent_detail(var _this) native;

  int get keyCode() { return _get__UIEvent_keyCode(this); }
  static int _get__UIEvent_keyCode(var _this) native;

  int get layerX() { return _get__UIEvent_layerX(this); }
  static int _get__UIEvent_layerX(var _this) native;

  int get layerY() { return _get__UIEvent_layerY(this); }
  static int _get__UIEvent_layerY(var _this) native;

  int get pageX() { return _get__UIEvent_pageX(this); }
  static int _get__UIEvent_pageX(var _this) native;

  int get pageY() { return _get__UIEvent_pageY(this); }
  static int _get__UIEvent_pageY(var _this) native;

  DOMWindow get view() { return _get__UIEvent_view(this); }
  static DOMWindow _get__UIEvent_view(var _this) native;

  int get which() { return _get__UIEvent_which(this); }
  static int _get__UIEvent_which(var _this) native;

  void initUIEvent(String type, bool canBubble, bool cancelable, DOMWindow view, int detail) {
    _initUIEvent(this, type, canBubble, cancelable, view, detail);
    return;
  }
  static void _initUIEvent(receiver, type, canBubble, cancelable, view, detail) native;

  String get typeName() { return "UIEvent"; }
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MouseEventWrappingImplementation extends _UIEventWrappingImplementation implements MouseEvent {
  _MouseEventWrappingImplementation() : super() {}

  static create__MouseEventWrappingImplementation() native {
    return new _MouseEventWrappingImplementation();
  }

  bool get altKey() { return _get_altKey(this); }
  static bool _get_altKey(var _this) native;

  int get button() { return _get_button(this); }
  static int _get_button(var _this) native;

  int get clientX() { return _get_clientX(this); }
  static int _get_clientX(var _this) native;

  int get clientY() { return _get_clientY(this); }
  static int _get_clientY(var _this) native;

  bool get ctrlKey() { return _get_ctrlKey(this); }
  static bool _get_ctrlKey(var _this) native;

  Clipboard get dataTransfer() { return _get_dataTransfer(this); }
  static Clipboard _get_dataTransfer(var _this) native;

  Node get fromElement() { return _get_fromElement(this); }
  static Node _get_fromElement(var _this) native;

  bool get metaKey() { return _get_metaKey(this); }
  static bool _get_metaKey(var _this) native;

  int get offsetX() { return _get_offsetX(this); }
  static int _get_offsetX(var _this) native;

  int get offsetY() { return _get_offsetY(this); }
  static int _get_offsetY(var _this) native;

  EventTarget get relatedTarget() { return _get_relatedTarget(this); }
  static EventTarget _get_relatedTarget(var _this) native;

  int get screenX() { return _get_screenX(this); }
  static int _get_screenX(var _this) native;

  int get screenY() { return _get_screenY(this); }
  static int _get_screenY(var _this) native;

  bool get shiftKey() { return _get_shiftKey(this); }
  static bool _get_shiftKey(var _this) native;

  Node get toElement() { return _get_toElement(this); }
  static Node _get_toElement(var _this) native;

  int get x() { return _get_x(this); }
  static int _get_x(var _this) native;

  int get y() { return _get_y(this); }
  static int _get_y(var _this) native;

  void initMouseEvent(String type, bool canBubble, bool cancelable, DOMWindow view, int detail, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, int button, EventTarget relatedTarget) {
    _initMouseEvent(this, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget);
    return;
  }
  static void _initMouseEvent(receiver, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget) native;

  String get typeName() { return "MouseEvent"; }
}

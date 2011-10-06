// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MouseEventWrappingImplementation extends _UIEventWrappingImplementation implements MouseEvent {
  _MouseEventWrappingImplementation() : super() {}

  static create__MouseEventWrappingImplementation() native {
    return new _MouseEventWrappingImplementation();
  }

  bool get altKey() { return _get__MouseEvent_altKey(this); }
  static bool _get__MouseEvent_altKey(var _this) native;

  int get button() { return _get__MouseEvent_button(this); }
  static int _get__MouseEvent_button(var _this) native;

  int get clientX() { return _get__MouseEvent_clientX(this); }
  static int _get__MouseEvent_clientX(var _this) native;

  int get clientY() { return _get__MouseEvent_clientY(this); }
  static int _get__MouseEvent_clientY(var _this) native;

  bool get ctrlKey() { return _get__MouseEvent_ctrlKey(this); }
  static bool _get__MouseEvent_ctrlKey(var _this) native;

  Node get fromElement() { return _get__MouseEvent_fromElement(this); }
  static Node _get__MouseEvent_fromElement(var _this) native;

  bool get metaKey() { return _get__MouseEvent_metaKey(this); }
  static bool _get__MouseEvent_metaKey(var _this) native;

  int get offsetX() { return _get__MouseEvent_offsetX(this); }
  static int _get__MouseEvent_offsetX(var _this) native;

  int get offsetY() { return _get__MouseEvent_offsetY(this); }
  static int _get__MouseEvent_offsetY(var _this) native;

  EventTarget get relatedTarget() { return _get__MouseEvent_relatedTarget(this); }
  static EventTarget _get__MouseEvent_relatedTarget(var _this) native;

  int get screenX() { return _get__MouseEvent_screenX(this); }
  static int _get__MouseEvent_screenX(var _this) native;

  int get screenY() { return _get__MouseEvent_screenY(this); }
  static int _get__MouseEvent_screenY(var _this) native;

  bool get shiftKey() { return _get__MouseEvent_shiftKey(this); }
  static bool _get__MouseEvent_shiftKey(var _this) native;

  Node get toElement() { return _get__MouseEvent_toElement(this); }
  static Node _get__MouseEvent_toElement(var _this) native;

  int get x() { return _get__MouseEvent_x(this); }
  static int _get__MouseEvent_x(var _this) native;

  int get y() { return _get__MouseEvent_y(this); }
  static int _get__MouseEvent_y(var _this) native;

  void initMouseEvent(String type, bool canBubble, bool cancelable, DOMWindow view, int detail, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, int button, EventTarget relatedTarget) {
    _initMouseEvent(this, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget);
    return;
  }
  static void _initMouseEvent(receiver, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget) native;

  String get typeName() { return "MouseEvent"; }
}

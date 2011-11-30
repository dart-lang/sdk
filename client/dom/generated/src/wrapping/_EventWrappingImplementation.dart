// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _EventWrappingImplementation extends DOMWrapperBase implements Event {
  _EventWrappingImplementation() : super() {}

  static create__EventWrappingImplementation() native {
    return new _EventWrappingImplementation();
  }

  bool get bubbles() { return _get_bubbles(this); }
  static bool _get_bubbles(var _this) native;

  bool get cancelBubble() { return _get_cancelBubble(this); }
  static bool _get_cancelBubble(var _this) native;

  void set cancelBubble(bool value) { _set_cancelBubble(this, value); }
  static void _set_cancelBubble(var _this, bool value) native;

  bool get cancelable() { return _get_cancelable(this); }
  static bool _get_cancelable(var _this) native;

  Clipboard get clipboardData() { return _get_clipboardData(this); }
  static Clipboard _get_clipboardData(var _this) native;

  EventTarget get currentTarget() { return _get_currentTarget(this); }
  static EventTarget _get_currentTarget(var _this) native;

  bool get defaultPrevented() { return _get_defaultPrevented(this); }
  static bool _get_defaultPrevented(var _this) native;

  int get eventPhase() { return _get_eventPhase(this); }
  static int _get_eventPhase(var _this) native;

  bool get returnValue() { return _get_returnValue(this); }
  static bool _get_returnValue(var _this) native;

  void set returnValue(bool value) { _set_returnValue(this, value); }
  static void _set_returnValue(var _this, bool value) native;

  EventTarget get srcElement() { return _get_srcElement(this); }
  static EventTarget _get_srcElement(var _this) native;

  EventTarget get target() { return _get_target(this); }
  static EventTarget _get_target(var _this) native;

  int get timeStamp() { return _get_timeStamp(this); }
  static int _get_timeStamp(var _this) native;

  String get type() { return _get_type(this); }
  static String _get_type(var _this) native;

  void initEvent(String eventTypeArg, bool canBubbleArg, bool cancelableArg) {
    _initEvent(this, eventTypeArg, canBubbleArg, cancelableArg);
    return;
  }
  static void _initEvent(receiver, eventTypeArg, canBubbleArg, cancelableArg) native;

  void preventDefault() {
    _preventDefault(this);
    return;
  }
  static void _preventDefault(receiver) native;

  void stopImmediatePropagation() {
    _stopImmediatePropagation(this);
    return;
  }
  static void _stopImmediatePropagation(receiver) native;

  void stopPropagation() {
    _stopPropagation(this);
    return;
  }
  static void _stopPropagation(receiver) native;

  String get typeName() { return "Event"; }
}

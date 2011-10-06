// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _EventWrappingImplementation extends DOMWrapperBase implements Event {
  _EventWrappingImplementation() : super() {}

  static create__EventWrappingImplementation() native {
    return new _EventWrappingImplementation();
  }

  bool get bubbles() { return _get__Event_bubbles(this); }
  static bool _get__Event_bubbles(var _this) native;

  bool get cancelBubble() { return _get__Event_cancelBubble(this); }
  static bool _get__Event_cancelBubble(var _this) native;

  void set cancelBubble(bool value) { _set__Event_cancelBubble(this, value); }
  static void _set__Event_cancelBubble(var _this, bool value) native;

  bool get cancelable() { return _get__Event_cancelable(this); }
  static bool _get__Event_cancelable(var _this) native;

  EventTarget get currentTarget() { return _get__Event_currentTarget(this); }
  static EventTarget _get__Event_currentTarget(var _this) native;

  bool get defaultPrevented() { return _get__Event_defaultPrevented(this); }
  static bool _get__Event_defaultPrevented(var _this) native;

  int get eventPhase() { return _get__Event_eventPhase(this); }
  static int _get__Event_eventPhase(var _this) native;

  bool get returnValue() { return _get__Event_returnValue(this); }
  static bool _get__Event_returnValue(var _this) native;

  void set returnValue(bool value) { _set__Event_returnValue(this, value); }
  static void _set__Event_returnValue(var _this, bool value) native;

  EventTarget get srcElement() { return _get__Event_srcElement(this); }
  static EventTarget _get__Event_srcElement(var _this) native;

  EventTarget get target() { return _get__Event_target(this); }
  static EventTarget _get__Event_target(var _this) native;

  int get timeStamp() { return _get__Event_timeStamp(this); }
  static int _get__Event_timeStamp(var _this) native;

  String get type() { return _get__Event_type(this); }
  static String _get__Event_type(var _this) native;

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

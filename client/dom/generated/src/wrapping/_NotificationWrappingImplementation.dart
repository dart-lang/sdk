// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _NotificationWrappingImplementation extends DOMWrapperBase implements Notification {
  _NotificationWrappingImplementation() : super() {}

  static create__NotificationWrappingImplementation() native {
    return new _NotificationWrappingImplementation();
  }

  String get dir() { return _get__Notification_dir(this); }
  static String _get__Notification_dir(var _this) native;

  void set dir(String value) { _set__Notification_dir(this, value); }
  static void _set__Notification_dir(var _this, String value) native;

  EventListener get onclick() { return _get__Notification_onclick(this); }
  static EventListener _get__Notification_onclick(var _this) native;

  void set onclick(EventListener value) { _set__Notification_onclick(this, value); }
  static void _set__Notification_onclick(var _this, EventListener value) native;

  EventListener get onclose() { return _get__Notification_onclose(this); }
  static EventListener _get__Notification_onclose(var _this) native;

  void set onclose(EventListener value) { _set__Notification_onclose(this, value); }
  static void _set__Notification_onclose(var _this, EventListener value) native;

  EventListener get ondisplay() { return _get__Notification_ondisplay(this); }
  static EventListener _get__Notification_ondisplay(var _this) native;

  void set ondisplay(EventListener value) { _set__Notification_ondisplay(this, value); }
  static void _set__Notification_ondisplay(var _this, EventListener value) native;

  EventListener get onerror() { return _get__Notification_onerror(this); }
  static EventListener _get__Notification_onerror(var _this) native;

  void set onerror(EventListener value) { _set__Notification_onerror(this, value); }
  static void _set__Notification_onerror(var _this, EventListener value) native;

  String get replaceId() { return _get__Notification_replaceId(this); }
  static String _get__Notification_replaceId(var _this) native;

  void set replaceId(String value) { _set__Notification_replaceId(this, value); }
  static void _set__Notification_replaceId(var _this, String value) native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _addEventListener(this, type, listener);
      return;
    } else {
      _addEventListener_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _addEventListener(receiver, type, listener) native;
  static void _addEventListener_2(receiver, type, listener, useCapture) native;

  void cancel() {
    _cancel(this);
    return;
  }
  static void _cancel(receiver) native;

  bool dispatchEvent(Event evt) {
    return _dispatchEvent(this, evt);
  }
  static bool _dispatchEvent(receiver, evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _removeEventListener(this, type, listener);
      return;
    } else {
      _removeEventListener_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _removeEventListener(receiver, type, listener) native;
  static void _removeEventListener_2(receiver, type, listener, useCapture) native;

  void show() {
    _show(this);
    return;
  }
  static void _show(receiver) native;

  String get typeName() { return "Notification"; }
}

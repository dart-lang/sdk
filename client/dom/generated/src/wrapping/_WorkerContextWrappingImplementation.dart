// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WorkerContextWrappingImplementation extends DOMWrapperBase implements WorkerContext {
  _WorkerContextWrappingImplementation() : super() {}

  static create__WorkerContextWrappingImplementation() native {
    return new _WorkerContextWrappingImplementation();
  }

  WorkerLocation get location() { return _get__WorkerContext_location(this); }
  static WorkerLocation _get__WorkerContext_location(var _this) native;

  void set location(WorkerLocation value) { _set__WorkerContext_location(this, value); }
  static void _set__WorkerContext_location(var _this, WorkerLocation value) native;

  WorkerNavigator get navigator() { return _get__WorkerContext_navigator(this); }
  static WorkerNavigator _get__WorkerContext_navigator(var _this) native;

  void set navigator(WorkerNavigator value) { _set__WorkerContext_navigator(this, value); }
  static void _set__WorkerContext_navigator(var _this, WorkerNavigator value) native;

  EventListener get onerror() { return _get__WorkerContext_onerror(this); }
  static EventListener _get__WorkerContext_onerror(var _this) native;

  void set onerror(EventListener value) { _set__WorkerContext_onerror(this, value); }
  static void _set__WorkerContext_onerror(var _this, EventListener value) native;

  NotificationCenter get webkitNotifications() { return _get__WorkerContext_webkitNotifications(this); }
  static NotificationCenter _get__WorkerContext_webkitNotifications(var _this) native;

  DOMURL get webkitURL() { return _get__WorkerContext_webkitURL(this); }
  static DOMURL _get__WorkerContext_webkitURL(var _this) native;

  void addEventListener(String type, EventListener listener, bool useCapture = null) {
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

  void clearInterval(int handle = null) {
    if (handle === null) {
      _clearInterval(this);
      return;
    } else {
      _clearInterval_2(this, handle);
      return;
    }
  }
  static void _clearInterval(receiver) native;
  static void _clearInterval_2(receiver, handle) native;

  void clearTimeout(int handle = null) {
    if (handle === null) {
      _clearTimeout(this);
      return;
    } else {
      _clearTimeout_2(this, handle);
      return;
    }
  }
  static void _clearTimeout(receiver) native;
  static void _clearTimeout_2(receiver, handle) native;

  void close() {
    _close(this);
    return;
  }
  static void _close(receiver) native;

  bool dispatchEvent(Event evt) {
    return _dispatchEvent(this, evt);
  }
  static bool _dispatchEvent(receiver, evt) native;

  void importScripts() {
    _importScripts(this);
    return;
  }
  static void _importScripts(receiver) native;

  void removeEventListener(String type, EventListener listener, bool useCapture = null) {
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

  int setInterval(TimeoutHandler handler, int timeout) {
    return _setInterval(this, handler, timeout);
  }
  static int _setInterval(receiver, handler, timeout) native;

  int setTimeout(TimeoutHandler handler, int timeout) {
    return _setTimeout(this, handler, timeout);
  }
  static int _setTimeout(receiver, handler, timeout) native;

  String get typeName() { return "WorkerContext"; }
}

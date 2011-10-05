// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _EventSourceWrappingImplementation extends DOMWrapperBase implements EventSource {
  _EventSourceWrappingImplementation() : super() {}

  static create__EventSourceWrappingImplementation() native {
    return new _EventSourceWrappingImplementation();
  }

  String get URL() { return _get__EventSource_URL(this); }
  static String _get__EventSource_URL(var _this) native;

  EventListener get onerror() { return _get__EventSource_onerror(this); }
  static EventListener _get__EventSource_onerror(var _this) native;

  void set onerror(EventListener value) { _set__EventSource_onerror(this, value); }
  static void _set__EventSource_onerror(var _this, EventListener value) native;

  EventListener get onmessage() { return _get__EventSource_onmessage(this); }
  static EventListener _get__EventSource_onmessage(var _this) native;

  void set onmessage(EventListener value) { _set__EventSource_onmessage(this, value); }
  static void _set__EventSource_onmessage(var _this, EventListener value) native;

  EventListener get onopen() { return _get__EventSource_onopen(this); }
  static EventListener _get__EventSource_onopen(var _this) native;

  void set onopen(EventListener value) { _set__EventSource_onopen(this, value); }
  static void _set__EventSource_onopen(var _this, EventListener value) native;

  int get readyState() { return _get__EventSource_readyState(this); }
  static int _get__EventSource_readyState(var _this) native;

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

  void close() {
    _close(this);
    return;
  }
  static void _close(receiver) native;

  bool dispatchEvent(Event evt) {
    return _dispatchEvent(this, evt);
  }
  static bool _dispatchEvent(receiver, evt) native;

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

  String get typeName() { return "EventSource"; }
}

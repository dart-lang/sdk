// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _EventSourceWrappingImplementation extends DOMWrapperBase implements EventSource {
  _EventSourceWrappingImplementation() : super() {}

  static create__EventSourceWrappingImplementation() native {
    return new _EventSourceWrappingImplementation();
  }

  String get URL() { return _get_URL(this); }
  static String _get_URL(var _this) native;

  int get readyState() { return _get_readyState(this); }
  static int _get_readyState(var _this) native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _addEventListener_EventSource(this, type, listener);
      return;
    } else {
      _addEventListener_EventSource_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _addEventListener_EventSource(receiver, type, listener) native;
  static void _addEventListener_EventSource_2(receiver, type, listener, useCapture) native;

  void close() {
    _close(this);
    return;
  }
  static void _close(receiver) native;

  bool dispatchEvent(Event evt) {
    return _dispatchEvent_EventSource(this, evt);
  }
  static bool _dispatchEvent_EventSource(receiver, evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _removeEventListener_EventSource(this, type, listener);
      return;
    } else {
      _removeEventListener_EventSource_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _removeEventListener_EventSource(receiver, type, listener) native;
  static void _removeEventListener_EventSource_2(receiver, type, listener, useCapture) native;

  String get typeName() { return "EventSource"; }
}

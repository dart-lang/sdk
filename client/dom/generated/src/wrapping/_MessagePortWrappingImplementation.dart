// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MessagePortWrappingImplementation extends DOMWrapperBase implements MessagePort {
  _MessagePortWrappingImplementation() : super() {}

  static create__MessagePortWrappingImplementation() native {
    return new _MessagePortWrappingImplementation();
  }

  EventListener get onmessage() { return _get__MessagePort_onmessage(this); }
  static EventListener _get__MessagePort_onmessage(var _this) native;

  void set onmessage(EventListener value) { _set__MessagePort_onmessage(this, value); }
  static void _set__MessagePort_onmessage(var _this, EventListener value) native;

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

  void close() {
    _close(this);
    return;
  }
  static void _close(receiver) native;

  bool dispatchEvent(Event evt) {
    return _dispatchEvent(this, evt);
  }
  static bool _dispatchEvent(receiver, evt) native;

  void postMessage(String message) {
    _postMessage(this, message);
    return;
  }
  static void _postMessage(receiver, message) native;

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

  void start() {
    _start(this);
    return;
  }
  static void _start(receiver) native;

  void webkitPostMessage(String message) {
    _webkitPostMessage(this, message);
    return;
  }
  static void _webkitPostMessage(receiver, message) native;

  String get typeName() { return "MessagePort"; }
}

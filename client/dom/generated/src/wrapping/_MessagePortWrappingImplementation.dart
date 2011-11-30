// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MessagePortWrappingImplementation extends DOMWrapperBase implements MessagePort {
  _MessagePortWrappingImplementation() : super() {}

  static create__MessagePortWrappingImplementation() native {
    return new _MessagePortWrappingImplementation();
  }

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _addEventListener_MessagePort(this, type, listener);
      return;
    } else {
      _addEventListener_MessagePort_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _addEventListener_MessagePort(receiver, type, listener) native;
  static void _addEventListener_MessagePort_2(receiver, type, listener, useCapture) native;

  void close() {
    _close(this);
    return;
  }
  static void _close(receiver) native;

  bool dispatchEvent(Event evt) {
    return _dispatchEvent_MessagePort(this, evt);
  }
  static bool _dispatchEvent_MessagePort(receiver, evt) native;

  void postMessage(String message, [List messagePorts = null]) {
    if (messagePorts === null) {
      _postMessage(this, message);
      return;
    } else {
      _postMessage_2(this, message, messagePorts);
      return;
    }
  }
  static void _postMessage(receiver, message) native;
  static void _postMessage_2(receiver, message, messagePorts) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _removeEventListener_MessagePort(this, type, listener);
      return;
    } else {
      _removeEventListener_MessagePort_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _removeEventListener_MessagePort(receiver, type, listener) native;
  static void _removeEventListener_MessagePort_2(receiver, type, listener, useCapture) native;

  void start() {
    _start(this);
    return;
  }
  static void _start(receiver) native;

  void webkitPostMessage(String message, [List transfer = null]) {
    if (transfer === null) {
      _webkitPostMessage(this, message);
      return;
    } else {
      _webkitPostMessage_2(this, message, transfer);
      return;
    }
  }
  static void _webkitPostMessage(receiver, message) native;
  static void _webkitPostMessage_2(receiver, message, transfer) native;

  String get typeName() { return "MessagePort"; }
}

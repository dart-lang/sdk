// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WorkerWrappingImplementation extends _AbstractWorkerWrappingImplementation implements Worker {
  _WorkerWrappingImplementation() : super() {}

  static create__WorkerWrappingImplementation() native {
    return new _WorkerWrappingImplementation();
  }

  EventListener get onmessage() { return _get__Worker_onmessage(this); }
  static EventListener _get__Worker_onmessage(var _this) native;

  void set onmessage(EventListener value) { _set__Worker_onmessage(this, value); }
  static void _set__Worker_onmessage(var _this, EventListener value) native;

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

  void terminate() {
    _terminate(this);
    return;
  }
  static void _terminate(receiver) native;

  void webkitPostMessage(String message, [List messagePorts = null]) {
    if (messagePorts === null) {
      _webkitPostMessage(this, message);
      return;
    } else {
      _webkitPostMessage_2(this, message, messagePorts);
      return;
    }
  }
  static void _webkitPostMessage(receiver, message) native;
  static void _webkitPostMessage_2(receiver, message, messagePorts) native;

  String get typeName() { return "Worker"; }
}

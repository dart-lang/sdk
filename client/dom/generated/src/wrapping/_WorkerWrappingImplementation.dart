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

  void postMessage(String message, [MessagePort messagePort = null]) {
    if (messagePort === null) {
      _postMessage(this, message);
      return;
    } else {
      _postMessage_2(this, message, messagePort);
      return;
    }
  }
  static void _postMessage(receiver, message) native;
  static void _postMessage_2(receiver, message, messagePort) native;

  void terminate() {
    _terminate(this);
    return;
  }
  static void _terminate(receiver) native;

  String get typeName() { return "Worker"; }
}

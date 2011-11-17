// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DedicatedWorkerContextWrappingImplementation extends _WorkerContextWrappingImplementation implements DedicatedWorkerContext {
  _DedicatedWorkerContextWrappingImplementation() : super() {}

  static create__DedicatedWorkerContextWrappingImplementation() native {
    return new _DedicatedWorkerContextWrappingImplementation();
  }

  EventListener get onmessage() { return _get__DedicatedWorkerContext_onmessage(this); }
  static EventListener _get__DedicatedWorkerContext_onmessage(var _this) native;

  void set onmessage(EventListener value) { _set__DedicatedWorkerContext_onmessage(this, value); }
  static void _set__DedicatedWorkerContext_onmessage(var _this, EventListener value) native;

  void postMessage(Object message, [List messagePorts = null]) {
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

  void webkitPostMessage(Object message, [List transferList = null]) {
    if (transferList === null) {
      _webkitPostMessage(this, message);
      return;
    } else {
      _webkitPostMessage_2(this, message, transferList);
      return;
    }
  }
  static void _webkitPostMessage(receiver, message) native;
  static void _webkitPostMessage_2(receiver, message, transferList) native;

  String get typeName() { return "DedicatedWorkerContext"; }
}

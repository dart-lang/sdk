// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _AbstractWorkerWrappingImplementation extends DOMWrapperBase implements AbstractWorker {
  _AbstractWorkerWrappingImplementation() : super() {}

  static create__AbstractWorkerWrappingImplementation() native {
    return new _AbstractWorkerWrappingImplementation();
  }

  EventListener get onerror() { return _get_onerror(this); }
  static EventListener _get_onerror(var _this) native;

  void set onerror(EventListener value) { _set_onerror(this, value); }
  static void _set_onerror(var _this, EventListener value) native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _addEventListener_AbstractWorker(this, type, listener);
      return;
    } else {
      _addEventListener_AbstractWorker_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _addEventListener_AbstractWorker(receiver, type, listener) native;
  static void _addEventListener_AbstractWorker_2(receiver, type, listener, useCapture) native;

  bool dispatchEvent(Event evt) {
    return _dispatchEvent_AbstractWorker(this, evt);
  }
  static bool _dispatchEvent_AbstractWorker(receiver, evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _removeEventListener_AbstractWorker(this, type, listener);
      return;
    } else {
      _removeEventListener_AbstractWorker_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _removeEventListener_AbstractWorker(receiver, type, listener) native;
  static void _removeEventListener_AbstractWorker_2(receiver, type, listener, useCapture) native;

  String get typeName() { return "AbstractWorker"; }
}

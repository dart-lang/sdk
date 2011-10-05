// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _IDBTransactionWrappingImplementation extends DOMWrapperBase implements IDBTransaction {
  _IDBTransactionWrappingImplementation() : super() {}

  static create__IDBTransactionWrappingImplementation() native {
    return new _IDBTransactionWrappingImplementation();
  }

  IDBDatabase get db() { return _get__IDBTransaction_db(this); }
  static IDBDatabase _get__IDBTransaction_db(var _this) native;

  int get mode() { return _get__IDBTransaction_mode(this); }
  static int _get__IDBTransaction_mode(var _this) native;

  EventListener get onabort() { return _get__IDBTransaction_onabort(this); }
  static EventListener _get__IDBTransaction_onabort(var _this) native;

  void set onabort(EventListener value) { _set__IDBTransaction_onabort(this, value); }
  static void _set__IDBTransaction_onabort(var _this, EventListener value) native;

  EventListener get oncomplete() { return _get__IDBTransaction_oncomplete(this); }
  static EventListener _get__IDBTransaction_oncomplete(var _this) native;

  void set oncomplete(EventListener value) { _set__IDBTransaction_oncomplete(this, value); }
  static void _set__IDBTransaction_oncomplete(var _this, EventListener value) native;

  EventListener get onerror() { return _get__IDBTransaction_onerror(this); }
  static EventListener _get__IDBTransaction_onerror(var _this) native;

  void set onerror(EventListener value) { _set__IDBTransaction_onerror(this, value); }
  static void _set__IDBTransaction_onerror(var _this, EventListener value) native;

  void abort() {
    _abort(this);
    return;
  }
  static void _abort(receiver) native;

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

  bool dispatchEvent(Event evt) {
    return _dispatchEvent(this, evt);
  }
  static bool _dispatchEvent(receiver, evt) native;

  IDBObjectStore objectStore(String name) {
    return _objectStore(this, name);
  }
  static IDBObjectStore _objectStore(receiver, name) native;

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

  String get typeName() { return "IDBTransaction"; }
}

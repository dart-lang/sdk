// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _IDBRequestWrappingImplementation extends DOMWrapperBase implements IDBRequest {
  _IDBRequestWrappingImplementation() : super() {}

  static create__IDBRequestWrappingImplementation() native {
    return new _IDBRequestWrappingImplementation();
  }

  int get errorCode() { return _get__IDBRequest_errorCode(this); }
  static int _get__IDBRequest_errorCode(var _this) native;

  EventListener get onerror() { return _get__IDBRequest_onerror(this); }
  static EventListener _get__IDBRequest_onerror(var _this) native;

  void set onerror(EventListener value) { _set__IDBRequest_onerror(this, value); }
  static void _set__IDBRequest_onerror(var _this, EventListener value) native;

  EventListener get onsuccess() { return _get__IDBRequest_onsuccess(this); }
  static EventListener _get__IDBRequest_onsuccess(var _this) native;

  void set onsuccess(EventListener value) { _set__IDBRequest_onsuccess(this, value); }
  static void _set__IDBRequest_onsuccess(var _this, EventListener value) native;

  int get readyState() { return _get__IDBRequest_readyState(this); }
  static int _get__IDBRequest_readyState(var _this) native;

  IDBAny get result() { return _get__IDBRequest_result(this); }
  static IDBAny _get__IDBRequest_result(var _this) native;

  IDBAny get source() { return _get__IDBRequest_source(this); }
  static IDBAny _get__IDBRequest_source(var _this) native;

  IDBTransaction get transaction() { return _get__IDBRequest_transaction(this); }
  static IDBTransaction _get__IDBRequest_transaction(var _this) native;

  String get webkitErrorMessage() { return _get__IDBRequest_webkitErrorMessage(this); }
  static String _get__IDBRequest_webkitErrorMessage(var _this) native;

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

  String get typeName() { return "IDBRequest"; }
}

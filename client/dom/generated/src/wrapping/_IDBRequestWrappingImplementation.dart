// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _IDBRequestWrappingImplementation extends DOMWrapperBase implements IDBRequest {
  _IDBRequestWrappingImplementation() : super() {}

  static create__IDBRequestWrappingImplementation() native {
    return new _IDBRequestWrappingImplementation();
  }

  int get errorCode() { return _get_errorCode(this); }
  static int _get_errorCode(var _this) native;

  int get readyState() { return _get_readyState(this); }
  static int _get_readyState(var _this) native;

  IDBAny get result() { return _get_result(this); }
  static IDBAny _get_result(var _this) native;

  IDBAny get source() { return _get_source(this); }
  static IDBAny _get_source(var _this) native;

  IDBTransaction get transaction() { return _get_transaction(this); }
  static IDBTransaction _get_transaction(var _this) native;

  String get webkitErrorMessage() { return _get_webkitErrorMessage(this); }
  static String _get_webkitErrorMessage(var _this) native;

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

  bool dispatchEvent(Event evt) {
    return _dispatchEvent(this, evt);
  }
  static bool _dispatchEvent(receiver, evt) native;

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

  String get typeName() { return "IDBRequest"; }
}

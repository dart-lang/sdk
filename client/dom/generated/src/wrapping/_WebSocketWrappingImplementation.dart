// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WebSocketWrappingImplementation extends DOMWrapperBase implements WebSocket {
  _WebSocketWrappingImplementation() : super() {}

  static create__WebSocketWrappingImplementation() native {
    return new _WebSocketWrappingImplementation();
  }

  String get URL() { return _get__WebSocket_URL(this); }
  static String _get__WebSocket_URL(var _this) native;

  String get binaryType() { return _get__WebSocket_binaryType(this); }
  static String _get__WebSocket_binaryType(var _this) native;

  void set binaryType(String value) { _set__WebSocket_binaryType(this, value); }
  static void _set__WebSocket_binaryType(var _this, String value) native;

  int get bufferedAmount() { return _get__WebSocket_bufferedAmount(this); }
  static int _get__WebSocket_bufferedAmount(var _this) native;

  EventListener get onclose() { return _get__WebSocket_onclose(this); }
  static EventListener _get__WebSocket_onclose(var _this) native;

  void set onclose(EventListener value) { _set__WebSocket_onclose(this, value); }
  static void _set__WebSocket_onclose(var _this, EventListener value) native;

  EventListener get onerror() { return _get__WebSocket_onerror(this); }
  static EventListener _get__WebSocket_onerror(var _this) native;

  void set onerror(EventListener value) { _set__WebSocket_onerror(this, value); }
  static void _set__WebSocket_onerror(var _this, EventListener value) native;

  EventListener get onmessage() { return _get__WebSocket_onmessage(this); }
  static EventListener _get__WebSocket_onmessage(var _this) native;

  void set onmessage(EventListener value) { _set__WebSocket_onmessage(this, value); }
  static void _set__WebSocket_onmessage(var _this, EventListener value) native;

  EventListener get onopen() { return _get__WebSocket_onopen(this); }
  static EventListener _get__WebSocket_onopen(var _this) native;

  void set onopen(EventListener value) { _set__WebSocket_onopen(this, value); }
  static void _set__WebSocket_onopen(var _this, EventListener value) native;

  String get protocol() { return _get__WebSocket_protocol(this); }
  static String _get__WebSocket_protocol(var _this) native;

  int get readyState() { return _get__WebSocket_readyState(this); }
  static int _get__WebSocket_readyState(var _this) native;

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

  void close([int code = null, String reason = null]) {
    if (code === null) {
      if (reason === null) {
        _close(this);
        return;
      }
    } else {
      if (reason === null) {
        _close_2(this, code);
        return;
      } else {
        _close_3(this, code, reason);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _close(receiver) native;
  static void _close_2(receiver, code) native;
  static void _close_3(receiver, code, reason) native;

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

  bool send(String data) {
    return _send(this, data);
  }
  static bool _send(receiver, data) native;

  String get typeName() { return "WebSocket"; }
}

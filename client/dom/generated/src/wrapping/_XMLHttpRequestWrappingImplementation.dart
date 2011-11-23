// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _XMLHttpRequestWrappingImplementation extends DOMWrapperBase implements XMLHttpRequest {
  _XMLHttpRequestWrappingImplementation() : super() {}

  static create__XMLHttpRequestWrappingImplementation() native {
    return new _XMLHttpRequestWrappingImplementation();
  }

  bool get asBlob() { return _get_asBlob(this); }
  static bool _get_asBlob(var _this) native;

  void set asBlob(bool value) { _set_asBlob(this, value); }
  static void _set_asBlob(var _this, bool value) native;

  int get readyState() { return _get_readyState(this); }
  static int _get_readyState(var _this) native;

  Blob get responseBlob() { return _get_responseBlob(this); }
  static Blob _get_responseBlob(var _this) native;

  String get responseText() { return _get_responseText(this); }
  static String _get_responseText(var _this) native;

  String get responseType() { return _get_responseType(this); }
  static String _get_responseType(var _this) native;

  void set responseType(String value) { _set_responseType(this, value); }
  static void _set_responseType(var _this, String value) native;

  Document get responseXML() { return _get_responseXML(this); }
  static Document _get_responseXML(var _this) native;

  int get status() { return _get_status(this); }
  static int _get_status(var _this) native;

  String get statusText() { return _get_statusText(this); }
  static String _get_statusText(var _this) native;

  XMLHttpRequestUpload get upload() { return _get_upload(this); }
  static XMLHttpRequestUpload _get_upload(var _this) native;

  bool get withCredentials() { return _get_withCredentials(this); }
  static bool _get_withCredentials(var _this) native;

  void set withCredentials(bool value) { _set_withCredentials(this, value); }
  static void _set_withCredentials(var _this, bool value) native;

  void abort() {
    _abort(this);
    return;
  }
  static void _abort(receiver) native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _addEventListener_XMLHttpRequest(this, type, listener);
      return;
    } else {
      _addEventListener_XMLHttpRequest_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _addEventListener_XMLHttpRequest(receiver, type, listener) native;
  static void _addEventListener_XMLHttpRequest_2(receiver, type, listener, useCapture) native;

  bool dispatchEvent(Event evt) {
    return _dispatchEvent_XMLHttpRequest(this, evt);
  }
  static bool _dispatchEvent_XMLHttpRequest(receiver, evt) native;

  String getAllResponseHeaders() {
    return _getAllResponseHeaders(this);
  }
  static String _getAllResponseHeaders(receiver) native;

  String getResponseHeader(String header) {
    return _getResponseHeader(this, header);
  }
  static String _getResponseHeader(receiver, header) native;

  void open(String method, String url, [bool async = null, String user = null, String password = null]) {
    if (async === null) {
      if (user === null) {
        if (password === null) {
          _open(this, method, url);
          return;
        }
      }
    } else {
      if (user === null) {
        if (password === null) {
          _open_2(this, method, url, async);
          return;
        }
      } else {
        if (password === null) {
          _open_3(this, method, url, async, user);
          return;
        } else {
          _open_4(this, method, url, async, user, password);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _open(receiver, method, url) native;
  static void _open_2(receiver, method, url, async) native;
  static void _open_3(receiver, method, url, async, user) native;
  static void _open_4(receiver, method, url, async, user, password) native;

  void overrideMimeType(String override) {
    _overrideMimeType(this, override);
    return;
  }
  static void _overrideMimeType(receiver, override) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _removeEventListener_XMLHttpRequest(this, type, listener);
      return;
    } else {
      _removeEventListener_XMLHttpRequest_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _removeEventListener_XMLHttpRequest(receiver, type, listener) native;
  static void _removeEventListener_XMLHttpRequest_2(receiver, type, listener, useCapture) native;

  void send([var data = null]) {
    if (data === null) {
      _send(this);
      return;
    } else {
      if (data is ArrayBuffer) {
        _send_2(this, data);
        return;
      } else {
        if (data is Blob) {
          _send_3(this, data);
          return;
        } else {
          if (data is Document) {
            _send_4(this, data);
            return;
          } else {
            if (data is String) {
              _send_5(this, data);
              return;
            } else {
              if (data is DOMFormData) {
                _send_6(this, data);
                return;
              }
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _send(receiver) native;
  static void _send_2(receiver, data) native;
  static void _send_3(receiver, data) native;
  static void _send_4(receiver, data) native;
  static void _send_5(receiver, data) native;
  static void _send_6(receiver, data) native;

  void setRequestHeader(String header, String value) {
    _setRequestHeader(this, header, value);
    return;
  }
  static void _setRequestHeader(receiver, header, value) native;

  String get typeName() { return "XMLHttpRequest"; }
}

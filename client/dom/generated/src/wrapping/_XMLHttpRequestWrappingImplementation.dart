// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _XMLHttpRequestWrappingImplementation extends DOMWrapperBase implements XMLHttpRequest {
  _XMLHttpRequestWrappingImplementation() : super() {}

  static create__XMLHttpRequestWrappingImplementation() native {
    return new _XMLHttpRequestWrappingImplementation();
  }

  bool get asBlob() { return _get__XMLHttpRequest_asBlob(this); }
  static bool _get__XMLHttpRequest_asBlob(var _this) native;

  void set asBlob(bool value) { _set__XMLHttpRequest_asBlob(this, value); }
  static void _set__XMLHttpRequest_asBlob(var _this, bool value) native;

  EventListener get onabort() { return _get__XMLHttpRequest_onabort(this); }
  static EventListener _get__XMLHttpRequest_onabort(var _this) native;

  void set onabort(EventListener value) { _set__XMLHttpRequest_onabort(this, value); }
  static void _set__XMLHttpRequest_onabort(var _this, EventListener value) native;

  EventListener get onerror() { return _get__XMLHttpRequest_onerror(this); }
  static EventListener _get__XMLHttpRequest_onerror(var _this) native;

  void set onerror(EventListener value) { _set__XMLHttpRequest_onerror(this, value); }
  static void _set__XMLHttpRequest_onerror(var _this, EventListener value) native;

  EventListener get onload() { return _get__XMLHttpRequest_onload(this); }
  static EventListener _get__XMLHttpRequest_onload(var _this) native;

  void set onload(EventListener value) { _set__XMLHttpRequest_onload(this, value); }
  static void _set__XMLHttpRequest_onload(var _this, EventListener value) native;

  EventListener get onloadstart() { return _get__XMLHttpRequest_onloadstart(this); }
  static EventListener _get__XMLHttpRequest_onloadstart(var _this) native;

  void set onloadstart(EventListener value) { _set__XMLHttpRequest_onloadstart(this, value); }
  static void _set__XMLHttpRequest_onloadstart(var _this, EventListener value) native;

  EventListener get onprogress() { return _get__XMLHttpRequest_onprogress(this); }
  static EventListener _get__XMLHttpRequest_onprogress(var _this) native;

  void set onprogress(EventListener value) { _set__XMLHttpRequest_onprogress(this, value); }
  static void _set__XMLHttpRequest_onprogress(var _this, EventListener value) native;

  EventListener get onreadystatechange() { return _get__XMLHttpRequest_onreadystatechange(this); }
  static EventListener _get__XMLHttpRequest_onreadystatechange(var _this) native;

  void set onreadystatechange(EventListener value) { _set__XMLHttpRequest_onreadystatechange(this, value); }
  static void _set__XMLHttpRequest_onreadystatechange(var _this, EventListener value) native;

  int get readyState() { return _get__XMLHttpRequest_readyState(this); }
  static int _get__XMLHttpRequest_readyState(var _this) native;

  Blob get responseBlob() { return _get__XMLHttpRequest_responseBlob(this); }
  static Blob _get__XMLHttpRequest_responseBlob(var _this) native;

  String get responseText() { return _get__XMLHttpRequest_responseText(this); }
  static String _get__XMLHttpRequest_responseText(var _this) native;

  String get responseType() { return _get__XMLHttpRequest_responseType(this); }
  static String _get__XMLHttpRequest_responseType(var _this) native;

  void set responseType(String value) { _set__XMLHttpRequest_responseType(this, value); }
  static void _set__XMLHttpRequest_responseType(var _this, String value) native;

  Document get responseXML() { return _get__XMLHttpRequest_responseXML(this); }
  static Document _get__XMLHttpRequest_responseXML(var _this) native;

  int get status() { return _get__XMLHttpRequest_status(this); }
  static int _get__XMLHttpRequest_status(var _this) native;

  String get statusText() { return _get__XMLHttpRequest_statusText(this); }
  static String _get__XMLHttpRequest_statusText(var _this) native;

  XMLHttpRequestUpload get upload() { return _get__XMLHttpRequest_upload(this); }
  static XMLHttpRequestUpload _get__XMLHttpRequest_upload(var _this) native;

  bool get withCredentials() { return _get__XMLHttpRequest_withCredentials(this); }
  static bool _get__XMLHttpRequest_withCredentials(var _this) native;

  void set withCredentials(bool value) { _set__XMLHttpRequest_withCredentials(this, value); }
  static void _set__XMLHttpRequest_withCredentials(var _this, bool value) native;

  void abort() {
    _abort(this);
    return;
  }
  static void _abort(receiver) native;

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

  String getAllResponseHeaders() {
    return _getAllResponseHeaders(this);
  }
  static String _getAllResponseHeaders(receiver) native;

  String getResponseHeader(String header) {
    return _getResponseHeader(this, header);
  }
  static String _getResponseHeader(receiver, header) native;

  void open(String method, String url, bool async, [String user = null, String password = null]) {
    if (user === null) {
      if (password === null) {
        _open(this, method, url, async);
        return;
      }
    } else {
      if (password === null) {
        _open_2(this, method, url, async, user);
        return;
      } else {
        _open_3(this, method, url, async, user, password);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _open(receiver, method, url, async) native;
  static void _open_2(receiver, method, url, async, user) native;
  static void _open_3(receiver, method, url, async, user, password) native;

  void overrideMimeType(String override) {
    _overrideMimeType(this, override);
    return;
  }
  static void _overrideMimeType(receiver, override) native;

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

  void send([var data = null]) {
    if (data === null) {
      _send(this);
      return;
    } else {
      if (data is String) {
        _send_2(this, data);
        return;
      } else {
        if (data is Document) {
          _send_3(this, data);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _send(receiver) native;
  static void _send_2(receiver, data) native;
  static void _send_3(receiver, data) native;

  void setRequestHeader(String header, String value) {
    _setRequestHeader(this, header, value);
    return;
  }
  static void _setRequestHeader(receiver, header, value) native;

  String get typeName() { return "XMLHttpRequest"; }
}

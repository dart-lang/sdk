// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _XMLHttpRequestUploadWrappingImplementation extends DOMWrapperBase implements XMLHttpRequestUpload {
  _XMLHttpRequestUploadWrappingImplementation() : super() {}

  static create__XMLHttpRequestUploadWrappingImplementation() native {
    return new _XMLHttpRequestUploadWrappingImplementation();
  }

  EventListener get onabort() { return _get_onabort(this); }
  static EventListener _get_onabort(var _this) native;

  void set onabort(EventListener value) { _set_onabort(this, value); }
  static void _set_onabort(var _this, EventListener value) native;

  EventListener get onerror() { return _get_onerror(this); }
  static EventListener _get_onerror(var _this) native;

  void set onerror(EventListener value) { _set_onerror(this, value); }
  static void _set_onerror(var _this, EventListener value) native;

  EventListener get onload() { return _get_onload(this); }
  static EventListener _get_onload(var _this) native;

  void set onload(EventListener value) { _set_onload(this, value); }
  static void _set_onload(var _this, EventListener value) native;

  EventListener get onloadstart() { return _get_onloadstart(this); }
  static EventListener _get_onloadstart(var _this) native;

  void set onloadstart(EventListener value) { _set_onloadstart(this, value); }
  static void _set_onloadstart(var _this, EventListener value) native;

  EventListener get onprogress() { return _get_onprogress(this); }
  static EventListener _get_onprogress(var _this) native;

  void set onprogress(EventListener value) { _set_onprogress(this, value); }
  static void _set_onprogress(var _this, EventListener value) native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _addEventListener_XMLHttpRequestUpload(this, type, listener);
      return;
    } else {
      _addEventListener_XMLHttpRequestUpload_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _addEventListener_XMLHttpRequestUpload(receiver, type, listener) native;
  static void _addEventListener_XMLHttpRequestUpload_2(receiver, type, listener, useCapture) native;

  bool dispatchEvent(Event evt) {
    return _dispatchEvent_XMLHttpRequestUpload(this, evt);
  }
  static bool _dispatchEvent_XMLHttpRequestUpload(receiver, evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _removeEventListener_XMLHttpRequestUpload(this, type, listener);
      return;
    } else {
      _removeEventListener_XMLHttpRequestUpload_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _removeEventListener_XMLHttpRequestUpload(receiver, type, listener) native;
  static void _removeEventListener_XMLHttpRequestUpload_2(receiver, type, listener, useCapture) native;

  String get typeName() { return "XMLHttpRequestUpload"; }
}

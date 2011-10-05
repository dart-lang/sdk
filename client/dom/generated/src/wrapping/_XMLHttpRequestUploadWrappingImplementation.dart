// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _XMLHttpRequestUploadWrappingImplementation extends DOMWrapperBase implements XMLHttpRequestUpload {
  _XMLHttpRequestUploadWrappingImplementation() : super() {}

  static create__XMLHttpRequestUploadWrappingImplementation() native {
    return new _XMLHttpRequestUploadWrappingImplementation();
  }

  EventListener get onabort() { return _get__XMLHttpRequestUpload_onabort(this); }
  static EventListener _get__XMLHttpRequestUpload_onabort(var _this) native;

  void set onabort(EventListener value) { _set__XMLHttpRequestUpload_onabort(this, value); }
  static void _set__XMLHttpRequestUpload_onabort(var _this, EventListener value) native;

  EventListener get onerror() { return _get__XMLHttpRequestUpload_onerror(this); }
  static EventListener _get__XMLHttpRequestUpload_onerror(var _this) native;

  void set onerror(EventListener value) { _set__XMLHttpRequestUpload_onerror(this, value); }
  static void _set__XMLHttpRequestUpload_onerror(var _this, EventListener value) native;

  EventListener get onload() { return _get__XMLHttpRequestUpload_onload(this); }
  static EventListener _get__XMLHttpRequestUpload_onload(var _this) native;

  void set onload(EventListener value) { _set__XMLHttpRequestUpload_onload(this, value); }
  static void _set__XMLHttpRequestUpload_onload(var _this, EventListener value) native;

  EventListener get onloadstart() { return _get__XMLHttpRequestUpload_onloadstart(this); }
  static EventListener _get__XMLHttpRequestUpload_onloadstart(var _this) native;

  void set onloadstart(EventListener value) { _set__XMLHttpRequestUpload_onloadstart(this, value); }
  static void _set__XMLHttpRequestUpload_onloadstart(var _this, EventListener value) native;

  EventListener get onprogress() { return _get__XMLHttpRequestUpload_onprogress(this); }
  static EventListener _get__XMLHttpRequestUpload_onprogress(var _this) native;

  void set onprogress(EventListener value) { _set__XMLHttpRequestUpload_onprogress(this, value); }
  static void _set__XMLHttpRequestUpload_onprogress(var _this, EventListener value) native;

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

  String get typeName() { return "XMLHttpRequestUpload"; }
}

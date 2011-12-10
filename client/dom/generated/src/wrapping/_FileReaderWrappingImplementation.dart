// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _FileReaderWrappingImplementation extends DOMWrapperBase implements FileReader {
  _FileReaderWrappingImplementation() : super() {}

  static create__FileReaderWrappingImplementation() native {
    return new _FileReaderWrappingImplementation();
  }

  FileError get error() { return _get_error(this); }
  static FileError _get_error(var _this) native;

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

  EventListener get onloadend() { return _get_onloadend(this); }
  static EventListener _get_onloadend(var _this) native;

  void set onloadend(EventListener value) { _set_onloadend(this, value); }
  static void _set_onloadend(var _this, EventListener value) native;

  EventListener get onloadstart() { return _get_onloadstart(this); }
  static EventListener _get_onloadstart(var _this) native;

  void set onloadstart(EventListener value) { _set_onloadstart(this, value); }
  static void _set_onloadstart(var _this, EventListener value) native;

  EventListener get onprogress() { return _get_onprogress(this); }
  static EventListener _get_onprogress(var _this) native;

  void set onprogress(EventListener value) { _set_onprogress(this, value); }
  static void _set_onprogress(var _this, EventListener value) native;

  int get readyState() { return _get_readyState(this); }
  static int _get_readyState(var _this) native;

  Object get result() { return _get_result(this); }
  static Object _get_result(var _this) native;

  void abort() {
    _abort(this);
    return;
  }
  static void _abort(receiver) native;

  void readAsArrayBuffer(Blob blob) {
    _readAsArrayBuffer(this, blob);
    return;
  }
  static void _readAsArrayBuffer(receiver, blob) native;

  void readAsBinaryString(Blob blob) {
    _readAsBinaryString(this, blob);
    return;
  }
  static void _readAsBinaryString(receiver, blob) native;

  void readAsDataURL(Blob blob) {
    _readAsDataURL(this, blob);
    return;
  }
  static void _readAsDataURL(receiver, blob) native;

  void readAsText(Blob blob, [String encoding = null]) {
    if (encoding === null) {
      _readAsText(this, blob);
      return;
    } else {
      _readAsText_2(this, blob, encoding);
      return;
    }
  }
  static void _readAsText(receiver, blob) native;
  static void _readAsText_2(receiver, blob, encoding) native;

  String get typeName() { return "FileReader"; }
}

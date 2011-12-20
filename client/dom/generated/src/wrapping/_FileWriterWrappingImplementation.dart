// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _FileWriterWrappingImplementation extends DOMWrapperBase implements FileWriter {
  _FileWriterWrappingImplementation() : super() {}

  static create__FileWriterWrappingImplementation() native {
    return new _FileWriterWrappingImplementation();
  }

  FileError get error() { return _get_error(this); }
  static FileError _get_error(var _this) native;

  int get length() { return _get_length(this); }
  static int _get_length(var _this) native;

  EventListener get onabort() { return _get_onabort(this); }
  static EventListener _get_onabort(var _this) native;

  void set onabort(EventListener value) { _set_onabort(this, value); }
  static void _set_onabort(var _this, EventListener value) native;

  EventListener get onerror() { return _get_onerror(this); }
  static EventListener _get_onerror(var _this) native;

  void set onerror(EventListener value) { _set_onerror(this, value); }
  static void _set_onerror(var _this, EventListener value) native;

  EventListener get onprogress() { return _get_onprogress(this); }
  static EventListener _get_onprogress(var _this) native;

  void set onprogress(EventListener value) { _set_onprogress(this, value); }
  static void _set_onprogress(var _this, EventListener value) native;

  EventListener get onwrite() { return _get_onwrite(this); }
  static EventListener _get_onwrite(var _this) native;

  void set onwrite(EventListener value) { _set_onwrite(this, value); }
  static void _set_onwrite(var _this, EventListener value) native;

  EventListener get onwriteend() { return _get_onwriteend(this); }
  static EventListener _get_onwriteend(var _this) native;

  void set onwriteend(EventListener value) { _set_onwriteend(this, value); }
  static void _set_onwriteend(var _this, EventListener value) native;

  EventListener get onwritestart() { return _get_onwritestart(this); }
  static EventListener _get_onwritestart(var _this) native;

  void set onwritestart(EventListener value) { _set_onwritestart(this, value); }
  static void _set_onwritestart(var _this, EventListener value) native;

  int get position() { return _get_position(this); }
  static int _get_position(var _this) native;

  int get readyState() { return _get_readyState(this); }
  static int _get_readyState(var _this) native;

  void abort() {
    _abort(this);
    return;
  }
  static void _abort(receiver) native;

  void seek(int position) {
    _seek(this, position);
    return;
  }
  static void _seek(receiver, position) native;

  void truncate(int size) {
    _truncate(this, size);
    return;
  }
  static void _truncate(receiver, size) native;

  void write(Blob data) {
    _write(this, data);
    return;
  }
  static void _write(receiver, data) native;

  String get typeName() { return "FileWriter"; }
}

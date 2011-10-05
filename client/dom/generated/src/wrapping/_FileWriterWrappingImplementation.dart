// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _FileWriterWrappingImplementation extends DOMWrapperBase implements FileWriter {
  _FileWriterWrappingImplementation() : super() {}

  static create__FileWriterWrappingImplementation() native {
    return new _FileWriterWrappingImplementation();
  }

  FileError get error() { return _get__FileWriter_error(this); }
  static FileError _get__FileWriter_error(var _this) native;

  int get length() { return _get__FileWriter_length(this); }
  static int _get__FileWriter_length(var _this) native;

  EventListener get onabort() { return _get__FileWriter_onabort(this); }
  static EventListener _get__FileWriter_onabort(var _this) native;

  void set onabort(EventListener value) { _set__FileWriter_onabort(this, value); }
  static void _set__FileWriter_onabort(var _this, EventListener value) native;

  EventListener get onerror() { return _get__FileWriter_onerror(this); }
  static EventListener _get__FileWriter_onerror(var _this) native;

  void set onerror(EventListener value) { _set__FileWriter_onerror(this, value); }
  static void _set__FileWriter_onerror(var _this, EventListener value) native;

  EventListener get onprogress() { return _get__FileWriter_onprogress(this); }
  static EventListener _get__FileWriter_onprogress(var _this) native;

  void set onprogress(EventListener value) { _set__FileWriter_onprogress(this, value); }
  static void _set__FileWriter_onprogress(var _this, EventListener value) native;

  EventListener get onwrite() { return _get__FileWriter_onwrite(this); }
  static EventListener _get__FileWriter_onwrite(var _this) native;

  void set onwrite(EventListener value) { _set__FileWriter_onwrite(this, value); }
  static void _set__FileWriter_onwrite(var _this, EventListener value) native;

  EventListener get onwriteend() { return _get__FileWriter_onwriteend(this); }
  static EventListener _get__FileWriter_onwriteend(var _this) native;

  void set onwriteend(EventListener value) { _set__FileWriter_onwriteend(this, value); }
  static void _set__FileWriter_onwriteend(var _this, EventListener value) native;

  EventListener get onwritestart() { return _get__FileWriter_onwritestart(this); }
  static EventListener _get__FileWriter_onwritestart(var _this) native;

  void set onwritestart(EventListener value) { _set__FileWriter_onwritestart(this, value); }
  static void _set__FileWriter_onwritestart(var _this, EventListener value) native;

  int get position() { return _get__FileWriter_position(this); }
  static int _get__FileWriter_position(var _this) native;

  int get readyState() { return _get__FileWriter_readyState(this); }
  static int _get__FileWriter_readyState(var _this) native;

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

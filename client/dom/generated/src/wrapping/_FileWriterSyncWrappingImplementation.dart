// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _FileWriterSyncWrappingImplementation extends DOMWrapperBase implements FileWriterSync {
  _FileWriterSyncWrappingImplementation() : super() {}

  static create__FileWriterSyncWrappingImplementation() native {
    return new _FileWriterSyncWrappingImplementation();
  }

  int get length() { return _get__FileWriterSync_length(this); }
  static int _get__FileWriterSync_length(var _this) native;

  int get position() { return _get__FileWriterSync_position(this); }
  static int _get__FileWriterSync_position(var _this) native;

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

  String get typeName() { return "FileWriterSync"; }
}

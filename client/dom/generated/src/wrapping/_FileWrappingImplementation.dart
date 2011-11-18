// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _FileWrappingImplementation extends _BlobWrappingImplementation implements File {
  _FileWrappingImplementation() : super() {}

  static create__FileWrappingImplementation() native {
    return new _FileWrappingImplementation();
  }

  String get fileName() { return _get_fileName(this); }
  static String _get_fileName(var _this) native;

  int get fileSize() { return _get_fileSize(this); }
  static int _get_fileSize(var _this) native;

  Date get lastModifiedDate() { return _get_lastModifiedDate(this); }
  static Date _get_lastModifiedDate(var _this) native;

  String get name() { return _get_name(this); }
  static String _get_name(var _this) native;

  String get typeName() { return "File"; }
}

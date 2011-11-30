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

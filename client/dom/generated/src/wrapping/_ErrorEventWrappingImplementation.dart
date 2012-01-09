// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ErrorEventWrappingImplementation extends _EventWrappingImplementation implements ErrorEvent {
  _ErrorEventWrappingImplementation() : super() {}

  static create__ErrorEventWrappingImplementation() native {
    return new _ErrorEventWrappingImplementation();
  }

  String get filename() { return _get_filename(this); }
  static String _get_filename(var _this) native;

  int get lineno() { return _get_lineno(this); }
  static int _get_lineno(var _this) native;

  String get message() { return _get_message(this); }
  static String _get_message(var _this) native;

  String get typeName() { return "ErrorEvent"; }
}

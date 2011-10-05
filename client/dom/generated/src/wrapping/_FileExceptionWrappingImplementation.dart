// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _FileExceptionWrappingImplementation extends DOMWrapperBase implements FileException {
  _FileExceptionWrappingImplementation() : super() {}

  static create__FileExceptionWrappingImplementation() native {
    return new _FileExceptionWrappingImplementation();
  }

  int get code() { return _get__FileException_code(this); }
  static int _get__FileException_code(var _this) native;

  String get message() { return _get__FileException_message(this); }
  static String _get__FileException_message(var _this) native;

  String get name() { return _get__FileException_name(this); }
  static String _get__FileException_name(var _this) native;

  String get typeName() { return "FileException"; }
}

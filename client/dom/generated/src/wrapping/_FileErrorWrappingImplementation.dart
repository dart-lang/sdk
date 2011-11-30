// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _FileErrorWrappingImplementation extends DOMWrapperBase implements FileError {
  _FileErrorWrappingImplementation() : super() {}

  static create__FileErrorWrappingImplementation() native {
    return new _FileErrorWrappingImplementation();
  }

  int get code() { return _get_code(this); }
  static int _get_code(var _this) native;

  String get typeName() { return "FileError"; }
}

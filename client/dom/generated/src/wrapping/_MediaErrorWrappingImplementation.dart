// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MediaErrorWrappingImplementation extends DOMWrapperBase implements MediaError {
  _MediaErrorWrappingImplementation() : super() {}

  static create__MediaErrorWrappingImplementation() native {
    return new _MediaErrorWrappingImplementation();
  }

  int get code() { return _get__MediaError_code(this); }
  static int _get__MediaError_code(var _this) native;

  String get typeName() { return "MediaError"; }
}

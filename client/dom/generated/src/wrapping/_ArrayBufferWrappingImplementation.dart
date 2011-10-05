// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ArrayBufferWrappingImplementation extends DOMWrapperBase implements ArrayBuffer {
  _ArrayBufferWrappingImplementation() : super() {}

  static create__ArrayBufferWrappingImplementation() native {
    return new _ArrayBufferWrappingImplementation();
  }

  int get byteLength() { return _get__ArrayBuffer_byteLength(this); }
  static int _get__ArrayBuffer_byteLength(var _this) native;

  String get typeName() { return "ArrayBuffer"; }
}

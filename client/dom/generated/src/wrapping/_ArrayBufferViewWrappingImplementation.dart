// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ArrayBufferViewWrappingImplementation extends DOMWrapperBase implements ArrayBufferView {
  _ArrayBufferViewWrappingImplementation() : super() {}

  static create__ArrayBufferViewWrappingImplementation() native {
    return new _ArrayBufferViewWrappingImplementation();
  }

  ArrayBuffer get buffer() { return _get_buffer(this); }
  static ArrayBuffer _get_buffer(var _this) native;

  int get byteLength() { return _get_byteLength(this); }
  static int _get_byteLength(var _this) native;

  int get byteOffset() { return _get_byteOffset(this); }
  static int _get_byteOffset(var _this) native;

  String get typeName() { return "ArrayBufferView"; }
}

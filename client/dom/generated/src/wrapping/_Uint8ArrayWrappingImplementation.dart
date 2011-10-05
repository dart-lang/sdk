// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _Uint8ArrayWrappingImplementation extends _ArrayBufferViewWrappingImplementation implements Uint8Array {
  _Uint8ArrayWrappingImplementation() : super() {}

  static create__Uint8ArrayWrappingImplementation() native {
    return new _Uint8ArrayWrappingImplementation();
  }

  int get length() { return _get__Uint8Array_length(this); }
  static int _get__Uint8Array_length(var _this) native;

  Uint8Array subarray([int start = null, int end = null]) {
    if (start === null) {
      if (end === null) {
        return _subarray(this);
      }
    } else {
      if (end === null) {
        return _subarray_2(this, start);
      } else {
        return _subarray_3(this, start, end);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static Uint8Array _subarray(receiver) native;
  static Uint8Array _subarray_2(receiver, start) native;
  static Uint8Array _subarray_3(receiver, start, end) native;

  String get typeName() { return "Uint8Array"; }
}

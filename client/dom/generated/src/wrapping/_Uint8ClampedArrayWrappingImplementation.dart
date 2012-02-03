// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _Uint8ClampedArrayWrappingImplementation extends _Uint8ArrayWrappingImplementation implements Uint8ClampedArray {
  _Uint8ClampedArrayWrappingImplementation() : super() {}

  static create__Uint8ClampedArrayWrappingImplementation() native {
    return new _Uint8ClampedArrayWrappingImplementation();
  }

  int get length() { return _get_length_Uint8ClampedArray(this); }
  static int _get_length_Uint8ClampedArray(var _this) native;

  Uint8ClampedArray subarray(int start, [int end = null]) {
    if (end === null) {
      return _subarray_Uint8ClampedArray(this, start);
    } else {
      return _subarray_Uint8ClampedArray_2(this, start, end);
    }
  }
  static Uint8ClampedArray _subarray_Uint8ClampedArray(receiver, start) native;
  static Uint8ClampedArray _subarray_Uint8ClampedArray_2(receiver, start, end) native;

  String get typeName() { return "Uint8ClampedArray"; }
}

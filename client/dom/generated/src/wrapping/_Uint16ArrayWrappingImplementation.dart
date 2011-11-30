// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _Uint16ArrayWrappingImplementation extends _ArrayBufferViewWrappingImplementation implements Uint16Array {
  _Uint16ArrayWrappingImplementation() : super() {}

  static create__Uint16ArrayWrappingImplementation() native {
    return new _Uint16ArrayWrappingImplementation();
  }

  int get length() { return _get_length(this); }
  static int _get_length(var _this) native;

  Uint16Array subarray(int start, [int end = null]) {
    if (end === null) {
      return _subarray(this, start);
    } else {
      return _subarray_2(this, start, end);
    }
  }
  static Uint16Array _subarray(receiver, start) native;
  static Uint16Array _subarray_2(receiver, start, end) native;

  String get typeName() { return "Uint16Array"; }
}

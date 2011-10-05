// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _Int16ArrayWrappingImplementation extends _ArrayBufferViewWrappingImplementation implements Int16Array {
  _Int16ArrayWrappingImplementation() : super() {}

  static create__Int16ArrayWrappingImplementation() native {
    return new _Int16ArrayWrappingImplementation();
  }

  int get length() { return _get__Int16Array_length(this); }
  static int _get__Int16Array_length(var _this) native;

  Int16Array subarray([int start = null, int end = null]) {
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
  static Int16Array _subarray(receiver) native;
  static Int16Array _subarray_2(receiver, start) native;
  static Int16Array _subarray_3(receiver, start, end) native;

  String get typeName() { return "Int16Array"; }
}

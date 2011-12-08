// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Int32ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Int32Array {
  Int32ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Int32Array subarray(int start, [int end]) {
    if (end === null) {
      return LevelDom.wrapInt32Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapInt32Array(_ptr.subarray(start, end));
    }
  }
}

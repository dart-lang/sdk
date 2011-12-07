// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Float32ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Float32Array {
  Float32ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Float32Array subarray(int start, [int end]) {
    if (end === null) {
      return LevelDom.wrapFloat32Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapFloat32Array(_ptr.subarray(start, end));
    }
  }
}

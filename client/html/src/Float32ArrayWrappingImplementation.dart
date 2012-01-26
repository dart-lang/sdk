// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Float32ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Float32Array {
  Float32ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  factory Float32ArrayWrappingImplementation(int length) =>
    LevelDom.wrapFloat32Array(new dom.Float32Array(length));

  factory Float32ArrayWrappingImplementation.from(List<num> list) =>
    // TODO(nweiz): when there's a cross-platform name for the native
    // implementation of List, check if [list] is native and if not convert it
    // to a native list before sending it to the JS constructor.
    LevelDom.wrapFloat32Array(new dom.Float32Array.fromList(list));

  factory Float32ArrayWrappingImplementation.fromBuffer(ArrayBuffer buffer) =>
    LevelDom.wrapFloat32Array(new dom.Float32Array.fromBuffer(LevelDom.unwrap(buffer)));

  int get length() { return _ptr.length; }

  Float32Array subarray(int start, [int end]) {
    if (end === null) {
      return LevelDom.wrapFloat32Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapFloat32Array(_ptr.subarray(start, end));
    }
  }
}

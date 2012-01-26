// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Int32ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Int32Array {
  Int32ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  factory Int32ArrayWrappingImplementation(int length) =>
    LevelDom.wrapInt32Array(new dom.Int32Array(length));

  factory Int32ArrayWrappingImplementation.from(List<num> list) =>
    // TODO(nweiz): when there's a cross-platform name for the native
    // implementation of List, check if [list] is native and if not convert it
    // to a native list before sending it to the JS constructor.
    LevelDom.wrapInt32Array(new dom.Int32Array.fromList(list));

  factory Int32ArrayWrappingImplementation.fromBuffer(ArrayBuffer buffer) =>
    LevelDom.wrapInt32Array(new dom.Int32Array.fromBuffer(LevelDom.unwrap(buffer)));

  int get length() { return _ptr.length; }

  Int32Array subarray(int start, [int end]) {
    if (end === null) {
      return LevelDom.wrapInt32Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapInt32Array(_ptr.subarray(start, end));
    }
  }
}

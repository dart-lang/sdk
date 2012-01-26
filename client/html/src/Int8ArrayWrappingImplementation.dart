// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Int8ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Int8Array {
  Int8ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  factory Int8ArrayWrappingImplementation(int length) =>
    LevelDom.wrapInt8Array(new dom.Int8Array(length));

  factory Int8ArrayWrappingImplementation.from(List<num> list) =>
    // TODO(nweiz): when there's a cross-platform name for the native
    // implementation of List, check if [list] is native and if not convert it
    // to a native list before sending it to the JS constructor.
    LevelDom.wrapInt8Array(new dom.Int8Array.fromList(list));

  factory Int8ArrayWrappingImplementation.fromBuffer(ArrayBuffer buffer) =>
    LevelDom.wrapInt8Array(new dom.Int8Array.fromBuffer(LevelDom.unwrap(buffer)));

  int get length() { return _ptr.length; }

  Int8Array subarray(int start, [int end]) {
    if (end === null) {
      return LevelDom.wrapInt8Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapInt8Array(_ptr.subarray(start, end));
    }
  }
}

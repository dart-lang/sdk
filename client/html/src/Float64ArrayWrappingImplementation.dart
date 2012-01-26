// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Float64ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Float64Array {
  Float64ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  factory Float64ArrayWrappingImplementation(int length) =>
    LevelDom.wrapFloat64Array(new dom.Float64Array(length));

  factory Float64ArrayWrappingImplementation.from(List<num> list) =>
    // TODO(nweiz): when there's a cross-platform name for the native
    // implementation of List, check if [list] is native and if not convert it
    // to a native list before sending it to the JS constructor.
    LevelDom.wrapFloat64Array(new dom.Float64Array.fromList(list));

  factory Float64ArrayWrappingImplementation.fromBuffer(ArrayBuffer buffer) =>
    LevelDom.wrapFloat64Array(new dom.Float64Array.fromBuffer(LevelDom.unwrap(buffer)));

  int get length() { return _ptr.length; }

  Float64Array subarray(int start, [int end]) {
    if (end === null) {
      return LevelDom.wrapFloat64Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapFloat64Array(_ptr.subarray(start, end));
    }
  }
}

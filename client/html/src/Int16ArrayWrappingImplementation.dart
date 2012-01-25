// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Int16ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Int16Array {
  Int16ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  factory Int16ArrayWrappingImplementation(int length) =>
    LevelDom.wrapInt16Array(new dom.Int16Array(length));

  factory Int16ArrayWrappingImplementation.from(List<num> list) =>
    // TODO(nweiz): when there's a cross-platform name for the native
    // implementation of List, check if [list] is native and if not convert it
    // to a native list before sending it to the JS constructor.
    LevelDom.wrapInt16Array(new dom.Int16Array.fromList(list));

  factory Int16ArrayWrappingImplementation.fromBuffer(ArrayBuffer buffer) =>
    LevelDom.wrapInt16Array(new dom.Int16Array.fromBuffer(LevelDom.unwrap(buffer)));

  int get length() { return _ptr.length; }

  Int16Array subarray(int start, [int end]) {
    if (end === null) {
      return LevelDom.wrapInt16Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapInt16Array(_ptr.subarray(start, end));
    }
  }
}

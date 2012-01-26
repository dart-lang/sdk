// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Uint32ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Uint32Array {
  Uint32ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  factory Uint32ArrayWrappingImplementation(int length) =>
    LevelDom.wrapUint32Array(new dom.Uint32Array(length));

  factory Uint32ArrayWrappingImplementation.from(List<num> list) =>
    // TODO(nweiz): when there's a cross-platform name for the native
    // implementation of List, check if [list] is native and if not convert it
    // to a native list before sending it to the JS constructor.
    LevelDom.wrapUint32Array(new dom.Uint32Array.fromList(list));

  factory Uint32ArrayWrappingImplementation.fromBuffer(ArrayBuffer buffer) =>
    LevelDom.wrapUint32Array(new dom.Uint32Array.fromBuffer(LevelDom.unwrap(buffer)));

  int get length() { return _ptr.length; }

  Uint32Array subarray(int start, [int end]) {
    if (end === null) {
      return LevelDom.wrapUint32Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapUint32Array(_ptr.subarray(start, end));
    }
  }
}

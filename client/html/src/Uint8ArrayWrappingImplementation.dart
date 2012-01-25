// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Uint8ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Uint8Array {
  Uint8ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  factory Uint8ArrayWrappingImplementation(int length) =>
    LevelDom.wrapUint8Array(new dom.Uint8Array(length));

  factory Uint8ArrayWrappingImplementation.from(List<num> list) =>
    // TODO(nweiz): when there's a cross-platform name for the native
    // implementation of List, check if [list] is native and if not convert it
    // to a native list before sending it to the JS constructor.
    LevelDom.wrapUint8Array(new dom.Uint8Array.fromList(list));

  factory Uint8ArrayWrappingImplementation.fromBuffer(ArrayBuffer buffer) =>
    LevelDom.wrapUint8Array(new dom.Uint8Array.fromBuffer(LevelDom.unwrap(buffer)));

  int get length() { return _ptr.length; }

  Uint8Array subarray(int start, [int end]) {
    if (end === null) {
      return LevelDom.wrapUint8Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapUint8Array(_ptr.subarray(start, end));
    }
  }
}

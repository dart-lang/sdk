// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Uint16ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Uint16Array {
  Uint16ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  factory Uint16ArrayWrappingImplementation(int length) =>
    LevelDom.wrapUint16Array(new dom.Uint16Array(length));

  factory Uint16ArrayWrappingImplementation.from(List<num> list) =>
    // TODO(nweiz): when there's a cross-platform name for the native
    // implementation of List, check if [list] is native and if not convert it
    // to a native list before sending it to the JS constructor.
    LevelDom.wrapUint16Array(new dom.Uint16Array.fromList(list));

  factory Uint16ArrayWrappingImplementation.fromBuffer(ArrayBuffer buffer) =>
    LevelDom.wrapUint16Array(new dom.Uint16Array.fromBuffer(LevelDom.unwrap(buffer)));

  int get length() { return _ptr.length; }

  Uint16Array subarray(int start, [int end]) {
    if (end === null) {
      return LevelDom.wrapUint16Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapUint16Array(_ptr.subarray(start, end));
    }
  }
}

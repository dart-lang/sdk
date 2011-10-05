// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Uint32ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Uint32Array {
  Uint32ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Uint32Array subarray(int start, int end) {
    return LevelDom.wrapUint32Array(_ptr.subarray(start, end));
  }

  String get typeName() { return "Uint32Array"; }
}

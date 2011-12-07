// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ArrayBufferWrappingImplementation extends DOMWrapperBase implements ArrayBuffer {
  ArrayBufferWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get byteLength() { return _ptr.byteLength; }

  ArrayBuffer slice(int begin, [int end]) {
    if (end === null) {
      return LevelDom.wrapArrayBuffer(_ptr.slice(begin));
    } else {
      return LevelDom.wrapArrayBuffer(_ptr.slice(begin, end));
    }
  }
}

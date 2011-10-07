// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ArrayBufferViewWrappingImplementation extends DOMWrapperBase implements ArrayBufferView {
  ArrayBufferViewWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  ArrayBuffer get buffer() { return LevelDom.wrapArrayBuffer(_ptr.buffer); }

  int get byteLength() { return _ptr.byteLength; }

  int get byteOffset() { return _ptr.byteOffset; }
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Float64ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Float64Array {
  Float64ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Float64Array subarray(int start, int end) {
    return LevelDom.wrapFloat64Array(_ptr.subarray(start, end));
  }

  String get typeName() { return "Float64Array"; }
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Int32Array extends ArrayBufferView
    default Int32ArrayWrappingImplementation {

  static final int BYTES_PER_ELEMENT = 4;

  Int32Array(int length);

  Int32Array.from(List<num> list);

  Int32Array.fromBuffer(ArrayBuffer buffer);

  int get length();

  Int32Array subarray(int start, [int end]);
}

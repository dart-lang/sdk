// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Float32Array extends ArrayBufferView
    default Float32ArrayWrappingImplementation {

  static final int BYTES_PER_ELEMENT = 4;

  Float32Array(int length);

  Float32Array.from(List<num> list);

  Float32Array.fromBuffer(ArrayBuffer buffer);

  int get length();

  Float32Array subarray(int start, [int end]);
}

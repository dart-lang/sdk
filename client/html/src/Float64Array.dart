// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE fil default-styleWrappingImplementatione.

interface Float64Array extends ArrayBufferView
    default Float64ArrayWrappingImplementation {

  static final int BYTES_PER_ELEMENT = 8;

  Float64Array(int length);

  Float64Array.from(List<num> list);

  Float64Array.fromBuffer(ArrayBuffer buffer);

  int get length();

  Float64Array subarray(int start, [int end]);
}

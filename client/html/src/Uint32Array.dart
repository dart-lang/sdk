// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Uint32Array extends ArrayBufferView
    default Uint32ArrayWrappingImplementation {

  static final int BYTES_PER_ELEMENT = 4;

  Uint32Array(int length);

  Uint32Array.from(List<num> list);

  Uint32Array.fromBuffer(ArrayBuffer buffer);

  int get length();

  Uint32Array subarray(int start, [int end]);
}

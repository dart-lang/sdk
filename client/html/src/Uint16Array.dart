// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Uint16Array extends ArrayBufferView
    default Uint16ArrayWrappingImplementation {

  static final int BYTES_PER_ELEMENT = 2;

  Uint16Array(int length);

  Uint16Array.from(List<num> list);

  Uint16Array.fromBuffer(ArrayBuffer buffer);

  int get length();

  Uint16Array subarray(int start, [int end]);
}

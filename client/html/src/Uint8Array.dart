// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Uint8Array extends ArrayBufferView
    default Uint8ArrayWrappingImplementation {

  static final int BYTES_PER_ELEMENT = 1;

  Uint8Array(int length);

  Uint8Array.from(List<num> list);

  Uint8Array.fromBuffer(ArrayBuffer buffer);

  int get length();

  Uint8Array subarray(int start, [int end]);
}

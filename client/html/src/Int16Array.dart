// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Int16Array extends ArrayBufferView
    default Int16ArrayWrappingImplementation {

  static final int BYTES_PER_ELEMENT = 2;

  Int16Array(int length);

  Int16Array.from(List<num> list);

  Int16Array.fromBuffer(ArrayBuffer buffer);

  int get length();

  Int16Array subarray(int start, [int end]);
}

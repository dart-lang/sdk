// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Int8Array extends ArrayBufferView, List<int> factory _TypedArrayFactoryProvider {

  Int8Array(int length);

  Int8Array.fromList(List<int> list);

  Int8Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 1;

  int get length();

  Int8Array subarray(int start, [int end]);
}

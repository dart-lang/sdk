// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Int32Array extends ArrayBufferView, List<int> factory _TypedArrayFactoryProvider {

  Int32Array(int length);

  Int32Array.fromList(List<int> list);

  Int32Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 4;

  int get length();

  Int32Array subarray(int start, [int end]);
}

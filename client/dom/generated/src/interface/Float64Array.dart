// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Float64Array extends ArrayBufferView, List<num> factory _TypedArrayFactoryProvider {

  Float64Array(int length);

  Float64Array.fromList(List<num> list);

  Float64Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 8;

  int get length();

  Float64Array subarray(int start, [int end]);
}

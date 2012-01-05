// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Float32Array extends ArrayBufferView, List<num> factory _TypedArrayFactoryProvider {

  Float32Array(int length);

  Float32Array.fromList(List<num> list);

  Float32Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 4;

  int get length();

  Float32Array subarray(int start, [int end]);
}

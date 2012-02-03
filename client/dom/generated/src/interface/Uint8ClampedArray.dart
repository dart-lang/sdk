// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Uint8ClampedArray extends Uint8Array default _TypedArrayFactoryProvider {

  Uint8ClampedArray(int length);

  Uint8ClampedArray.fromList(List<int> list);

  Uint8ClampedArray.fromBuffer(ArrayBuffer buffer);

  int get length();

  Uint8ClampedArray subarray(int start, [int end]);
}

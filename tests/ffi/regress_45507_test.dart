// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:ffi";

import "package:expect/expect.dart";

const EIGHT = 8;

class Struct8BytesInlineArrayInt extends Struct {
  @Array(EIGHT)
  external Array<Uint8> a0;
}

void main() {
  Expect.equals(8, sizeOf<Struct8BytesInlineArrayInt>());
}

// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/55877.

// VMOptions=--optimization_level=3

import 'dart:typed_data';

Uint8List var7 = Uint8List(37);
Int32List? var16 = Int32List(2);

@pragma("vm:entry-point")
foo(int par3) {
  switch (par3) {
    case 308366437:
      var16 = Int32List(2).sublist(par3, 8);
      break;
  }
}

main() {
  try {
    foo(var7[-9223372032559808513]);
  } catch (e, st) {
    print('X2() throws');
  }
}

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=10

import 'package:expect/expect.dart';

trunc(x) => x & 0xFFFFFFFF;

f(t, x) => t(x) + 1;

g(t, x) => t(x + 1);

// Foo should be entirely replaced by Uint32 operations. Running with
// --trace-integer-ir-selection should result in:
//    CheckStackOverflow:4()
//    v22 <- UnboxUint32:14(v2)
//    v24 <- UnboxUint32:14(v3)
//    v6 <- BinaryUint32Op:14(+, v22 , v24 )
//    v26 <- UnboxUint32:22(v4)
//    v8 <- BinaryUint32Op:22(+, v6 , v26 )
//    v28 <- UnboxUint32:30(v5)
//    v10 <- BinaryUint32Op:30(+, v8 , v28 )
//    v30 <- UnboxUint32:14(v21)
//    v19 <- BinaryUint32Op:14(&, v10 , v30 )
//    v32 <- BoxUint32:90(v19 )
//    Return:38(v32 )
foo(a, b, c, i) {
  return trunc(a + b + c + i);
}

main() {
  for (var i = 0; i < 20000; i++) {
    Expect.equals(0x100000000, f(trunc, 0xFFFFFFFF));
    Expect.equals(0x0, g(trunc, 0xFFFFFFFF));
  }

  var a = 0xFFFFFFFF;
  var b = 0xCCCCCCCC;
  var c = 0x33333335;

  for (var i = 0; i < 20000; i++) {
    Expect.equals(i, foo(a, b, c, i));
  }
}


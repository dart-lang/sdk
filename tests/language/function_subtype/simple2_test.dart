// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping of simple function types.

import 'package:expect/expect.dart';

typedef Args0();
typedef Args1(a);
typedef Args2(a, b);
typedef Args3(a, b, c);
typedef Args4(a, b, c, d);

args0_1([a]) {}
args1_2(a, [b]) {}
args0_2([a, b]) {}
args1_3(a, [b, c]) {}

args0_1_named({a}) {}
args1_2_named(a, {b}) {}
args0_2_named({a, b}) {}
args1_3_named(a, {b, c}) {}

main() {
  Expect.isTrue(args0_1 is Args0);
  Expect.isTrue(args0_1 is Args1);
  Expect.isFalse(args0_1 is Args2);
  Expect.isFalse(args0_1 is Args3);
  Expect.isFalse(args0_1 is Args4);

  Expect.isFalse(args1_2 is Args0);
  Expect.isTrue(args1_2 is Args1);
  Expect.isTrue(args1_2 is Args2);
  Expect.isFalse(args1_2 is Args3);
  Expect.isFalse(args1_2 is Args4);

  Expect.isTrue(args0_2 is Args0);
  Expect.isTrue(args0_2 is Args1);
  Expect.isTrue(args0_2 is Args2);
  Expect.isFalse(args0_2 is Args3);
  Expect.isFalse(args0_2 is Args4);

  Expect.isFalse(args1_3 is Args0);
  Expect.isTrue(args1_3 is Args1);
  Expect.isTrue(args1_3 is Args2);
  Expect.isTrue(args1_3 is Args3);
  Expect.isFalse(args1_3 is Args4);

  Expect.isTrue(args0_1_named is Args0);
  Expect.isFalse(args0_1_named is Args1);
  Expect.isFalse(args0_1_named is Args2);
  Expect.isFalse(args0_1_named is Args3);
  Expect.isFalse(args0_1_named is Args4);

  Expect.isFalse(args1_2_named is Args0);
  Expect.isTrue(args1_2_named is Args1);
  Expect.isFalse(args1_2_named is Args2);
  Expect.isFalse(args1_2_named is Args3);
  Expect.isFalse(args1_2_named is Args4);

  Expect.isTrue(args0_2_named is Args0);
  Expect.isFalse(args0_2_named is Args1);
  Expect.isFalse(args0_2_named is Args2);
  Expect.isFalse(args0_2_named is Args3);
  Expect.isFalse(args0_2_named is Args4);

  Expect.isFalse(args1_3_named is Args0);
  Expect.isTrue(args1_3_named is Args1);
  Expect.isFalse(args1_3_named is Args2);
  Expect.isFalse(args1_3_named is Args3);
  Expect.isFalse(args1_3_named is Args4);
}

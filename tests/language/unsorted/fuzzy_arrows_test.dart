// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Fuzzy arrows will be eliminated from Dart 2.0 soon.  This test checks that
// implementations have properly removed fuzzy arrow support, both at compile
// time and at run time.  See dartbug.com/29630 for a detailed explanation.

import "package:expect/expect.dart";

typedef DynamicToDynamic(x);
typedef NeverToDynamic(Never x);

num numToNum(num x) => x;

main() {
  DynamicToDynamic x = numToNum; //# 01: compile-time error
  NeverToDynamic x = numToNum; //# 02: ok
  Expect.isFalse(numToNum is DynamicToDynamic); //# 03: ok
  Expect.isTrue(numToNum is NeverToDynamic); //# 04: ok
}

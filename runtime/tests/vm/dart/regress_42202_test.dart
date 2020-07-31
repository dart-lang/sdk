// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that AOT compiler doesn't crash when handling a polymorphic call to
// operator== when receiver is a dead code (result of inlined call of a method
// which doesn't return).
// Regression test for https://github.com/dart-lang/sdk/issues/42202.

import "package:expect/expect.dart";

@pragma('vm:prefer-inline')
num foo0(int par1) {
  if (par1 >= 39) {
    return 10;
  }
  if (par1 >= 37) {
    return 3.14;
  }
  throw 'hi';
}

main() {
  Expect.throws(() {
    print(foo0(0) == [1]);
  }, (e) => e == 'hi');
}

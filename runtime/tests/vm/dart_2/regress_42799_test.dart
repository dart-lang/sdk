// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that AOT compiler doesn't crash when constant folding 'is'
// test for a value which is a result of unreachable code
// (result of inlined call of a method which doesn't return).
// Regression test for https://github.com/dart-lang/sdk/issues/42799.

import "package:expect/expect.dart";

@pragma('vm:prefer-inline')
dynamic foo0(int par1) {
  if (par1 >= 39) {
    return <String>[];
  }
  if (par1 >= 37) {
    return <int>[];
  }
  throw 'hi';
}

main() {
  Expect.throws(() {
    if (foo0(0) is List<int>) {
      print('not reachable');
    }
  }, (e) => e == 'hi');
}

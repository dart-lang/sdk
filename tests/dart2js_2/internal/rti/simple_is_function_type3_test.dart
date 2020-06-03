// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7
//
// dart2jsOptions=--experiment-new-rti

// Test that some closures are 'is Function'.

import "package:expect/expect.dart";

@pragma('dart2js:noInline')
confuse(x) => x;

main() {
  // static tear-off.
  Expect.isTrue(confuse(main) is Function);

  // instance tear-off.
  Expect.isTrue(confuse([].add) is Function);

  // function expression.
  Expect.isTrue(confuse(() => 1) is Function);

  // local function.
  int add1(int x) => x;

  Expect.isTrue(confuse(add1) is Function);

  Expect.isFalse(confuse(null) is Function);
  Expect.isFalse(confuse(1) is Function);
}

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that inlining takes null into account.

import "package:expect/expect.dart";

class A {
  foo() => this;
}

var global;

main() {
  Expect.throws(() => global.foo());
  global = new A();
  Expect.equals(global, global.foo());
}

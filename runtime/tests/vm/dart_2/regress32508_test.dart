// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dartbug.com/32508: check that type test which takes
// a value of a guarded _Closure field is performed correctly.

// VMOptions=--optimization_counter_threshold=10 --no-background-compilation

import "package:expect/expect.dart";

typedef R MyFunc<R, T1, T2>(T1 arg1, T2 arg2);

class X {
  Function _foo = (x) {};

  bool bar() {
    if (_foo is MyFunc<dynamic, dynamic, dynamic>) {
      Expect.fail('Boom!');
    }
    return true;
  }
}

main() {
  for (var i = 0; i < 100; i++) {
    Expect.isTrue(new X().bar());
  }
}

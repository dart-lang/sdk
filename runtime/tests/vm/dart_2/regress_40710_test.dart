// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=10 --deterministic

// Regression test for https://dartbug.com/40710.
// Verifies that specialized type testing stub can reject
// instances with all-dynamic (null) type arguments.

import "package:expect/expect.dart";

class A<T> {
  @pragma('vm:never-inline')
  void foo(x) {
    print(x as T);
  }
}

class B<T> {}

main(List<String> args) {
  for (int i = 0; i < 20; ++i) {
    final a = new A<B<String>>();
    a.foo(new B<String>());
    Expect.throwsTypeError(() {
      a.foo(new B<dynamic>());
    });
  }
}

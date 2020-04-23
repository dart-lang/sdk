// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 23058.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

class A {
  var x = new B();

  foo() async {
    return x.foo == 2 ? 42 : x.foo;
  }
}

class B {
  var x = 0;

  get foo {
    if (x == -1) {
      return 0;
    } else {
      return x++;
    }
  }
}

main() {
  asyncStart();
  new A().foo().then((result) {
    Expect.equals(1, result);
    asyncEnd();
  });
}

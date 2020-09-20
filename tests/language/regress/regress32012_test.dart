// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class C {
  int x = -1;

  int bar() {
    return 19;
  }
}

main() {
  B foo<A extends B, B extends C>(A a) {
    int bar<Q>(B b) {
      return 23 + b.bar();
    }

    a.x = bar(a);
    return a;
  }

  var x = <A extends B, B>(A a) {
    return a;
  };

  Expect.equals(x(foo(new C())).x, 42);
}

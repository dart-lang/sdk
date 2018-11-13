// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class I {
  void foo(x);
}

class A implements I {
  void foo(x) {
    print(x);
  }
}

class B implements I {
  void foo(x) {
    print(x);
  }
}

void bar(I i) {
  if (i is A) {
    i.foo(42);
  }
}

I ii = new B();

main(List<String> args) {
  bar(ii);
}

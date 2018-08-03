// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  foo() => null;
}

main() {
  void bar<T extends A>(T t) {
    print("t.foo()=${t.foo()}");
  }

  bar(new A());

  (<S extends A>(S s) {
    print("s.foo()=${s.foo()}");
  })(new A());
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test comparison of this and a constant.

class Foo {
  static final C1 = const Foo('C1');
  static final C2 = const Foo('C2');
  static final C3 = const Foo('C3');

  var name;
  const Foo(this.name);

  foo() {
    switch (this) {
      case C1: return C1;
      case C2: return C2;
      default: return null;
    }
  }
}

main() {
  Expect.equals(Foo.C1, Foo.C1.foo());
  Expect.equals(Foo.C2, Foo.C2.foo());
  Expect.equals(null, Foo.C3.foo());
}

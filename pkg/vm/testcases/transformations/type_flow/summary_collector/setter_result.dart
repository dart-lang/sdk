// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class T {}

void use(x) {}

class A {
  dynamic foo;
}

class B extends A {
  set foo(x) {}

  static dynamic bar;

  void testPropertySet(x) {
    use(foo = x);
  }

  void testDynamicPropertySet(x, y) {
    use(x.foo = y);
  }

  void testSuperPropertySet(x) {
    use(super.foo = x);
  }

  void testStaticPropertySet(x) {
    use(bar = x);
  }
}

main() {}

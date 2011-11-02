// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo() => 123;

void testShadowingScope1() {
  var foo = foo();
  Expect.equals(123, foo);
}

void testShadowingScope2() {
  {
    var foo = foo() + 444;
    Expect.equals(567, foo);
  }
  Expect.equals(123, foo());
}

void testShadowingCapture1() {
  var f;
  {
    var foo = 888;
    f = () => foo;
  }
  var foo = -888;
  Expect.equals(888, f());
}

void testShadowingCapture2() {
  var f = null;
  // this one uses a reentrent block
  for (int i = 0; i < 2; i++) {
    var foo = i + 888;
    if (f == null) f = () => foo;
  } while(false);
  var foo = -888;

  // this could break if it doesn't bind the right "foo"
  Expect.equals(888, f());
}

class BlockScopeTest1 {
  void testShadowingInstanceVar() {
    if (true) {
      var foo = foo() + 444;
      Expect.equals(1221, foo);
    }
    Expect.equals(777, foo());
  }
  static void testShadowingStatic() {
    if (true) {
      var bar = bar() + 444;
      Expect.equals(1221, bar);
    }
    Expect.equals(777, bar());
  }

  foo() => 777;
  static bar() => 777;
}

main() {
  testShadowingScope1();
  testShadowingScope2();
  testShadowingCapture1();
  testShadowingCapture2();
  new BlockScopeTest1().testShadowingInstanceVar();
  BlockScopeTest1.testShadowingStatic();
}

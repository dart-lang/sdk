// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that noSuchMethod forwarders that were generated for
// abstract accessors declared via field in an interface don't override concrete
// getters and setters in the mixin application.

int count = 0;

abstract class A {
  int foo;
}

class B implements A {
  noSuchMethod(i) {
    ++count;
    return null;
  }

  // Should receive noSuchMethod forwarders for the 'foo' getter and setter.
}

class C extends Object with B {
  // The getter and the setter below shouldn't be overridden with noSuchMethod
  // forwarders.
  int get foo => 42;
  void set foo(int value) {}
}

main() {
  var c = new C();
  if (c.foo != 42) {
    throw "Value mismatch: c.foo != 42.";
  }
  c.foo = 43;
  if (count != 0) {
    throw "Value mismatch: count != 0";
  }
}

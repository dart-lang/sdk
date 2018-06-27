// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that noSuchMethod forwarders are generated for abstract
// accessors implicitly declared via fields of abstract classes in case when one
// of the accessors is defined in a superclass.

void expectTypeError(callback()) {
  try {
    callback();
    throw 'Expected TypeError, did not occur';
  } on TypeError {}
}

abstract class A {
  int foo;
}

abstract class B implements A {
  int get foo => 42;

  noSuchMethod(i) => "bar";
}

class C extends B {
  // Should receive a noSuchMethod forwarder for the 'foo' setter, but not for
  // the 'foo' getter.
}

abstract class D implements A {
  void set foo(int value) {}

  noSuchMethod(i) => "bar";
}

class E extends D {
  // Should receive a noSuchMethod forwarder for the 'foo' getter, but not for
  // the 'foo' setter.
}

main() {
  var c = new C();
  expectTypeError(() => (c as dynamic).foo = "bar");

  var e = new E();
  expectTypeError(() => e.foo);
}

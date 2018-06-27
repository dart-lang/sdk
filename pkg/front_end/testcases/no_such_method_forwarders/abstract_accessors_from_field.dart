// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that noSuchMethod forwarders are generated for abstract
// accessors implicitly declared via fields of abstract classes.  The type
// checks should be performed for the return values of getters and for the r.h.s
// of assignments for setters.

void expectTypeError(callback()) {
  try {
    callback();
    throw 'Expected TypeError, did not occur';
  } on TypeError {}
}

abstract class I {
  int foo;
}

class A implements I {
  dynamic noSuchMethod(i) => "bar";

  // Should have noSuchMethod forwarders for the 'foo' getter and setter.
}

class B extends A {
  // Should not have noSuchMethod forwarders for the 'foo' getter and setter.
}

main() {
  var a = new A();
  expectTypeError(() => a.foo);
  expectTypeError(() => (a as dynamic).foo = "bar");
}

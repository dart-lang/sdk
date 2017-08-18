// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The purpose of this test is to detect that closures in [LocalInitializer]s
// and [FieldInitializer]s are properly converted. This test assumes that
// [ArgumentExtractionForTesting] transformer was run before closure conversion.
// It should introduce one [LocalInitializer] for each argument passed to a
// field initializer for a field ending in "_li". If such argument contains a
// closure, it would appear in a [LocalInitializer]. The [FieldInitializer]
// example requires no such elaboration.

class X {}

// Closure in field initializer.
//
class A {
  X foo;
  A(X i) : foo = ((() => i)());
}

// Closure in super initializer.
//
class S extends A {
  S(X i) : super((() => i)());
}

// Closure in local initializer.
//
class S2 {
  X foo_li;
  S2(X foo) : foo_li = (() => foo)();
}

// Closure in redirecting initializer.
//
class B {
  X foo;
  B.named(X foo) {}
  B(X foo) : this.named((() => foo)());
}

main() {
  A a = new A(new X());
  a.foo; // To prevent dartanalyzer from marking [a] as unused.
  B b = new B(new X());
  b.foo;
  S s = new S(new X());
  s.foo;
  S2 s2 = new S2(new X());
  s2.foo_li;
}

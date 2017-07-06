// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The purpose of this test is to detect that closures in [LocalInitializer]s
// are properly converted.  This test assumes that
// [ArgumentExtractionForRedirecting] transformer was run before closure
// conversion.  It should introduce one [LocalInitializer] for each argument
// passed to the redirecting constructor.  If such argument contains a closure,
// it would appear in a [LocalInitializer].

class X {}

class A {
  X foo;
  A.named(X foo) {}
  A(X foo) : this.named((() => foo)());
}

main() {
  A a = new A(new X());
  a.foo; // To prevent dartanalyzer from marking [a] as unused.
}

// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that when both LHS and RHS in a mixin application have a
// concrete implementation of a method and a noSuchMethod forwarder for it, the
// concrete implementation stays.

abstract class I {
  foo();
}

class A {
  foo() {}
}

class B implements I {
  noSuchMethod(_) => null;
}

class C extends A with B {}

main() {}

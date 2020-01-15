// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// The test checks that 'covariant' bit is propagated from the superclass of the
// mixin application to the mixin application and its subclasses.

class A {
  void foo(covariant num x) {}
}

class B {
  void foo(num x) {}
}

class C {
  void foo(num x) {}
}

class D extends A with B implements C {
  // This member declaration shouldn't result in a compile-time error.
  void foo(int x) {}
}

main() {}

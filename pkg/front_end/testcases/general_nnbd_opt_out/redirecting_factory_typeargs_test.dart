// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// The purpose of this test is to check the representation of redirecting
// factory constructors in the case when the redirection target has type
// arguments supplied by the redirecting factory constructor.

library redirecting_factory_constructors.typeargs_test;

class X {}

class Y extends X {}

class A {
  A();

  factory A.redir() = B<Y>;
}

class B<T extends X> extends A {
  B();
}

main() {
  new A.redir();
}

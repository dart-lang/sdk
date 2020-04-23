// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// The purpose of this test is to check the representation of redirecting
// factory constructors on a simple case.

library redirecting_factory_constructors.simple_test;

class A {
  A();
  factory A.redir() = A;
}

main() {
  new A.redir();
}

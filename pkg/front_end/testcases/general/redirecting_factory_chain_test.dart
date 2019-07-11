// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The purpose of this test is to check the representation of redirecting
// factory constructors in a case of a redirecting chain.

library redirecting_factory_constructors.chain_test;

class A {
  A();
  factory A.first() = A;
  factory A.second() = A.first;
}

main() {
  new A.second();
}

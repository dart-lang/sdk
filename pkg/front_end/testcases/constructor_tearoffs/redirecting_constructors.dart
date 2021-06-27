// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A.new();
  factory A.redirectingFactory() = A.new;
  factory A.redirectingFactoryChild() = B.new;
  factory A.redirectingTwice() = A.redirectingFactory;
}

class B extends A {}

test() {
  A Function() f1 = A.redirectingFactory;
  A Function() f2 = A.redirectingFactoryChild;
  A Function() f3 = A.redirectingTwice;
  A x1 = f1();
  B x2 = f2() as B;
  A x3 f3();
}

main() => test();

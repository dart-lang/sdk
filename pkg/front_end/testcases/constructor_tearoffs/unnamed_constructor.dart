// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A.new();
  factory A.redirectingFactory() = A.new;
  factory A.redirectingFactoryChild() = B.new;
  A.redirecting() : this.new();
}

class B extends A {}

class C {
  final int x;
  const C.new(this.x);
}

class D extends C {
  D(int x) : super.new(x * 2);
}

test() {
  D.new(1);
  const C.new(1);
  new C.new(1);

  var f1 = A.new;
  var f2 = B.new;
  var f3 = C.new;
  var f4 = D.new;
  f1();
  f2();
  f3(1);
  f4(1);

  A Function() g1 = A.new;
  B Function() g2 = B.new;
  C Function(int x) g3 = C.new;
  D Function(int x) g4 = D.new;
  g1();
  g2();
  g3(1);
  g4(1);
}

main() {}

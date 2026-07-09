// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A(int x);
}

class B extends A {
  B() : super(42);
  factory B.foo(super.x) => new B();
}

foo(super.x) {}

class C {
  void set foo(super.value) {}
}

main() {}

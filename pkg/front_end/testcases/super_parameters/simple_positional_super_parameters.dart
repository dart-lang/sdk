// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A1 {
  final int foo;
  A1(this.foo);
}

class B1 extends A1 {
  B1(super.foo) : super(); // Ok.
}

class C1 extends A1 {
  C1(super.foo) : super(42); // Error.
}

class A2 {
  final int foo;
  final String bar;
  A2(this.foo, this.bar);
}

class B2 extends A2 {
  B2() : super(0, 1, 2); // Error.
}

class C2 extends A2 {
  C2(super.foo) : super(); // Error.
}

main() {}

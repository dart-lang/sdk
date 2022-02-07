// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A1 {
  final int foo;
  A1(this.foo);
  A1.named(this.foo);
  A1.named2(int foo) : foo = foo;
  A1.named3({required int foo}) : foo = foo;
}

class B1 extends A1 {
  B1(super.foo);
  B1.named(super.foo) : super.named();
  B1.named2(super.foo) : super.named2();
  B1.named3({required super.foo}) : super.named3();
}

class A2 {
  final int foo;
  final String bar;
  A2({required int this.foo, required String this.bar});
}

class B2 extends A2 {
  B2({required super.bar, required super.foo});
}

main() {}

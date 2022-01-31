// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A1 {
  final int foo;
  A1({required this.foo});
}

class B1 extends A1 {
  B1({required super.foo}) : super(); // Ok.
}

class C1 extends A1 {
  C1({required super.foo}) : super(foo: foo); // Error.
}

class A2 {
  final int foo;
  final String bar;
  A2({required this.foo, required this.bar});
}

class B2 extends A2 {
  B2() : super(foo: 42, bar: "bar", baz: false); // Error.
}

class C2 extends A2 {
  C2({required super.foo}) : super(); // Error.
  C2.other({required super.foo}) : super(bar: 'bar'); // Ok.
}

main() {}

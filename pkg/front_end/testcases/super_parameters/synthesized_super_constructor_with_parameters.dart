// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// 1. The base case.

class A1 {
  final int a;
  A1(this.a);
}

class B1 {}

// C1 has a synthesized constructor that takes a positional parameter.
class C1 = A1 with B1;

class D1 extends C1 {
  D1(super.a);
}

// 2. The case of named parameters.

class A2 {
  final int a;
  A2({this.a = 0});
}

class B2 {}

// C2 has a synthesized constructor that takes a named parameter.
class C2 = A2 with B2;

class D2 extends C2 {
  D2({super.a});
}

// 3. The case of optional positional parameters.

class A3 {
  final int a;
  A3([this.a = 0]);
}

class B3 {}

// C3 has a synthesized constructor that takes an optional positional parameter.
class C3 = A3 with B3;

class D3 extends C3 {
  D3([super.a]);
}

// 4. The case of the inverted order of classes.

class D4 extends C4 {
  D4([super.foo]);
}

// C4 has a synthesized constructor that takes an optional parameter.
class C4 = A4 with B4;

class B4 {}

class A4 extends AA4 {
  A4([super.foo]);
}

class AA4 {
  final int foo;
  AA4([this.foo = 42]);
}

// 5. The case of a longer named mixin chain.

class D5 extends C5c {
  D5([super.foo]);
}

// C5a, C5b, C5c have synthesized constructors that take an optional parameter.
class C5c = C5b with B5;
class C5b = C5a with B5;
class C5a = A5 with B5;

class B5 {}

class A5 extends AA5 {
  A5([super.foo]);
}

class AA5 {
  final int foo;
  AA5([this.foo = 42]);
}

main() {}

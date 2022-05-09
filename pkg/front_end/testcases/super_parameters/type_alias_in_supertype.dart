// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// 1. The base case.

class A1 {
  final String foo;
  A1(this.foo);
}

typedef TA1 = A1;

typedef TTA1 = TA1;

typedef TTTA1 = TTA1;

typedef TTTTA1 = TTTA1;

class D1 extends TTTTA1 {
  D1(super.foo);
}

// 2. The case of named parameters.

class A2 {
  final String foo;
  A2({this.foo = "bar"});
}

typedef TA2 = A2;

typedef TTA2 = TA2;

typedef TTTA2 = TTA2;

typedef TTTTA2 = TTTA2;

class D2 extends TTTTA2 {
  D2({super.foo});
}

// 3. The case of optional positional parameters.

class A3 {
  final String foo;
  A3([this.foo = "bar"]);
}

typedef TA3 = A3;

typedef TTA3 = TA3;

typedef TTTA3 = TTA3;

typedef TTTTA3 = TTTA3;

class D3 extends TTTTA3 {
  D3([super.foo]);
}

// 4. The case of the inverted order of declarations.

class D4 extends TTTTA4 {
  D4([super.foo]);
}

typedef TTTTA4 = TTTA4;

typedef TTTA4 = TTA4;

typedef TTA4 = TA4;

typedef TA4 = A4;

class A4 {
  final String foo;
  A4([this.foo = "bar"]);
}

main() {}

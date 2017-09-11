// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for type checks involving the void type in function types.

import 'package:expect/expect.dart';

typedef F = void Function(Object);
typedef F2 = void Function([Object]);
typedef F3 = void Function({Object x});

typedef G = void Function(void);
typedef G2 = void Function([void]);
typedef G3 = void Function({void x});

typedef H = int Function(void);
typedef H2 = int Function([void]);
typedef H3 = int Function({void x});

void f(Object x) {}
void f2([Object x]) {}
void f3({Object x}) {}

void g(void x) {}
void g2([void x]) {}
void g3({void x}) {}

int h(void x) => 499;
int h2([void x]) => 499;
int h3({void x}) => 499;

void expectsF(F f) {}
void expectsG(G g) {}
void expectsH(H h) {}

void expectsF2(F2 f) {}
void expectsG2(G2 g) {}
void expectsH2(H2 h) {}

void expectsF3(F3 f) {}
void expectsG3(G3 g) {}
void expectsH3(H3 h) {}

main() {
  Expect.isTrue(f is F);
  Expect.isTrue(f is G);
  Expect.isFalse(f is H);
  expectsF(f);
  expectsG(f);
  expectsH(f);  //# 00: compile-time error

  Expect.isTrue(f2 is F2);
  Expect.isTrue(f2 is G2);
  Expect.isFalse(f2 is H2);
  expectsF2(f2);
  expectsG2(f2);
  expectsH2(f2);  //# 01: compile-time error

  Expect.isTrue(f3 is F3);
  Expect.isTrue(f3 is G3);
  Expect.isFalse(f3 is H3);
  expectsF3(f3);
  expectsG3(f3);
  expectsH3(f3);  //# 03: compile-time error

  Expect.isTrue(g is F);
  Expect.isTrue(g is G);
  Expect.isFalse(g is H);
  expectsF(g);  //# 04: compile-time error
  expectsG(g);
  expectsH(g);  //# 05: compile-time error

  Expect.isTrue(g2 is F2);
  Expect.isTrue(g2 is G2);
  Expect.isFalse(g2 is H2);
  expectsF2(g2);  //# 06: compile-time error
  expectsG2(g2);
  expectsH2(g2);  //# 07: compile-time error

  Expect.isTrue(g3 is F3);
  Expect.isTrue(g3 is G3);
  Expect.isFalse(g3 is H3);
  expectsF3(g3);  //# 08: compile-time error
  expectsG3(g3);
  expectsH3(g3);  //# 09: compile-time error

  Expect.isTrue(h is F);
  Expect.isTrue(h is G);
  Expect.isTrue(h is H);
  expectsF(h);
  expectsG(h);
  expectsH(h);

  Expect.isTrue(h2 is H2);
  Expect.isTrue(h2 is G2);
  Expect.isTrue(h2 is H2);
  expectsF2(h2);
  expectsG2(h2);
  expectsH2(h2);

  Expect.isTrue(h3 is H3);
  Expect.isTrue(h3 is G3);
  Expect.isTrue(h3 is H3);
  expectsF3(h3);
  expectsG3(h3);
  expectsH3(h3);
}

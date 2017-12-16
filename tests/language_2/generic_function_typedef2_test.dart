// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for a function type test that cannot be eliminated at compile time.

import "package:expect/expect.dart";

class A {}

typedef int F();

typedef G = F; //# 00: syntax error
typedef H = int; //# 01: syntax error
typedef I = A; //# 02: syntax error
typedef J = List<int>; //# 03: syntax error
typedef K = Function(
    Function<A>(A
    <int> // //# 04: compile-time error
        ));
typedef L = Function(
    {
  /* //  //# 05: syntax error
    bool
  */ //  //# 05: continued
        x});

typedef M = Function(
    {
  /* //  //# 06: syntax error
    bool
  */ //  //# 06: continued
        int});

foo({bool int}) {}
main() {
  bool b = true;
  Expect.isFalse(b is L);
  Expect.isFalse(b is M);
  Expect.isTrue(foo is M);
}

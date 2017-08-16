// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests for parsing closures with complex parameter types.

main() {
  test1();
  test2();
  test3();
}

class Pair<A, B> {
  final A fst;
  final B snd;
  Pair(A this.fst, B this.snd);
}

test1() {
  // Closures with nested parameterized types.
  var cdar1 = (Pair<int, Pair<int, int>> pr) => pr.snd.fst;
  var cdar2 = (Pair<int, Pair<int, int>> pr) => pr.snd.fst;

  var e = new Pair<int, Pair<int, int>>(100, new Pair<int, int>(200, 300));

  Expect.equals(200, cdar1(e));
  Expect.equals(200, cdar2(e));
}

test2() {
  // Closures with nested parameterized types in optional position
  var cdar1 = ([Pair<int, Pair<int, int>> pr = null]) => pr.snd.fst;
  var cdar2 = ([Pair<int, Pair<int, int>> pr = null]) => pr.snd.fst;

  var e = new Pair<int, Pair<int, int>>(100, new Pair<int, int>(200, 300));

  Expect.equals(200, cdar1(e));
  Expect.equals(200, cdar2(e));
}

test3() {
  // Closures with nested parameterized types.
  var f1 = (Pair<int, Pair<int, int>> pr) => pr.snd.fst + 1;
  var f2 = (Pair<int, Pair<int, int>> pr) => pr.snd.fst + 2;

  // Closures with function type with nested parameterized types.
  var ap1 = (f(Pair<int, Pair<int, int>> pr1), Pair<int, Pair<int, int>> pr) =>
      f(pr) * 10;
  var ap2 = (f(Pair<int, Pair<int, int>> pr1), Pair<int, Pair<int, int>> pr) =>
      f(pr) * 100;

  var e = new Pair<int, Pair<int, int>>(100, new Pair<int, int>(200, 300));

  Expect.equals(2010, ap1(f1, e));
  Expect.equals(2020, ap1(f2, e));
  Expect.equals(20100, ap2(f1, e));
  Expect.equals(20200, ap2(f2, e));
}

// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import "package:expect/expect.dart";

class A<N, S, U> {
  final List<U> field;

  A(N n, S s) : field = new List<U>() {
    Expect.isTrue(n is N);
    Expect.isTrue(s is S);
  }

  A.empty() : field = null{}

  factory A.f(S s) {
    Expect.isTrue(s is S);
    return new A.empty();
  }

  const A.c(U u, S s) : field = const [null];

  List<U> get getter {
    return field;
  }

  void set setter(S s){}
}

abstract class J<Aa, B>{}

abstract class I<H, C, K> extends J<C, K>
{ }


main() {
  new A<num, double, List>(1, 2.0);
  A a = new A<int, int, int>.f(1);
  const A<int, int, List>.c(const[], 1);

  var z = a.getter;
  a.setter = 1;
}

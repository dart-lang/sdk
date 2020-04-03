// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

extension on Object {
  int operator -() => 42;
  int get length => 5;
}

class Tester {
  final value;
  const Tester.neg(Object o) : value = -o;
  const Tester.length(Object o) : value = o.length;
}

main() {
  const //
      Object //# neg: compile-time error
      i = 2;
  const int x = -i;
  print(x);

  const //
      Object //# length: compile-time error
      s = "fisk";
  const int y = s.length;
  print(y);

  Expect.equals(42, new Tester.neg(3).value);
  const tx = Tester.neg(42); //# tneg: compile-time error
  print(tx); //# tneg: continued

  Expect.equals(5, new Tester.length("abc").value);
  const ty = Tester.length("abc"); //# tlength: compile-time error
  print(ty); //# tlength: continued
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

foo(env1) {
  if (env1 == null) return 0;
  var env0 = 0;
  for (int i = 0; i < env1.length; i++) {
    env0 += env1[i];
  }
  env1 = inscrutableId(new A());
  for (int i = 0; i < env1.length; i++) {
    env0 += env1[i];
  }
  return env0;
}

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

inscrutableId(x) {
  if (x == 0) return inscrutable(x);
  return (3 == inscrutable(3)) ? x : false;
}

class A {
  int length = 3;
  operator [](i) => 1;
}

main() {
  Expect.equals(9, foo([1, 2, 3]));
  if (inscrutableId(0) == 0) {
    Expect.equals(6, foo(new A()));
  }
}

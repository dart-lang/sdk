// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that closurizing a function implies a dependency on its type.

import "package:expect/expect.dart";

import 'deferred_regression_22995_lib.dart' deferred as lib;

class A {}

class B {}

class C {}

typedef Ti(int x);
typedef TB(B x);
typedef TTi(Ti x);
typedef Tg<T>(T x);

class T {
  fA(A a) => null;
  fTB(TB a) => null;
  fTgC(Tg<C> a) => null;
}

main() {
  Expect.isFalse(new T().fA is Ti);
  Expect.isFalse(new T().fTB is TTi);
  Expect.isFalse(new T().fTgC is TTi);
  lib.loadLibrary().then((_) {
    lib.foofoo();
  });
}

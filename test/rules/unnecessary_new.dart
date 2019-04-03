// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_new`

class A {
  const A([o]);
  A.c1();
}

main() {
  const A(); // OK
  new A(); // LINT
  A(); // OK

  new A.c1(); // LINT
  A.c1(); // OK

  new A([]); // LINT
  A([]); // OK

  final v1 = A(); // OK
  final v2 = new A(); // LINT
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for http://dartbug.com/6259. This test used to fail
// on dart2js because class A does not know [A.document] is a target for
// the call [:obj.document:] in the [main] method. Therefore, dart2js
// would not compile [A.document].

class A {
  get document => 42;
}

abstract class B {
  get document; // Abstract.
}

class C extends A implements B {}

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

void main() {
  var tab = [new Object(), new C()];
  var obj = tab[inscrutable(1)];
  int res = 0;
  if (obj is B) res = obj.document;
  Expect.equals(42, res);
}

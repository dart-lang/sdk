// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that factory redirections work for compile-time constants, and
// that abstract classes can redirect.

abstract class C {
  const factory C(int x) = D;
}

class D implements C {
  final int i;
  const D(this.i);
  m() => 'called m';
}

main() {
  const C c = const C(42);
  D d = c;
  Expect.equals(42, d.i);
  Expect.equals('called m', d.m());
  d = new C(42);
  Expect.equals(42, d.i);
  Expect.equals('called m', d.m());
}

// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for a function type test that cannot be eliminated at compile time.

import "package:expect/expect.dart";

class A {}

typedef int F();





typedef K = Function(
    Function<A>(A

        ));
typedef L = Function(
    {

    bool

        x});

typedef M = Function(
    {

    bool

        int});

foo({bool int}) {}
main() {
  bool b = true;
  Expect.isFalse(b is L);
  Expect.isFalse(b is M);
  Expect.isTrue(foo is M);
}

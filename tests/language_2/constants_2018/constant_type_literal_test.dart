// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=constant-update-2018

// Tests that non-deferred type literals are constant expressions.

import "dart:core";
import "dart:core" as core;
import "dart:core" deferred as dcore;

// Declares F function type alias, M mixin and C class.
import "constant_type_literal_types.dart";
import "constant_type_literal_types.dart" as p;
import "constant_type_literal_types.dart" deferred as d;

main() {
  const Test(int, core.int);
  const Test(C, p.C);
  const Test(M, p.M);
  const Test(F, p.F);
  const c1 = //
      dcore. //# 01: compile-time error
          int;
  const Test(c1, int);
  const c2 = //
      d. //# 02: compile-time error
          C;
  const Test(c2, C);
}

class Test {
  const Test(Type t1, Type t2) : assert(identical(t1, t2));
}

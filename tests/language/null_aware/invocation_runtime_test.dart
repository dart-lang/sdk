// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify semantics of the ?. operator when it is used to invoke a method.

import "package:expect/expect.dart";
import "conditional_access_helper.dart" as h;

bad() {
  Expect.fail('Should not be executed');
}

class B {}

class C extends B {
  f(callback()?) => callback!();
  int g(int callback()) => callback();
  static staticF(callback()) => callback();
  static int staticG(int callback()) => callback();
}

C? nullC() => null;

main() {
  // o?.m(...) is equivalent to ((x) => x == null ? null : x.m(...))(o).
  Expect.equals(null, nullC()?.f(bad()));
  C? c = C() as dynamic;
  Expect.equals(1, c?.f(() => 1));
  // C?.m(...) is equivalent to C.m(...).
  Expect.equals(1, C?.staticF(() => 1));
  Expect.equals(1, h.C?.staticF(() => 1));

  // The static type of o?.m(...) is the same as the static type of
  // o.m(...).
  {
    int? i = nullC()?.g(bad());
    Expect.equals(null, i);
  }
  {
    int? i = c?.g(() => 1);
    Expect.equals(1, i);
  }
  {
    int? i = C?.staticG(() => 1);
    Expect.equals(1, i);
  }
  {
    int? i = h.C?.staticG(() => 1);
    Expect.equals(1, i);
  }
}

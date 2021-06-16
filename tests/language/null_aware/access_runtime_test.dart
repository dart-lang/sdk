// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify semantics of the ?. operator when it does not appear on the LHS of an
// assignment.

import "package:expect/expect.dart";
import "conditional_access_helper.dart" as h;

class B {}

class C extends B {
  int? v;
  C(this.v);
  static int? staticInt;
}

C? nullC() => null;

main() {
  // e1?.id is equivalent to ((x) => x == null ? null : x.id)(e1).
  Expect.equals(null, nullC()?.v);

  C? c = new C(1) as dynamic;
  Expect.equals(1, c?.v);

  // C?.id is equivalent to C.id.
  C.staticInt = 1;
  Expect.equals(1, C?.staticInt);

  h.C.staticInt = 1;
  Expect.equals(1, h.C?.staticInt);

  // The static type of e1?.id is the static type of e1.id.
  {
    int? i = c?.v;
    Expect.equals(1, i);
  }

  {
    C.staticInt = 1;
    int? i = C?.staticInt;
    Expect.equals(1, i);
  }

  {
    h.C.staticInt = 1;
    int? i = h.C?.staticInt;
    Expect.equals(1, i);
  }
}

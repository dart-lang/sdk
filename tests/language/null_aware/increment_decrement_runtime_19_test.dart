// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify semantics of the ?. operator when it appears in a postincrement or
// preincrement expression (or a postdecrement or predecrement expression).

import "package:expect/expect.dart";
import "conditional_access_helper.dart" as h;

class C {
  int v;
  C(this.v);
  static late int staticInt;
}

class D {
  E v;
  D(this.v);
  static late E staticE;
}

class E {
  G operator +(int i) => new I();
  G operator -(int i) => new I();
}

class F {}

class G extends E implements F {}

class H {}

class I extends G implements H {}

C? nullC() => null;

main() {
  // Make sure the "none" test fails if assignment to "?." is not implemented.
  // This makes status files easier to maintain.
  nullC()?.v = 1;

  // e1?.v++ is equivalent to ((x) => x == null ? null : x.v++)(e1).



  // C?.v++ is equivalent to C.v++.



  // The static type of e1?.v++ is the same as the static type of e1.v.







  // e1?.v-- is equivalent to ((x) => x == null ? null : x.v--)(e1).



  // C?.v-- is equivalent to C.v--.



  // The static type of e1?.v-- is the same as the static type of e1.v.







  // ++e1?.v is equivalent to e1?.v += 1.



  // ++C?.v is equivalent to C?.v += 1.



  // The static type of ++e1?.v is the same as the static type of e1.v + 1.
  { var d = new D(new E()) as D?; F? f = ++d?.v; Expect.identical(d!.v, f); }






  // --e1?.v is equivalent to e1?.v -= 1.



  // --C?.v is equivalent to C?.v -= 1.



  // The static type of --e1?.v is the same as the static type of e1.v - 1.






}

// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify semantics of the ?. operator when it appears on the LHS of an
// assignment.

import "package:expect/expect.dart";
import "conditional_access_helper.dart" as h;

bad() {
  Expect.fail('Should not be executed');
}

class B {}

class C extends B {
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

  // e1?.v = e2 is equivalent to ((x) => x == null ? null : x.v = e2)(e1).



  // C?.v = e2 is equivalent to C.v = e2.

  { h.C.staticInt = 1; Expect.equals(2, h.C?.staticInt = 2); Expect.equals(2, h.C.staticInt); }

  // The static type of e1?.v = e2 is the static type of e2.







  // Exactly the same errors that would be caused by e1.v = e2 are
  // also generated in the case of e1?.v = e2.



  // e1?.v op= e2 is equivalent to ((x) => x?.v = x.v op e2)(e1).



  // C?.v op= e2 is equivalent to C.v op= e2.


  // The static type of e1?.v op= e2 is the static type of e1.v op e2.




  // Let T be the static type of e1 and let y be a fresh variable of type T.
  // Exactly the same errors that would be caused by y.v op e2 are
  // also generated in the case of e1?.v op= e2.









  // '?.' cannot be used to assign to toplevel properties in libraries imported
  // via prefix.



}

// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

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
  // Make sure the "none" test fails if property access using "?." is not
  // implemented.  This makes status files easier to maintain.
  nullC()?.v;

  // e1?.id is equivalent to ((x) => x == null ? null : x.id)(e1).



  // C?.id is equivalent to C.id.
  { C.staticInt = 1; Expect.equals(1, C?.staticInt); }


  // The static type of e1?.d is the static type of e1.id.







  // Let T be the static type of e1 and let y be a fresh variable of type T.
  // Exactly the same static warnings that would be caused by y.id are also
  // generated in the case of e1?.id.



  // '?.' cannot be used to access toplevel properties in libraries imported via
  // prefix.


  // Nor can it be used to access the hashCode getter on the class Type.


}

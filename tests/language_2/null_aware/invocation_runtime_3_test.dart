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
  f(callback()) => callback();
  int g(int callback()) => callback();
  static staticF(callback()) => callback();
  static int staticG(int callback()) => callback();
}

C nullC() => null;

main() {
  // Make sure the "none" test fails if method invocation using "?." is not
  // implemented.  This makes status files easier to maintain.
  nullC()?.f(null);

  // o?.m(...) is equivalent to ((x) => x == null ? null : x.m(...))(o).



  // C?.m(...) is equivalent to C.m(...).
  Expect.equals(1, C?.staticF(() => 1));


  // The static type of o?.m(...) is the same as the static type of
  // o.m(...).









  // Let T be the static type of o and let y be a fresh variable of type T.
  // Exactly the same static warnings that would be caused by y.m(...) are also
  // generated in the case of o?.m(...).



  // '?.' can't be used to access toplevel functions in libraries imported via
  // prefix.


  // Nor can it be used to access the toString method on the class Type.


}

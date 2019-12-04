// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Validate the following spec text from section 16.14.3 (Unqualified
// invocation):
//     An unqualifiedfunction invocation i has the form
//     id(a1, ..., an, xn+1 : an+1, ..., xn+k : an+k),
//     where id is an identifier.
//     If there exists a lexically visible declaration named id, let fid be the
//   innermost such declaration.  Then:
//     - If fid is a prefix object, a compile-time error occurs.

import "empty_library.dart" as p;

class Base {
  void p() {}
}

class Derived extends Base {
  void f() {

  }
}

main() {
  new Derived().f();

}

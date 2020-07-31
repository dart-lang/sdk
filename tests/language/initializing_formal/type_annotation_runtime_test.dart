// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing the static checks for type annotations on initializing formals.

class C {
  num a;
  C.sameType(num this.a);
  C.subType(int this.a);


}

main() {
  new C.sameType(3.14);
  new C.subType(42);


}

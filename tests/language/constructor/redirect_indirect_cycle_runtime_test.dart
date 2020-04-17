// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  var x;
  A(x) : this.named(x, 0);
  A.named(x, int y)
      // Redirecting constructors must not be cyclic.

      ;
}

main() {
  new A(10);
}

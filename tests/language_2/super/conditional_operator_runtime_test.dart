// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that the ?. operator cannot be used with "super".

class B {
  B();
  B.namedConstructor();
  var field = 1;
  method() => 1;
}

class C extends B {
  C()

  ;

  test() {

















  }
}

main() {
  new C().test();
}

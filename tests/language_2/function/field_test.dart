// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--fatal-type-errors --enable_type_checks
//
// Test of calling Function, which is field of some class.

import "package:expect/expect.dart";

class Wrapper {
  Function f;
}

main() {
  Wrapper w = new Wrapper();
  w.f = () {
    return 42;
  };
  Expect.equals(42, w.f());
}

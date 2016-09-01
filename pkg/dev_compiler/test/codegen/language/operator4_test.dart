// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  operator <(other) => 1;
}

// This triggered a bug in Dart2Js: relational operators were not correctly
// boolified.
foo(a) {
  try {
    if (a < a) {
      return "bad";
    } else {
      return 499;
    }
  } on TypeError catch (e) {
    return 499;
  }
}

main() {
  Expect.equals(499, foo(new A()));
}

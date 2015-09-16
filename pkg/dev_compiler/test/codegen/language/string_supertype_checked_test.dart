// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// This tests a bug in dart2js which caused the compiler to emit bad
// type assertions for supertypes of String.

class A implements Comparable {
  int value;

  A(this.value);

  int compareTo(Comparable other) {
    A o = promote(other);
    return value.compareTo(o.value);
  }

  A promote(var other) {
    return other;
  }
}

main() {
  var a = new A(1);
  var b = new A(2);
  Expect.equals(-1, a.compareTo(b));
}

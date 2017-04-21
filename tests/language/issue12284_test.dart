// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "compiler_annotations.dart";

class A {
  int field;

  @DontInline()
  A(param) {
    // Currently defeat inlining by using a closure.
    var bar = () => 42;
    field = param + 42;
  }
  A.redirect() : this('foo');
}

main() {
  Expect.equals(42 + 42, new A(42).field);
  Expect.throws(
      () => new A.redirect(), (e) => e is ArgumentError || e is TypeError);
}

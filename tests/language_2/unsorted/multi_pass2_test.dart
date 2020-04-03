// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for loading several dart files and resolving superclasses lazily.
// Same as MultiPassTest, except that the file order is reversed.

library MultiPassTest.dart;

import "package:expect/expect.dart";
part "multi_pass_a.dart";
part "multi_pass_b.dart";

class Base {
  Base(this.value) {}
  var value;
}

class MultiPass2Test {
  static testMain() {
    var a = new B(5);
    Expect.equals(5, a.value);
  }
}

main() {
  MultiPass2Test.testMain();
}

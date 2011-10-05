// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that class with const constructor has only final fields.


class NixFinal {
  const NixFinal(var v): finalField = v;  // Expect compile error here.
  final finalField;
  var nixFinalField;
}


class ConstConstructorNegativeTest {
  static testMain() {
    var o = const NixFinal(5);
    Expect.equals(true, false);
  }
}

main() {
  ConstConstructorNegativeTest.testMain();
}

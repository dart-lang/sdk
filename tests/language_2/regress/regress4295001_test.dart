// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Issue4295001Test {
  String foo;
  Issue4295001Test(String s) : this.foo = s {
    var f = () => s;
  }

  static void testMain() {
    var d = new Issue4295001Test("Hello");
  }
}

main() {
  Issue4295001Test.testMain();
}

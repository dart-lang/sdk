// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test function equality with null.

import "package:expect/expect.dart";

class A {
  foo() {}
}

main() {
  var a = new A();
  var f = a.foo;
  Expect.isFalse(f == null);
  Expect.isFalse(null == f);
}

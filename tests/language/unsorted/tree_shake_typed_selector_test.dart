// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that dart2js emits code for classes that implement another
// class.

import "package:expect/expect.dart";

class A {
  factory A() => new B();
  foo() => 0;
}

class B implements A {
  foo() => 42;
}

main() {
  var a = new A();
  if (a is A) {
    Expect.equals(42, a.foo());
  } else {
    Expect.fail('Should not be here');
  }
}

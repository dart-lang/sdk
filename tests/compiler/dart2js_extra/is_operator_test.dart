// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

class A {}

class B extends A {}

main() {
  var a = new A();
  var b = new B();

  Expect.isTrue(a is A);
  Expect.isTrue(a is Object);
  Expect.isTrue(!(a is B));

  Expect.isTrue(b is A);
  Expect.isTrue(b is Object);
  Expect.isTrue(b is B);

  Expect.equals("true", (a is A).toString());
  Expect.equals("true", (a is Object).toString());
  Expect.equals("false", (a is B).toString());

  Expect.equals("true", (b is A).toString());
  Expect.equals("true", (b is Object).toString());
  Expect.equals("true", (b is B).toString());

  var c = new A();
  Expect.isTrue(c is Object);

  c = new A();
  Expect.equals("true", (c is Object).toString());
}

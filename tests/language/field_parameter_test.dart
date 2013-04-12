// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing setting/getting of instance fields.

import "package:expect/expect.dart";

class A {
  var x = 4;
  A(this.x);
  A.named([this.x]);
  A.named2([this.x = 2]);
  A.named3();
}

class B extends A {
  B(x) : super(x + 10);
  B.named_() : super.named();
  B.named(x) : super.named(x + 10);
  B.named2_() : super.named2();
  B.named2(x) : super.named2(x + 10);
  B.named3() : super.named3();
}

main() {
  Expect.equals(0, new A(0).x);
  Expect.equals(null, new A.named().x);
  Expect.equals(1, new A.named(1).x);
  Expect.equals(2, new A.named2().x);
  Expect.equals(3, new A.named2(3).x);
  Expect.equals(4, new A.named3().x);

  Expect.equals(10, new B(0).x);
  Expect.equals(null, new B.named_().x);
  Expect.equals(11, new B.named(1).x);
  Expect.equals(2, new B.named2_().x);
  Expect.equals(13, new B.named2(3).x);
  Expect.equals(4, new B.named3().x);
}

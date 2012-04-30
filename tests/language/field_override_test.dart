// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test overriding of fields.


class A {}
class B1 extends A {}
class B2 extends A {}

class Super {
  Super() : super();

  B1 field;
}

class Sub extends Super {
  Sub() : super();

  A field;
}

class SubSub extends Super {
  SubSub() : super();

  // B2 not assignable to B1
  B2 field;  /// 01: static type warning
}

main() {
  SubSub val1 = new SubSub();
  val1.field = new B2(); /// 02: static type warning
  Expect.equals(true, val1.field is B2); /// 02: continued

  Sub val2 = new Sub();
  val2.field = new A();
  Expect.equals(true, val2.field is A);
  Expect.equals(false, val2.field is B1);
  Expect.equals(false, val2.field is B2);

  Super val3 = new Super();
  val3.field = new B1();
  Expect.equals(true, val3.field is B1);
  Expect.equals(false, val3.field is B2);
}

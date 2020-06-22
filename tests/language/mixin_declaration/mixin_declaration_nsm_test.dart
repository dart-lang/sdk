// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

abstract class Bar {
  String bar();
}

abstract class Foo {
  String foo();
}

mixin M implements Bar {
  dynamic noSuchMethod(i) => "M:${i.memberName == #foo ? "foo" : "bar"}";
}

abstract class C {
  dynamic noSuchMethod(i) => "C:${i.memberName == #foo ? "foo" : "bar"}";
}

abstract class D {
  String foo() => "D:foo";
  String bar() => "D:bar";
}

class A1 extends Foo with M {}
class A2 extends C with M implements Foo {}
class A3 extends D with M implements Foo {}

main() {
  Expect.equals("M:foo", A1().foo());
  Expect.equals("M:bar", A1().bar());
  Expect.equals("M:foo", A2().foo());
  Expect.equals("M:bar", A2().bar());
  Expect.equals("D:foo", A3().foo());
  Expect.equals("D:bar", A3().bar());
}
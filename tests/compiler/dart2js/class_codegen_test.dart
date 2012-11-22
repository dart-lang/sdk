// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

import 'compiler_helper.dart';
import 'parser_helper.dart';

const String TEST_ONE = r"""
class A { }
class B { }

main() {
  new A();
  new B();
}
""";

const String TEST_TWO = r"""
class A { }
class B extends A { }

main() {
  new A();
  new B();
}
""";

const String TEST_THREE = r"""
class B extends A { }
class A { }

main() {
  new B();
  new A();
}
""";

const String TEST_FOUR = r"""
class A {
  var x;
}

class B extends A {
  var y;
  var z;
}

main() {
  new B();
}
""";

const String TEST_FIVE = r"""
class A {
  var a;
  A(a) : this.a = a {}
}

main() {
  new A(3);
}
""";

twoClasses() {
  String generated = compileAll(TEST_ONE);
  Expect.isTrue(generated.contains('\$.A = {\n "super": "Object"'));
  Expect.isTrue(generated.contains('\$.B = {\n "super": "Object"'));
}

subClass() {
  checkOutput(String generated) {
    Expect.isTrue(generated.contains('\$.A = {\n "super": "Object"'));
    Expect.isTrue(generated.contains('\$.B = {\n "super": "A"'));
  }

  checkOutput(compileAll(TEST_TWO));
  checkOutput(compileAll(TEST_THREE));
}

fieldTest() {
  String generated = compileAll(TEST_FOUR);
  Expect.isTrue(generated.contains(r"""
$.B = {"": ["y", "z", "x"],
 "super": "A"
}"""));
}

constructor1() {
  String generated = compileAll(TEST_FIVE);
  Expect.isTrue(generated.contains(r"new $.A(a);"));
}

main() {
  twoClasses();
  subClass();
  fieldTest();
  constructor1();
}

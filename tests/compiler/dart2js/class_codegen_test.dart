// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

import 'dart:async';
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
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
  asyncTest(() => compileAll(TEST_ONE).then((generated) {
    Expect.isTrue(generated.contains(new RegExp('A: {[ \n]*"\\^": "Object;"')));
    Expect.isTrue(generated.contains(new RegExp('B: {[ \n]*"\\^": "Object;"')));
  }));
}

subClass() {
  checkOutput(String generated) {
    Expect.isTrue(generated.contains(new RegExp('A: {[ \n]*"\\^": "Object;"')));
    Expect.isTrue(generated.contains(new RegExp('B: {[ \n]*"\\^": "A;"')));
  }

  asyncTest(() => compileAll(TEST_TWO).then(checkOutput));
  asyncTest(() => compileAll(TEST_THREE).then(checkOutput));
}

fieldTest() {
  asyncTest(() => compileAll(TEST_FOUR).then((generated) {
    Expect.isTrue(generated.contains(
        new RegExp('B: {[ \n]*"\\^": "A;y,z,x",[ \n]*static:')));
  }));
}

constructor1() {
  asyncTest(() => compileAll(TEST_FIVE).then((generated) {
    Expect.isTrue(generated.contains(new RegExp(r"new [$A-Z]+\.A\(a\);")));
  }));
}

main() {
  twoClasses();
  subClass();
  fieldTest();
  constructor1();
}

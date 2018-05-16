// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import '../compiler_helper.dart';

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

twoClasses() async {
  String generated = await compileAll(TEST_ONE);
  Expect.isTrue(generated.contains(new RegExp('A: {[ \n]*"\\^": "Object;"')));
  Expect.isTrue(generated.contains(new RegExp('B: {[ \n]*"\\^": "Object;"')));
}

subClass() async {
  checkOutput(String generated) {
    Expect.isTrue(generated.contains(new RegExp('A: {[ \n]*"\\^": "Object;"')));
    Expect.isTrue(generated.contains(new RegExp('B: {[ \n]*"\\^": "A;"')));
  }

  checkOutput(await compileAll(TEST_TWO));
  checkOutput(await compileAll(TEST_THREE));
}

fieldTest() async {
  String generated = await compileAll(TEST_FOUR);
  Expect.isTrue(generated
      .contains(new RegExp('B: {[ \n]*"\\^": "A;y,z,x",[ \n]*static:')));
}

constructor1() async {
  String generated = await compileAll(TEST_FIVE);
  Expect.isTrue(generated.contains(new RegExp(r"new [$A-Z]+\.A\(a\);")));
}

main() {
  runTests() async {
    await twoClasses();
    await subClass();
    await fieldTest();
    await constructor1();
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}

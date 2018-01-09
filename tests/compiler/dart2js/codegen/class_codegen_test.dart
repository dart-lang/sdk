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

twoClasses(CompileMode compileMode) async {
  String generated = await compileAll(TEST_ONE, compileMode: compileMode);
  Expect.isTrue(generated.contains(new RegExp('A: {[ \n]*"\\^": "Object;"')));
  Expect.isTrue(generated.contains(new RegExp('B: {[ \n]*"\\^": "Object;"')));
}

subClass(CompileMode compileMode) async {
  checkOutput(String generated) {
    Expect.isTrue(generated.contains(new RegExp('A: {[ \n]*"\\^": "Object;"')));
    Expect.isTrue(generated.contains(new RegExp('B: {[ \n]*"\\^": "A;"')));
  }

  checkOutput(await compileAll(TEST_TWO, compileMode: compileMode));
  checkOutput(await compileAll(TEST_THREE, compileMode: compileMode));
}

fieldTest(CompileMode compileMode) async {
  String generated = await compileAll(TEST_FOUR, compileMode: compileMode);
  Expect.isTrue(generated
      .contains(new RegExp('B: {[ \n]*"\\^": "A;y,z,x",[ \n]*static:')));
}

constructor1(CompileMode compileMode) async {
  String generated = await compileAll(TEST_FIVE, compileMode: compileMode);
  Expect.isTrue(generated.contains(new RegExp(r"new [$A-Z]+\.A\(a\);")));
}

main() {
  runTests(CompileMode compileMode) async {
    await twoClasses(compileMode);
    await subClass(compileMode);
    await fieldTest(compileMode);
    await constructor1(compileMode);
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTests(CompileMode.memory);
    print('--test from kernel------------------------------------------------');
    await runTests(CompileMode.kernel);
  });
}

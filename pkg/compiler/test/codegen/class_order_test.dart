// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7
// Test that parameters keep their names in the output.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import '../helpers/compiler_helper.dart';

const String TEST_ONE = r"""
class A { foo() => 499; }
class B { bar() => 499; }
class C { gee() => 499; }

void main() {
  new C().gee();
  new B().bar();
  new A().foo();
}
""";

const String TEST_TWO = r"""
class A extends B { foo() => 499; }
class B extends C { bar() => 499; }
class C { gee() => 499; }

void main() {
  new C().gee();
  new B().bar();
  new A().foo();
}
""";

main() {
  // Make sure that class A, B and C are emitted in that order. For simplicity
  // we just verify that their members are in the correct order.
  RegExp regexp = new RegExp(r"foo\$0?:(.|\n)*bar\$0:(.|\n)*gee\$0:");

  runTests() async {
    String generated1 = await compileAll(TEST_ONE);
    Expect.isTrue(regexp.hasMatch(generated1));

    String generated2 = await compileAll(TEST_TWO);
    Expect.isTrue(regexp.hasMatch(generated2));
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import '../helpers/compiler_helper.dart';

const String TEST = r"""
class A {
  A.foo() {}
  A();
}
main() {
  new A();
  new A.foo();
}
""";

main() {
  runTest() async {
    String generated = await compileAll(TEST);
    // No methods (including no constructor body method.
    Expect.isTrue(generated.contains('.A.prototype = {}'));
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';

const String TEST1 = r"""
class A implements List {
  factory A() {
    // Avoid inlining by using try/catch.
    try {
      return new List();
    } catch (e) {
    }
  }
}

main() {
  new A()[0] = 42;
}
""";

main() {
  runTest({bool useKernel}) async {
    String generated = await compileAll(TEST1,
        compileMode: useKernel ? CompileMode.kernel : CompileMode.memory);
    // Check that we're using the index operator on the object returned
    // by the A factory.
    Expect.isTrue(generated.contains('[0] = 42'));
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}

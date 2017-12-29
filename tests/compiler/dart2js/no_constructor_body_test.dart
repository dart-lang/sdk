// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';

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
  runTest({bool useKernel}) async {
    String generated = await compileAll(TEST,
        compileMode: useKernel ? CompileMode.kernel : CompileMode.memory);

    Expect.isTrue(generated
        .contains(new RegExp('A: {[ \n]*"\\^": "Object;",[ \n]*static:')));
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}

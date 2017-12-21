// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';

String TEST = r'''
main() {
  foo(null);
}
foo(a) {
  if (a != null) return 42;
  return 54;
}
''';

main() {
  runTest({bool useKernel}) async {
    String generated = await compileAll(TEST,
        compileMode: useKernel ? CompileMode.kernel : CompileMode.memory);
    Expect.isFalse(generated.contains('return 42'), 'dead code not eliminated');
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}

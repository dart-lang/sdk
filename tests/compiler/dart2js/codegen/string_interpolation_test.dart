// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import '../compiler_helper.dart';

main() {
  runTests({bool useKernel}) async {
    CompileMode compileMode =
        useKernel ? CompileMode.kernel : CompileMode.memory;

    String code1 = await compileAll(
        r'''main() { return "${2}${true}${'a'}${3.14}"; }''',
        compileMode: compileMode);
    Expect.isTrue(code1.contains(r'2truea3.14'));

    String code2 = await compileAll(
        r'''main() { return "foo ${new Object()}"; }''',
        compileMode: compileMode);
    Expect.isFalse(code2.contains(r'$add'));
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTests(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTests(useKernel: true);
  });
}

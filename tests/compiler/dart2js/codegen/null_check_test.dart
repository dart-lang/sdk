// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import '../compiler_helper.dart';
import "package:async_helper/async_helper.dart";

const String TEST1 = r"""
main() {
  var foo;
  if (main() == 5) {
    foo = [0];
  }
  return foo[0];
}
""";

main() {
  runTest({bool useKernel}) async {
    String generated = await compileAll(TEST1, useKernel: useKernel);
    Expect.isFalse(generated.contains('foo.length'));
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}

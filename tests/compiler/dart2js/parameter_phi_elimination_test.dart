// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test. Failed due to trying to detach an HLocal twice.

// VMOptions=--enable_asserts

import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String SOURCE = r"""
bool baz(int a, int b) {
  while (a == b || a < b) {
    a = a + b;
  }
  return a == b;
}
""";

main() {
  runTest({bool useKernel}) async {
    await compile(SOURCE, entry: "baz", useKernel: useKernel);
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}

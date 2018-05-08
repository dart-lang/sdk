// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import '../compiler_helper.dart';

const String TEST_NULL0 = r"""
class A { static var x; }

main() { return A.x; }
""";

const String TEST_NULL1 = r"""
var x;

main() { return x; }
""";

main() {
  runTests({bool useKernel}) async {
    String generated1 = await compileAll(TEST_NULL0, useKernel: useKernel);
    Expect.isTrue(generated1.contains("null"));

    String generated2 = await compileAll(TEST_NULL1, useKernel: useKernel);
    Expect.isTrue(generated2.contains("null"));
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTests(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTests(useKernel: true);
  });
}

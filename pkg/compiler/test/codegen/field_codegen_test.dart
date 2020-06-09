// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7
// Test that parameters keep their names in the output.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import '../helpers/compiler_helper.dart';

const String TEST_NULL0 = r"""
class A { static var x; }

main() { return A.x; }
""";

const String TEST_NULL1 = r"""
var x;

main() { return x; }
""";

main() {
  runTests() async {
    String generated1 = await compileAll(TEST_NULL0);
    Expect.isTrue(generated1.contains("null"));

    String generated2 = await compileAll(TEST_NULL1);
    Expect.isTrue(generated2.contains("null"));
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}

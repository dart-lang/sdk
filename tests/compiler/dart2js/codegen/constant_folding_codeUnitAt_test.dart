// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test constant folding on numbers.

import 'package:async_helper/async_helper.dart';
import '../compiler_helper.dart';

const String TEST_1 = """
foo() {
  var a = 'Hello';
  var b = 0;
  return a.codeUnitAt(b);
}
""";

// No folding of index type error.
const String TEST_2 = """
foo() {
  var a = 'Hello';
  var b = 1.5;
  return a.codeUnitAt(b);
}
""";

// No folding of index range error.
const String TEST_3 = """
foo() {
  var a = 'Hello';
  var b = 55;
  return a.codeUnitAt(b);
}
""";

main() {
  runTests({bool useKernel}) async {
    await compileAndMatch(TEST_1, 'foo', new RegExp(r'return 72'),
        useKernel: useKernel);
    await compileAndDoNotMatch(TEST_1, 'foo', new RegExp(r'Hello'),
        useKernel: useKernel);
    await compileAndMatch(TEST_2, 'foo', new RegExp(r'Hello'),
        useKernel: useKernel);
    await compileAndMatch(TEST_3, 'foo', new RegExp(r'Hello'),
        useKernel: useKernel);
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTests(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTests(useKernel: true);
  });
}

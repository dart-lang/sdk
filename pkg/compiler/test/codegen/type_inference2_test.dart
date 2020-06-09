// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import '../helpers/compiler_helper.dart';

const String TEST_ONE = r"""
sum(param0, param1) {
  var sum = 0;
  for (var i = param0; i < param1; i += 1) sum = sum + i;
  return sum;
}
""";

main() {
  runTest() async {
    await compileAndMatchFuzzy(TEST_ONE, 'sum', r"\+\+x");
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}

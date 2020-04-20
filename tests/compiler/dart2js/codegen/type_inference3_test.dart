// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';
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
    await compile(TEST_ONE, entry: 'sum', check: (String generated) {
      RegExp regexp = new RegExp(getNumberTypeCheck('(param1|b)'));
      Expect.isTrue(
          regexp.hasMatch(generated), '$regexp not found in:\n$generated');
    });
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import '../helpers/compiler_helper.dart';

const String TEST_ONE = r"""
foo() {
  print([1, 2]);
  print([3]);
  var c = [4, 5];
  print(c);
}
""";

main() {
  runTest() async {
    await compile(TEST_ONE, entry: 'foo', check: (String generated) {
      Expect.isTrue(generated.contains('print([1, 2]);'),
          "Code pattern 'print([1, 2]);' not found in\n$generated");
      Expect.isTrue(generated.contains('print([3]);'),
          "Code pattern 'print([3]);' not found in\n$generated");
      Expect.isTrue(generated.contains('print([4, 5]);'),
          "Code pattern 'print([4, 5]);' not found in\n$generated");
    });
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}

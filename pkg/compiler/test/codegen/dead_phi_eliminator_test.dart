// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import '../helpers/compiler_helper.dart';

const String TEST_ONE = r"""
void foo(bar) {
  var toBeRemoved = 1;
  if (bar) {
    toBeRemoved = 2;
  } else {
    toBeRemoved = 3;
  }
}
""";

main() {
  runTest() async {
    await compile(
      TEST_ONE,
      entry: 'foo',
      check: (String generated) {
        RegExp regexp = RegExp("toBeRemoved");
        Expect.isTrue(!regexp.hasMatch(generated));
      },
    );
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}

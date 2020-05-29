// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7
// Test that parameters keep their names in the output.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import '../helpers/compiler_helper.dart';

main() {
  // For a function with only one variable we declare it inline for more
  // compactness.  Test that we don't also declare it at the start of the
  // method.
  runTest() async {
    String generated = await compile(
        'final List a = const ["bar", "baz"];'
        'int foo() {'
        '  for (int i = 0; i < a.length; i++) {'
        '    print(a[i]);'
        '  }'
        '}',
        entry: 'foo',
        minify: false);
    RegExp re = new RegExp(r"var ");
    Expect.isTrue(re.hasMatch(generated));
    print(generated);
    Expect.equals(1, re.allMatches(generated).length);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import '../helpers/compiler_helper.dart';

const String TEST_ONE = r"""
class A {}
bool foo(bar) {
  var x = A();
  var y = A();
  return identical(x, y);
}
""";

main() {
  runTest() async {
    await compile(
      TEST_ONE,
      entry: 'foo',
      check: (String generated) {
        // Check that no boolify code is generated.
        RegExp regexp = RegExp("=== true");
        Iterator matches = regexp.allMatches(generated).iterator;
        Expect.isFalse(matches.moveNext());

        regexp = RegExp("===");
        matches = regexp.allMatches(generated).iterator;
        Expect.isTrue(matches.moveNext());
        Expect.isFalse(matches.moveNext());
      },
    );
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}

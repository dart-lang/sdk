// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import '../helpers/compiler_helper.dart';

const String TEST1 = r"""
main() {
  var a = 52;
  var f = () => a + 87;
  f();
}
""";

const String TEST2 = r"""
main() {
  var a = 52;
  var g = () { a = 48; };
  var f = () => a + 87;
  f();
  g();
}
""";

const String TEST3 = r"""
main() {
  dynamic a = 52;
  var g = () { a = 'foo'; };
  var f = () => a + 87;
  f();
  g();
}
""";

main() {
  runTests() async {
    // Test that we know the type of captured, non-mutated variables.
    String generated1 = await compileAll(TEST1);
    Expect.isTrue(generated1.contains('+ 87'));

    // Test that we know the type of captured, mutated variables.
    String generated2 = await compileAll(TEST2);
    Expect.isTrue(generated2.contains('+ 87'));

    // Test that we know when types of a captured, mutated variable
    // conflict.
    String generated3 = await compileAll(TEST3);
    Expect.isFalse(generated3.contains('+ 87'));
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}

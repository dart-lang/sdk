// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
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
      Expect.isTrue(
          generated.contains('A.print(A._setArrayType([1, 2], t1));'),
          "Code pattern 'A.print(A._setArrayType([1, 2], t1));' "
          "not found in\n$generated");
      Expect.isTrue(
          generated.contains('A.print(A._setArrayType([3], t1));'),
          "Code pattern 'A.print(A._setArrayType([3], t1));' "
          "not found in\n$generated");
      Expect.isTrue(
          generated.contains('A.print(A._setArrayType([4, 5], t1));'),
          "Code pattern 'A.print(A._setArrayType([4, 5], t1));' "
          "not found in\n$generated");
    });
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}

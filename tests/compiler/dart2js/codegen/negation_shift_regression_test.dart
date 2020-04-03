// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import '../helpers/compiler_helper.dart';

// A bug in UnaryNegateSpecializer left '-a' labelled as 'positive', allowing
// misoptimization of '<<'.
const String TEST1 = r"""
foo(param) {
  var a = param ? 0xFFFFFFFF : 1;
  return 1 << -a;
  // present: '$shl'
  // absent: '_shlPositive'
}
""";

const String TEST2 = r"""
foo(param) {
  var a = param ? 0xFFFFFFFF : 1;
  return 1 << a;
  // present: '_shlPositive'
  // absent: '$shl'
}
""";

main() {
  runTests() async {
    check(String test) async {
      await compile(test, entry: 'foo', check: checkerForAbsentPresent(test));
    }

    await check(TEST1);
    await check(TEST2);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}

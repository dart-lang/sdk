// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that logical or-expressions don't introduce unnecessary nots.
// See http://dartbug.com/17027

import 'package:async_helper/async_helper.dart';
import '../helpers/compiler_helper.dart';

const String TEST_ONE = r"""
foo(bar, gee) {
  bool cond1 = bar();
  if (cond1 || gee()) gee();
  if (cond1 || gee()) gee();

  // We want something like:
  //     var t1 = bar.call$0();
  //     if (t1 || gee.call$0()) gee.call$0();
  //     if (t1 || gee.call$0()) gee.call$0();

  // absent: 'if (!'
  // present: /if \(\w+ \|\|/
}
""";

const String TEST_TWO = r"""
void foo(list, bar) {
  if (list == null) bar();
  if (list == null || bar()) bar();
  if (list == null || bar()) bar();

  // We want something like:
  //     var t1 = list == null;
  //     if (t1) bar.call$0();
  //     if (t1 || bar.call$0()) bar.call$0();
  //     if (t1 || bar.call$0()) bar.call$0();

  // absent: 'if (!'
  // present: /if \(\w+ \|\|/
}
""";

main() {
  runTests() async {
    Future check(String test) {
      return compile(test, entry: 'foo', check: checkerForAbsentPresent(test));
    }

    await check(TEST_ONE);
    await check(TEST_TWO);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import '../helpers/compiler_helper.dart';

// Tests for
const String TEST_1 = r"""
  foo() {
    int a = 120;
    String b = 'hello';
    return 'u${a}v${b}w';
  }
""";

const String TEST_2 = r"""
  foo(a, b) {
    return 'aaaaa${a}xxxxx'
           "yyyyy${b}zzzzz";
  }
""";

const String TEST_3 = r"""
  foo(a) {
    var b = '$a#';
    return '${b}x${b}';
  }
""";

const String TEST_4 = r"""
  foo(a) {
    var b = [];
    if (a) b.add(123);
    return '${b.length}';
  }
""";

main() {
  runTests() async {
    check(String test, String contained) async {
      String generated = await compile(test, entry: 'foo');
      Expect.isTrue(generated.contains(contained), contained);
    }

    // Full substitution.
    await check(TEST_1, r'"u120vhellow"');

    // Adjacent string fragments get merged.
    await check(TEST_2, r'"xxxxxyyyyy"');

    // 1. No merging of fragments that are multi-use.  Prevents exponential code
    //    and keeps author's manual CSE.
    // 2. Know string values require no stringification.
    await check(TEST_3, r'return b + "x" + b');

    // Known int value can be formatted directly.
    await check(TEST_4, r'return "" + b.length');
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}

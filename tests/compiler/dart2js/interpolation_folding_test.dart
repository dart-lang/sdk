// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'compiler_helper.dart';

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
  Future check(String test, String contained) {
    return compile(test, entry: 'foo').then((String generated) {
      Expect.isTrue(generated.contains(contained), contained);
    });
  }

  asyncTest(() => Future.wait([
    // Full substitution.
    check(TEST_1, r'"u120vhellow"'),

    // Adjacent string fragments get merged.
    check(TEST_2, r'"xxxxxyyyyy"'),

    // 1. No merging of fragments that are multi-use.  Prevents exponential code
    //    and keeps author's manual CSE.
    // 2. Know string values require no stringification.
    check(TEST_3, r'return b + "x" + b'),

    // Known int value can be formatted directly.
    check(TEST_4, r'return "" + b.length'),
  ]));
}

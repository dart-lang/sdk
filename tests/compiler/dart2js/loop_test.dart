// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String TEST_ONE = r"""
foo(a) {
  int x = 0;
  for (int i = 0; i < 10; i++) {
    x += i;
  }
  return x;
}
""";

const String TEST_TWO = r"""
foo(a) {
  int x = 0;
  int i = 0;
  while (i < 10) {
    x += i;
    i++;
  }
  return x;
}
""";

const String TEST_THREE = r"""
foo(a) {
  int x = 0;
  for (int i = 0; i < 10; i++) {
    if (i == 5) continue;
    x += i;
  }
  return x;
}
""";

const String TEST_FOUR = r"""
foo(a) {
  int x = 0;
  int i = 0;
  while (i < 10) {
    i++;
    if (i == 5) continue;
    x += i;
  }
  return x;
}
""";

main() {
  asyncTest(() => Future.wait([
    compile(TEST_ONE, entry: 'foo', check: (String generated) {
      Expect.isTrue(generated.contains(r'for ('));
    }),
    compile(TEST_TWO, entry: 'foo', check: (String generated) {
      Expect.isTrue(!generated.contains(r'break'));
    }),
    compile(TEST_THREE, entry: 'foo', check: (String generated) {
      Expect.isTrue(generated.contains(r'continue'));
    }),
    compile(TEST_FOUR, entry: 'foo', check: (String generated) {
      Expect.isTrue(generated.contains(r'continue'));
    }),
  ]));
}

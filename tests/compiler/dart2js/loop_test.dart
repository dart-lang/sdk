// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("compiler_helper.dart");

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
  for (int i in a) {
    x += i;
  }
  return x;
}
""";


const String TEST_FOUR = r"""
foo(a) {
  int x = 0;
  for (int i = 0; i < 10; i++) {
    if (i == 5) continue;
    x += i;
  }
  return x;
}
""";

const String TEST_FIVE = r"""
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

const String TEST_SIX = r"""
foo(a) {
  int x = 0;
  for (int i in a) {
    if (i == 5) continue;
    x += i;
  }
  return x;
}
""";


main() {
  String generated = compile(TEST_ONE, 'foo');
  Expect.isTrue(generated.contains(r'for ('));
  generated = compile(TEST_TWO, 'foo');
  Expect.isTrue(!generated.contains(r'break'));
  generated = compile(TEST_THREE, 'foo');
  Expect.isTrue(!generated.contains(r'break'));
  generated = compile(TEST_FOUR, 'foo');
  Expect.isTrue(generated.contains(r'continue'));
  generated = compile(TEST_FIVE, 'foo');
  Expect.isTrue(generated.contains(r'continue'));
  generated = compile(TEST_SIX, 'foo');
  Expect.isTrue(generated.contains(r'continue'));
}

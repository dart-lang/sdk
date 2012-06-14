// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("compiler_helper.dart");

final String TEST_ONE = @"""
foo(a) {
  int x = 0;
  for (int i = 0; i < 10; i++) {
    x += i;
  }
  return x;
}
""";

final String TEST_TWO = @"""
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

final String TEST_THREE = @"""
foo(a) {
  int x = 0;
  for (int i in a) {
    x += i;
  }
  return x;
}
""";


final String TEST_FOUR = @"""
foo(a) {
  int x = 0;
  for (int i = 0; i < 10; i++) {
    if (i == 5) continue;
    x += i;
  }
  return x;
}
""";

final String TEST_FIVE = @"""
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

final String TEST_SIX = @"""
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
  Expect.isTrue(generated.contains(@'for ('));
  generated = compile(TEST_TWO, 'foo');
  Expect.isTrue(!generated.contains(@'break'));
  generated = compile(TEST_THREE, 'foo');
  Expect.isTrue(!generated.contains(@'break'));
  generated = compile(TEST_FOUR, 'foo');
  Expect.isTrue(generated.contains(@'continue'));
  generated = compile(TEST_FIVE, 'foo');
  Expect.isTrue(generated.contains(@'continue'));
  generated = compile(TEST_SIX, 'foo');
  Expect.isTrue(generated.contains(@'continue'));
}

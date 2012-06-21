// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("compiler_helper.dart");

final String TEST_ONE = @"""
sum(param0, param1) {
  var sum = 0;
  for (var i = param0; i < param1; i += 1) sum = sum + i;
  return sum;
}
""";

final String TEST_TWO = @"""
foo(int param0) {
  return -param0;
}
""";

final String TEST_TWO_WITH_BAILOUT = @"""
foo(int param0) {
  for (int i = 0; i < 1; i++) {
    param0 = -param0;
  }
  return param0;
}
""";

final String TEST_THREE = @"""
foo(c) {
  for (int i = 0; i < 10; i++) print(c[i]);
}
""";

final String TEST_FOUR = @"""
foo(String c) {
  print(c[0]); // Force a type guard.
  while (true) print(c.length);
}
""";

final String TEST_FIVE = @"""
foo(a) {
  a[0] = 1;
  print(a[1]);
}
""";

final String TEST_FIVE_WITH_BAILOUT = @"""
foo(a) {
  for (int i = 0; i < 1; i++) {
    a[0] = 1;
    print(a[1]);
  }
}
""";

final String TEST_SIX = @"""
foo(a) {
  print(a[0]);
  while (true) {
    a[0] = a[1];
  }
}
""";

main() {
  String generated = compile(TEST_ONE, 'sum');
  Expect.isTrue(generated.contains('sum += i'));
  Expect.isTrue(generated.contains("typeof param1 !== 'number'"));

  generated = compile(TEST_TWO, 'foo');
  RegExp regexp = new RegExp(getNumberTypeCheck('param0'));
  Expect.isTrue(!regexp.hasMatch(generated));

  regexp = const RegExp('-param0');
  Expect.isTrue(!regexp.hasMatch(generated));

  generated = compile(TEST_TWO_WITH_BAILOUT, 'foo');
  regexp = new RegExp(getNumberTypeCheck('param0'));
  Expect.isTrue(regexp.hasMatch(generated));

  regexp = const RegExp('-param0');
  Expect.isTrue(regexp.hasMatch(generated));

  generated = compile(TEST_THREE, 'foo');
  regexp = new RegExp("c[$anyIdentifier]");
  Expect.isTrue(regexp.hasMatch(generated));

  generated = compile(TEST_FOUR, 'foo');
  regexp = new RegExp("c.length");
  Expect.isTrue(regexp.hasMatch(generated));

  generated = compile(TEST_FIVE, 'foo');
  regexp = const RegExp('a.constructor !== Array');
  Expect.isTrue(!regexp.hasMatch(generated));
  Expect.isTrue(generated.contains('index'));
  Expect.isTrue(generated.contains('indexSet'));

  generated = compile(TEST_FIVE_WITH_BAILOUT, 'foo');
  regexp = const RegExp('a.constructor !== Array');
  Expect.isTrue(regexp.hasMatch(generated));
  Expect.isTrue(!generated.contains('index'));
  Expect.isTrue(!generated.contains('indexSet'));

  generated = compile(TEST_SIX, 'foo');
  regexp = const RegExp('a.constructor !== Array');
  Expect.isTrue(regexp.hasMatch(generated));
  Expect.isTrue(!generated.contains('index'));
  Expect.isTrue(!generated.contains('indexSet'));
}

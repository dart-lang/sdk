// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

#import("compiler_helper.dart");

const String TEST_ONE = @"""
void foo(bar) {
  var a = 1;
  if (bar) {
    a = 2;
  } else {
    a = 3;
  }
  print(a);
}
""";

const String TEST_TWO = @"""
void main() {
  var t = 0;
  for (var i = 0; i == 0; i = i + 1) {
    t = t + 10;
  }
  print(t);
}
""";

const String TEST_THREE = @"""
foo(b, c, d) {
  var val = 42;
  if (b) {
    c = c && d;
    if (c) {
      val = 43;
    }
  }
  return val;
}
""";

const String TEST_FOUR = @"""
foo() {
  var cond1 = true;
  var cond2 = false;
  for (var i = 0; cond1; i = i + 1) {
    if (i == 9) cond1 = false;
    for (var j = 0; cond2; j = j + 1) {
      if (j == 9) cond2 = false;
    }
  }
  print(cond1);
  print(cond2);
}
""";

main() {
  String generated = compile(TEST_ONE, 'foo');
  Expect.isTrue(generated.contains('var a = bar === true ? 2 : 3;'));
  Expect.isTrue(generated.contains('print(a);'));

  generated = compile(TEST_TWO, 'main');
  RegExp regexp = new RegExp("t \\+= 10");
  Expect.isTrue(regexp.hasMatch(generated));

  regexp = new RegExp("\\+\\+i");
  Expect.isTrue(regexp.hasMatch(generated));

  generated = compile(TEST_THREE, 'foo');

  // Check that we don't have 'val = val'.
  regexp = const RegExp("val = val;");
  Expect.isTrue(!regexp.hasMatch(generated));

  regexp = const RegExp("return val");
  Expect.isTrue(regexp.hasMatch(generated));
  // Check that a store just after the declaration of the local
  // only generates one instruction.
  regexp = const RegExp(@"val = 42");
  Expect.isTrue(regexp.hasMatch(generated));

  generated = compile(TEST_FOUR, 'foo');

  regexp = const RegExp("cond1 = cond1;");
  Expect.isTrue(!regexp.hasMatch(generated));

  regexp = const RegExp("cond2 = cond2;");
  Expect.isTrue(!regexp.hasMatch(generated));
}

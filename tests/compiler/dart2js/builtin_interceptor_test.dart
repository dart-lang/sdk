// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("compiler_helper.dart");

const String TEST_ONE = @"""
foo(String a) {
  // index into the parameter and move into a loop to make sure we'll get a
  // type guard.
  for (int i = 0; i < 1; i++) {
    print(a[0]);
  }
  return a.length;
}
""";

const String TEST_TWO = @"""
foo() {
  return "foo".length;
}
""";

const String TEST_THREE = @"""
foo() {
  return @"foo".length;
}
""";

const String TEST_FOUR = @"""
foo() {
  return new List().add(2);
}
""";

main() {
  String generated = compile(TEST_ONE, 'foo');
  Expect.isTrue(generated.contains("return a.length;"));

  generated = compile(TEST_TWO, 'foo');
  Expect.isTrue(generated.contains("return 3;"));

  generated = compile(TEST_THREE, 'foo');
  Expect.isTrue(generated.contains("return 3;"));

  generated = compile(TEST_FOUR, 'foo');
  Expect.isTrue(generated.contains("push(2);"));
}

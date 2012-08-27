// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("compiler_helper.dart");

const String TEST_ONE = @"""
void foo(bar) {
  var toBeRemoved = 1;
  if (bar) {
  } else {
  }
  print(toBeRemoved);
}
""";


const String TEST_TWO = @"""
void foo() {
  var temp = 0;
  var toBeRemoved = temp;
  for (var i = 0; i == 0; i = i + 1) {
    toBeRemoved = temp;
  }
  print(toBeRemoved);
}
""";

main() {
  String generated = compile(TEST_ONE, 'foo');
  RegExp regexp = const RegExp("toBeRemoved");
  Expect.isTrue(!regexp.hasMatch(generated));

  generated = compile(TEST_TWO, 'foo');
  regexp = const RegExp("toBeRemoved");
  Expect.isTrue(!regexp.hasMatch(generated));
  regexp = const RegExp("temp");
  Expect.isTrue(!regexp.hasMatch(generated));
}

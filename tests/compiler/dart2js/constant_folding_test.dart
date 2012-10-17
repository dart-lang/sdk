// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test constant folding on numbers.

#import("compiler_helper.dart");

const String NUMBER_FOLDING = """
void main() {
  var a = 4;
  var b = 3;
  print(a + b);
}
""";

const String NEGATIVE_NUMBER_FOLDING = """
void main() {
  var a = 4;
  var b = -3;
  print(a + b);
}
""";

const String NULL_EQUALS_FOLDING = """
foo(a, b, c, d) {
  if (a == null) return 1;
  if (null == b) return 2;
  if (4 == c) return 3;
  if ("foo" == d) return 3;
}
""";

main() {
  compileAndMatch(
      NUMBER_FOLDING, 'main', const RegExp(r"print\(7\)"));
  compileAndMatch(
      NEGATIVE_NUMBER_FOLDING, 'main', const RegExp(r"print\(1\)"));

  String generated = compile(NULL_EQUALS_FOLDING, entry: 'foo');
  RegExp regexp = const RegExp(r'a == null');
  Expect.isTrue(regexp.hasMatch(generated));

  regexp = const RegExp(r'null == b');
  Expect.isTrue(regexp.hasMatch(generated));

  regexp = const RegExp(r'4 === c');
  Expect.isTrue(regexp.hasMatch(generated));

  regexp = const RegExp("'foo' === d");
  Expect.isTrue(regexp.hasMatch(generated));
}

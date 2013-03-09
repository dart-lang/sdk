// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library boolified_operator_test;
import 'compiler_helper.dart';

const String TEST_EQUAL = r"""
foo(param0, param1) {
  if (param0 == param1) return 0;
  return 1;
}
""";

const String TEST_EQUAL_NULL = r"""
foo(param0) {
  if (param0 == null) return 0;
  return 1;
}
""";

const String TEST_LESS = r"""
foo(param0, param1) {
  if (param0 < param1) return 0;
  return 1;
}
""";

const String TEST_LESS_EQUAL = r"""
foo(param0, param1) {
  if (param0 <= param1) return 0;
  return 1;
}
""";
const String TEST_GREATER = r"""
foo(param0, param1) {
  if (param0 > param1) return 0;
  return 1;
}
""";

const String TEST_GREATER_EQUAL = r"""
foo(param0, param1) {
  if (param0 >= param1) return 0;
  return 1;
}
""";

main() {
  RegExp regexp = new RegExp('=== true');

  String generated = compile(TEST_EQUAL, entry: 'foo');
  Expect.isFalse(generated.contains('=== true'));
  Expect.isTrue(generated.contains('eqB'));

  generated = compile(TEST_EQUAL_NULL, entry: 'foo');
  Expect.isFalse(generated.contains('=== true'));
  Expect.isTrue(generated.contains('== null'));

  generated = compile(TEST_LESS, entry: 'foo');
  Expect.isFalse(generated.contains('=== true'));
  Expect.isTrue(generated.contains('ltB'));

  generated = compile(TEST_LESS_EQUAL, entry: 'foo');
  Expect.isFalse(generated.contains('=== true'));
  Expect.isTrue(generated.contains('leB'));
  
  generated = compile(TEST_GREATER, entry: 'foo');
  Expect.isFalse(generated.contains('=== true'));
  Expect.isTrue(generated.contains('gtB'));
  
  generated = compile(TEST_GREATER_EQUAL, entry: 'foo');
  Expect.isFalse(generated.contains('=== true'));
  Expect.isTrue(generated.contains('geB'));
}

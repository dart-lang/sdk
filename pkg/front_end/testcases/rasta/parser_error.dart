// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.
// @dart=2.9
// Copy of third_party/dart-sdk/tests/language/argument_definition_test.dart.

import "package:expect/expect.dart";

int test(a, {b, c}) {
  if (?b) return b;  /// 01: compile-time error
  return a + b + c;
}

main() {
  Expect.equals(6, test(1, b: 2, c:3));
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String TEST_ONE = r"""
foo() {
  return "foo".length;
}
""";

const String TEST_TWO = r"""
foo() {
  return r"foo".length;
}
""";

const String TEST_THREE = r"""
foo() {
  return new List().add(2);
}
""";

main() {
  asyncTest(() => Future.wait([
    compile(TEST_ONE, entry: 'foo', check: (String generated) {
      Expect.isTrue(generated.contains("return 3;"));
    }),
    compile(TEST_TWO, entry: 'foo', check: (String generated) {
      Expect.isTrue(generated.contains("return 3;"));
    }),
    compile(TEST_THREE, entry: 'foo', check: (String generated) {
      Expect.isTrue(generated.contains("push(2);"));
    }),
  ]));
}

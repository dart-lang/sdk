// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String TEST_IF_BOOL_FIRST_INSTRUCTION = r"""
negate(x) {
  if (x is bool) return !x;
  return x;
}
""";

main() {
  asyncTest(() => compile(TEST_IF_BOOL_FIRST_INSTRUCTION, entry: 'negate',
      check: (String generated) {
    Expect.isTrue(generated.contains("!"));  // We want to see !x.
    Expect.isFalse(generated.contains("!="));  // And not !== true.
    Expect.isFalse(generated.contains("true"));
    Expect.isFalse(generated.contains("false"));
  }));
}

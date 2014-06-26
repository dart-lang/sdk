// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String TEST_ONE = r"""
foo() {
  print([1, 2]);
  print([3]);
  var c = [4, 5];
  print(c);
}
""";

main() {
  asyncTest(() => compile(TEST_ONE, entry: 'foo', check: (String generated) {
    Expect.isTrue(generated.contains('print([1, 2]);'));
    Expect.isTrue(generated.contains('print([3]);'));
    Expect.isTrue(generated.contains('print([4, 5]);'));
  }));
}

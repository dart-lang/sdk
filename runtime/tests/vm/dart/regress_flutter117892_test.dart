// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that compiler doesn't crash when uninitialized late variable
// (sentinel) is returned from an async function.
// Regression test for https://github.com/flutter/flutter/issues/117892.

import 'package:expect/expect.dart';

foo() async {
  late int x;
  if (3 != 3) {
    x = 42;
  }
  return x;
}

main() {
  foo().then((_) {
    Expect.fail("Exception should be thrown.");
  }, onError: (_) {});
}

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable_async --optimization-counter-threshold=10

// This tests that captured parameters (by the async-closure) are
// correctly treated in try-catch generated in the async function.
// They must be skipped when generating sync-code in the optimized
// try-block.

import 'package:expect/expect.dart';

import 'dart:async';

check(value) {
  try {
  } finally {
    return value;
  }
}

fail() {
  try {
    Expect.isTrue(false);
  } finally { }
}

foo(i) async {
  var k = await 77;
  var a = "abc${k}";
  if (a != "abc77") fail();
  return k;
}


main() {
  for (int i = 0; i < 20; i++) {
    foo(i).then((value) => Expect.equals(77, value));
  }
}

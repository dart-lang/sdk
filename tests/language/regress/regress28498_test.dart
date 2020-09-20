// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The Kernel async transformer should not skip assert statements.

import 'dart:async';

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

g() async => 21;
f() async => 42;

test() async {
  assert(await g() == await f());
}

main() {
  bool ok = true;
  assert(!(ok = false));
  // !ok iff asserts are enabled.

  asyncStart();
  test().then((_) => Expect.isTrue(ok), onError: (error) {
    // !ok implies error is AssertionError.
    Expect.isTrue(ok || error is AssertionError);
  }).whenComplete(asyncEnd);
}

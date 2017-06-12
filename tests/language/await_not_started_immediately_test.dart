// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that an async function does not start immediately.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

var x = 0;

foo() async {
  x++;
  await 1;
  x++;
}

void main() {
  asyncStart();
  foo().then((_) => Expect.equals(2, x)).whenComplete(asyncEnd);
  Expect.equals(0, x);
}

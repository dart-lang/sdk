// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=5

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

var X = 0;

foo() async {
  Expect.equals(X, 0);
  await 5;
  Expect.equals(X, 10);
  return await 499;
}

main() {
  asyncStart();
  var f = foo();
  f.then((res) {
    Expect.equals(499, res);
    asyncEnd();
  });
  X = 10;
}

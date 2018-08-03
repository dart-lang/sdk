// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

foo() async {
  throw 42;
}

test() async {
  var exception;
  try {
    await foo();
  } catch (e) {
    print(await (e));
    await (exception = await e);
  }
  Expect.equals(42, exception);
}

main() {
  asyncStart();
  test().then((_) => asyncEnd());
}

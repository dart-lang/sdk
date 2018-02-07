// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

var result = "";

foo() {
  result += "foo";
}

bar() async {
  result += "bar";
  await null;
  result += "bar2";
}

main() {
  asyncStart();
  () async {
    var f = new Future(foo);
    var b = bar();
    Expect.equals("bar", result);
    scheduleMicrotask(() => result += "micro");
    await b;
    await f;

    // Validates that bar is scheduled as a microtask, before foo.
    Expect.equals("barbar2microfoo", result);
    asyncEnd();
  }();
}

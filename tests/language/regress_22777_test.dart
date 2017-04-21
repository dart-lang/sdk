// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

var a = 0;

testSync() {
  do {
    continue;
  } while (throw "Error");
  a = 100;
}

testAsync() async {
  do {
    continue;
  } while (await (throw "Error"));
  a = 100;
}

test() async {
  try {
    testSync();
  } catch (e) {
    Expect.equals(e, "Error");
  }
  Expect.equals(a, 0);

  try {
    await testAsync();
  } catch (e) {
    Expect.equals(e, "Error");
  }
  Expect.equals(a, 0);
}

main() {
  asyncStart();
  test().then((_) => asyncEnd());
}

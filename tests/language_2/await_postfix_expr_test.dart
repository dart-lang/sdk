// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

post0(a) async {
  return await a++;
}

post1(a) async {
  return await a++ + await a++;
}

pref0(a) async {
  return await ++a;
}

pref1(a) async {
  return await ++a + await ++a;
}

sum(a) async {
  var s = 0;
  for (int i = 0; i < a.length; /* nothing */) {
    s += a[await i++];
  }
  return s;
}

// Adapted from repro case for issue 22875.
sum2(n) async {
  int i, s = 0;
  for (i = 1; i <= n; await i++) {
    // The loop-local variable j was necessary for the crash in 22785.
    var j = await i;
    s += j;
  }
  return s;
}

test() async {
  Expect.equals(10, await post0(10));
  Expect.equals(21, await post1(10));
  Expect.equals(11, await pref0(10));
  Expect.equals(23, await pref1(10));
  Expect.equals(10, await sum([1, 2, 3, 4]));
  Expect.equals(10, await sum2(4));
}

main() {
  asyncStart();
  test().then((_) {
    asyncEnd();
  });
}

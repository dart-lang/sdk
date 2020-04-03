// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

Stream makeStream(int n) async* {
  for (int i = 0; i < n; i++) yield i;
}

main() {
  f(Stream s) async {
    var r = 0;
    await for (var v in s.take(5)) r += v;
    return r;
  }

  asyncStart();
  f(makeStream(10)).then((v) {
    Expect.equals(10, v);
    asyncEnd();
  });
}

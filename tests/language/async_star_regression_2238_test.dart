// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for issue 2238
import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

main() {
  f() async* {
    label1:
    label2:
    yield 0;
  }

  asyncStart();
  f().toList().then((list) {
    Expect.listEquals([0], list);
    asyncEnd();
  });
}

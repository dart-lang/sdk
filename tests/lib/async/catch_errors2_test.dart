// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';
import 'catch_errors.dart';

main() {
  asyncStart();
  bool futureWasExecuted = false;
  // Make sure that `catchErrors` only closes the error stream when the inner
  // futures are done.
  catchErrors(() {
    new Future(() {
      futureWasExecuted = true;
    });
    return 'allDone';
  }).listen((x) {
      Expect.fail("Unexpected callback");
    },
    onDone: () {
      Expect.isTrue(futureWasExecuted);
      asyncEnd();
    });
}

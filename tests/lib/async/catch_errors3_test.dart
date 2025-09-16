// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

import 'catch_errors.dart';

void main() {
  asyncStart();
  Completer done = Completer();
  bool futureWasExecuted = false;
  bool future2WasExecuted = false;

  // Make sure `catchErrors` never closes its stream.
  catchErrors(() {
    Future(() => 499).then((x) {
      futureWasExecuted = true;
    });
    scheduleMicrotask(() {
      Future(() => 42).then((x) {
        future2WasExecuted = true;
        Expect.isTrue(futureWasExecuted);
        done.complete(true);
      });
    });
  }).listen(
    (x) {
      Expect.fail("Unexpected callback");
    },
    onDone: () {
      Expect.fail("Unexpected callback");
    },
  );
  done.future.whenComplete(asyncEnd);
}

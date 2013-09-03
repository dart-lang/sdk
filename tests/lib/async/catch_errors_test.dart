// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';
import 'catch_errors.dart';

main() {
  asyncStart();
  // Make sure `catchErrors` shuts down the error stream when the synchronous
  // operation is done and there isn't any asynchronous pending callback.
  catchErrors(() {
    return 'allDone';
  }).listen((x) {
      Expect.fail("Unexpected callback");
    },
    onDone: () {
      asyncEnd();
    });
}

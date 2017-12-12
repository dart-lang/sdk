// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

// Tests that an exception thrown from a message handler in a Zone without an
// error handler is propagated synchronously.

main() {
  asyncStart();
  runZoned(() {
    Timer.run(() {
      asyncEnd();
      throw "Exception";
    });
  });
  Expect.throws(waitForEventSync, (e) => e is String);
}

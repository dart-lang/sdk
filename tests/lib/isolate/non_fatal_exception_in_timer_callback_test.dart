// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:io';

import "package:expect/async_helper.dart";

main() async {
  asyncStart();
  // May happen asynchronously, but won't take 10 ms.
  Isolate.current.setErrorsFatal(false);

  Timer(const Duration(milliseconds: 10), () {
    // This unhandled exception should not prevent the last timer from firing.
    throw "Error 1";
  });

  Timer(const Duration(milliseconds: 11), () {
    sleep(const Duration(milliseconds: 30));
    // This unhandled exception should not prevent the last timer from firing.
    throw "Error 2"; // Throws after last timer is due.
  });

  Timer.periodic(const Duration(milliseconds: 30), (t) {
    t.cancel();
    asyncEnd();
  });
}

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:io';

main() async {
  Isolate.current.setErrorsFatal(false);

  new Timer(const Duration(milliseconds: 10), () {
    print("Timer 1");

    // This unhandled exception should not prevent the second timer from firing.
    throw "Oh no!";
  });

  new Timer.periodic(const Duration(milliseconds: 20), (_) {
    print("Timer 2");
    exit(0);
  });

  sleep(const Duration(milliseconds: 30)); //# sleep: ok
  // With sleep: both timers are due at the same wakeup event.
  // Without sleep: the timers get separate wakeup events.
}

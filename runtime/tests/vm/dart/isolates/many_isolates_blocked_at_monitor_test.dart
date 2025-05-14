// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--experimental-shared-data

import "dart:concurrent";
import "dart:isolate";
import "dart:io";

@pragma("vm:shared")
int pending = 0;
@pragma("vm:shared")
late Mutex mutex;
@pragma("vm:shared")
late ConditionVariable condition;

waitForAllToCheckIn() {
  mutex.runLocked(() {
    pending--;
    if (pending == 0) {
      print("notifyAll $pending");
      condition.notifyAll();
    } else {
      while (pending > 0) {
        print("wait $pending");
        condition.wait(mutex);
        print("notified $pending");
      }
    }
    condition.notifyAll();
  });
}

child(_) {
  waitForAllToCheckIn();
}

main() async {
  mutex = new Mutex();
  condition = new ConditionVariable();
  pending = 21;
  for (var i = 0; i < 20; i++) {
    Isolate.spawn(child, null);
  }
  waitForAllToCheckIn();
}

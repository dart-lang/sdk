// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--experimental-shared-data

import "dart:concurrent";
import "dart:isolate";
import "dart:typed_data";

@pragma("vm:shared")
final pending = Uint8List(1);
@pragma("vm:shared")
final mutex = Mutex();
@pragma("vm:shared")
final condition = ConditionVariable();

waitForAllToCheckIn() {
  mutex.runLocked(() {
    pending[0]--;
    if (pending == 0) {
      print("notifyAll $pending");
      condition.notifyAll();
    } else {
      while (pending[0] > 0) {
        print("wait ${pending[0]}");
        condition.wait(mutex);
        print("notified ${pending[0]}");
      }
    }
    condition.notifyAll();
  });
}

child(_) {
  waitForAllToCheckIn();
}

main() async {
  pending[0] = 21;
  for (var i = 0; i < 20; i++) {
    Isolate.spawn(child, null);
  }
  waitForAllToCheckIn();
}

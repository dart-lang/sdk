// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:isolate";

child(msg) {
  // This should work even though the parent isolate is blocked and won't
  // respond to OOB messages such as shutdown requests.
  exit(0);
}

main() {
  Isolate.spawn(child, null);

  // The test harness provides no input, so this will block forever.
  stdin.readByteSync();
}

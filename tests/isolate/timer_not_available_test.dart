// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('timer_not_available');

#import("dart:isolate");

main() {
  bool failed = false;
  try {
    new Timer(0, (_) { });
  } catch (UnsupportedOperationException e) {
    failed = true;
  }
  Expect.isTrue(failed);
  failed = false;
  try {
    var t = new Timer.repeating(10, (_) { });
    t.cancel();
  } catch (UnsupportedOperationException e) {
    failed = true;
  }
  Expect.isTrue(failed);
}

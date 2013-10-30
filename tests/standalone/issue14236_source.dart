// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This is the original dart program that was used to generate the snapshot
// in file issue14236_test.dart
// The original test/main has been commented out and we have a test/main which
// throws an error to ensure that this file is not executed as part of the
// test.

library test.issue14236;
import "dart:isolate";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

/*
test(SendPort replyTo) {
  replyTo.send("from Isolate");
}

main() {
  asyncStart();
  ReceivePort port = new ReceivePort();
  Isolate.spawn(test, port.sendPort);
  port.first.then((msg) {
    Expect.equals("from Isolate", msg);
    asyncEnd();
  });
}
*/

test() {
  Expect.fail("Don't expect this to run at all");
}
main() {
  Expect.fail("Don't expect this to run at all");
}

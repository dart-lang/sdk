// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This is the original dart program that was used to generate the snapshot
// in file issue14236_test.dart
// The original test/main has been commented out and we have a test/main which
// throws an error to ensure that this file is not executed as part of the
// test.
//
// When issue14236_test.dart fails, you must regenerate it using the VM
// with your changes. You should understand what in your change makes
// regeneration of the snapshot necessary.
// Steps for regenerating:
// 1) Swap the test functions below.
// 2) $ ./xcodebuild/DebugIA32/dart --package-root=./xcodebuild/DebugIA32/packages --snapshot=tests/standalone/issue14236_test.dart tests/standalone/issue14236_source.dart
// OR:
// 2) $ ./out/DebugIA32/dart --package-root=./out/DebugIA32/packages --snapshot=tests/standalone/issue14236_test.dart tests/standalone/issue14236_source.dart
// 3) Undo changes in 1.

library test.issue14236;
import "dart:isolate";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";


/*
test(SendPort replyTo) {
  replyTo.send("from Isolate");
}
*/

test(dummy) {
  Expect.fail("Don't expect this to run at all");
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

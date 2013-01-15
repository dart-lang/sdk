// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that exceptions in other isolates bring down
// the program.
// TODO(7769): Remove this test when
// tests/isolate/isolate2_negative_test passes.

library isolate2_negative_test;
import 'dart:isolate';

void entry() {
  throw "foo";
}

main() {
  SendPort port = spawnFunction(entry);
  port.receive((msg) {});
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that exceptions in other isolates bring down
// the program.

library isolate2_negative_test;
import 'dart:isolate';
import "package:async_helper/async_helper.dart";

void entry(msg) {
  throw "foo";
}

main() {
  // We start an asynchronous operation, but since we don't expect to get
  // anything back except an exception there is no asyncEnd().
  // If the exception is not thrown this test will timeout.
  asyncStart();
  Isolate.spawn(entry);
}

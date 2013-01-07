// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_extension_test;

import "dart:async";
import "dart:isolate";
import "test_extension.dart";

main() {
  try {
    Cat.throwMeTheBall("ball");
  } on String catch (e) {
    Expect.equals("ball", e);
  }
  // Make sure the exception is thrown out to the event handler from C++ code.
  // The harness expects the string "ball" to be thrown and the process to
  // end with an unhandled exception.
  new Timer(0, (_) => Cat.throwMeTheBall("ball"));
}

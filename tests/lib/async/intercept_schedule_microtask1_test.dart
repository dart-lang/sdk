// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'catch_errors.dart';

main() {
  // Test that runZoned returns the result of executing the body.
  var result = runZonedScheduleMicrotask(() => 499, onScheduleMicrotask: (f) {
    Expect.fail("Unexpected invocation.");
  });
  Expect.equals(499, result);
}

// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong
// dart2jsOptions=-O3

import 'null_assertions_test_lib.dart';
import 'web_library_interfaces.dart';

void main() {
  // If the flag wasn't passed, we can optimize the check away.
  var flagEnabled = false;
  testNativeNullAssertions(flagEnabled);
  testJSInvocationNullAssertions(flagEnabled);
}

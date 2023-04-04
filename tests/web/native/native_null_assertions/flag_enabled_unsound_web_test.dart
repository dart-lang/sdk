// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak
// dart2jsOptions=--native-null-assertions

import 'null_assertions_test_lib.dart';
import 'web_library_interfaces.dart';

void main() {
  // To avoid a breaking change, we don't enable checks even if the user passes
  // the flag in unsound mode.
  var flagEnabled = false;
  testNativeNullAssertions(flagEnabled);
  testJSInvocationNullAssertions(flagEnabled);
}

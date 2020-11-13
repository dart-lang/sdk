// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong
// dart2jsOptions=--native-null-assertions

import 'null_assertions_test_lib.dart';
import 'web_library_interfaces.dart';

void main() {
  var flagEnabled = true;
  testNativeNullAssertions(flagEnabled);
  testJSInvocationNullAssertions(flagEnabled);
}

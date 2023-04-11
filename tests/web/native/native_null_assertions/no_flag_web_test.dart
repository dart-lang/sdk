// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong
// dart2jsOptions=-O1

import 'null_assertions_test_lib.dart';
import 'web_library_interfaces.dart';

void main() {
  // Strong mode should enable checks in the default optimization level if
  // neither the enable or disable flag is passed.
  var flagEnabled = true;
  testNativeNullAssertions(flagEnabled);
  testJSInvocationNullAssertions(flagEnabled);
}

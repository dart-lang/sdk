// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// negative test to ensure that unresolved_ports works.
library unresolved_ports_negative;
import 'dart:isolate';
import '../../pkg/unittest/lib/unittest.dart';
import 'unresolved_ports_test.dart' as positive_test;

main() {
  positive_test.baseTest(failForNegativeTest: true);
}

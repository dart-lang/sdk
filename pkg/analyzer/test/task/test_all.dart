// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.task;

import 'package:unittest/unittest.dart';

import 'task_dart_test.dart' as task_dart_test;

/// Utility for manually running all tests.
main() {
  groupSep = ' | ';
  group('generated tests', () {
    task_dart_test.main();
  });
}

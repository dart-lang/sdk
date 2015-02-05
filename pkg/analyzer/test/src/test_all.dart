// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src;

import 'package:unittest/unittest.dart';

import 'task/test_all.dart' as task;
import 'util/test_all.dart' as util;

/// Utility for manually running all tests.
main() {
  groupSep = ' | ';
  group('src tests', () {
    task.main();
    util.main();
  });
}

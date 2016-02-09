// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.test_all;

import 'package:unittest/unittest.dart';

import '../utils.dart';
import 'context/test_all.dart' as context;
import 'dart/test_all.dart' as dart;
import 'plugin/plugin_config_test.dart' as plugin;
import 'summary/test_all.dart' as summary;
import 'task/test_all.dart' as task;
import 'util/test_all.dart' as util;

/// Utility for manually running all tests.
main() {
  initializeTestEnvironment();
  group('src tests', () {
    context.main();
    dart.main();
    plugin.main();
    summary.main();
    task.main();
    util.main();
  });
}

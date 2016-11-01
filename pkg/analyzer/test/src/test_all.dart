// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.test_all;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'command_line/test_all.dart' as command_line;
import 'context/test_all.dart' as context;
import 'dart/test_all.dart' as dart;
import 'plugin/plugin_config_test.dart' as plugin;
import 'source/test_all.dart' as source;
import 'summary/test_all.dart' as summary;
import 'task/test_all.dart' as task;
import 'util/test_all.dart' as util;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    command_line.main();
    context.main();
    dart.main();
    plugin.main();
    source.main();
    summary.main();
    task.main();
    util.main();
  }, name: 'src');
}

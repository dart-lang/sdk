// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/io.dart';

import 'config_test.dart' as config_test;
import 'engine_test.dart' as engine_test;
import 'formatter_test.dart' as formatter_test;
import 'integration_test.dart' as integration_test;
import 'io_test.dart' as io_test;
import 'mocks.dart';
import 'plugin_test.dart' as plugin_test;
import 'project_test.dart' as project_test;
import 'pub_test.dart' as pub_test;
import 'rule_test.dart' as rule_test;

main() {
  // useCompactVMConfiguration();

  // Redirect output.
  outSink = new MockIOSink();

  config_test.main();
  engine_test.main();
  formatter_test.main();
  io_test.main();
  integration_test.main();
  plugin_test.main();
  project_test.main();
  pub_test.main();
  rule_test.main();
}

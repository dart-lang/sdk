// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/io.dart';
import 'package:unittest/unittest.dart';

import 'config_test.dart' as config_test;
import 'formatter_test.dart' as formatter_test;
import 'integration_test.dart' as integration_test;
import 'io_test.dart' as io_test;
import 'linter_test.dart' as linter_test;
import 'mocks.dart';
import 'pub_test.dart' as pub_test;

main() {
  // Tidy up the unittest output.
  filterStacks = true;
  formatStacks = true;
  // useCompactVMConfiguration();

  // Redirect output
  outSink = new MockIOSink();

  linter_test.main();
  pub_test.main();
  io_test.main();
  formatter_test.main();
  config_test.main();
  integration_test.main();
}

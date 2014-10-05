// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.engine;

import 'package:unittest/unittest.dart';

import 'error_test.dart' as error;
import 'file_system/test_all.dart' as file_system;
import 'generated/test_all.dart' as generated;
import 'options_test.dart' as options;
import 'parse_compilation_unit_test.dart' as parse_compilation_unit;
import 'source/test_all.dart' as source;


/// Utility for manually running all tests.
main() {
  groupSep = ' | ';
  group('analysis engine', () {
    error.main();
    file_system.main();
    generated.main();
    options.main();
    parse_compilation_unit.main();
    source.main();
  });
}
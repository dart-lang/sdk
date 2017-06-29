// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.dart.analysis.test_all;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_test.dart' as driver;
import 'file_state_test.dart' as file_state;
import 'index_test.dart' as index;
import 'referenced_names_test.dart' as referenced_names;
import 'search_test.dart' as search_test;
import 'session_test.dart' as session_test;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    driver.main();
    file_state.main();
    index.main();
    referenced_names.main();
    search_test.main();
    session_test.main();
  }, name: 'analysis');
}

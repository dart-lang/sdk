// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_builder_test.dart' as context_builder_test;
import 'context_locator_test.dart' as context_locator_test;
import 'context_root_test.dart' as context_root_test;
import 'defined_names_test.dart' as defined_names_test;
import 'driver_kernel_test.dart' as driver_kernel;
import 'driver_resolution_kernel_test.dart' as driver_resolution_kernel;
import 'driver_resolution_test.dart' as driver_resolution;
import 'driver_test.dart' as driver;
import 'file_state_test.dart' as file_state;
import 'index_test.dart' as index;
import 'mutex_test.dart' as mutex;
import 'referenced_names_test.dart' as referenced_names;
import 'search_test.dart' as search_test;
import 'session_helper_test.dart' as session_helper_test;
import 'session_test.dart' as session_test;

main() {
  defineReflectiveSuite(() {
    context_builder_test.main();
    context_locator_test.main();
    context_root_test.main();
    defined_names_test.main();
    driver.main();
    driver_kernel.main();
    driver_resolution.main();
    driver_resolution_kernel.main();
    file_state.main();
    index.main();
    mutex.main();
    referenced_names.main();
    search_test.main();
    session_helper_test.main();
    session_test.main();
  }, name: 'analysis');
}

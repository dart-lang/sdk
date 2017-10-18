// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.task.test_all;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'dart_test.dart' as dart_test;
import 'dart_work_manager_test.dart' as dart_work_manager_test;
import 'driver_test.dart' as driver_test;
import 'general_test.dart' as general_test;
import 'html_test.dart' as html_test;
import 'html_work_manager_test.dart' as html_work_manager_test;
import 'inputs_test.dart' as inputs_test;
import 'manager_test.dart' as manager_test;
import 'model_test.dart' as model_test;
import 'options_test.dart' as options_test;
import 'options_work_manager_test.dart' as options_work_manager_test;
import 'strong/test_all.dart' as strong_mode_test_all;
import 'strong_mode_driver_test.dart' as strong_mode_driver_test;
import 'strong_mode_test.dart' as strong_mode_test;
import 'yaml_test.dart' as yaml_test;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    dart_test.main();
    dart_work_manager_test.main();
    driver_test.main();
    general_test.main();
    html_test.main();
    html_work_manager_test.main();
    inputs_test.main();
    manager_test.main();
    model_test.main();
    options_test.main();
    options_work_manager_test.main();
    strong_mode_test_all.main();
    strong_mode_driver_test.main();
    strong_mode_test.main();
    yaml_test.main();
  }, name: 'task');
}

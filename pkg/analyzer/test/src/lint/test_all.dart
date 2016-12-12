// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'config_test.dart' as config_test;
import 'io_test.dart' as io_test;
import 'project_test.dart' as project_test;
import 'pub_test.dart' as pub_test;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    config_test.main();
    io_test.main();
    project_test.main();
    pub_test.main();
  }, name: 'lint');
}

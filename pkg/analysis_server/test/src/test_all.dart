// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'computer/test_all.dart' as computer_all;
import 'domain_abstract_test.dart' as domain_abstract_test;
import 'plugin/test_all.dart' as plugin_all;
import 'utilities/test_all.dart' as utilities_all;
import 'watch_manager_test.dart' as watch_manager_test;

/**
 * Utility for manually running all tests.
 */
main() {
  defineReflectiveSuite(() {
    computer_all.main();
    domain_abstract_test.main();
    plugin_all.main();
    utilities_all.main();
    watch_manager_test.main();
  }, name: 'src');
}

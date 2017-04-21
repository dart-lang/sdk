// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'plugin/test_all.dart' as plugin_all;
import 'utilities/test_all.dart' as utilities_all;

/**
 * Utility for manually running all tests.
 */
main() {
  defineReflectiveSuite(() {
    plugin_all.main();
    utilities_all.main();
  }, name: 'analysis_server');
}

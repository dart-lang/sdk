// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src;

import 'package:unittest/unittest.dart';

import 'sdk_ext_test.dart' as sdk_ext_test;
import 'utilities/test_all.dart' as utilities_all;

/**
 * Utility for manually running all tests.
 */
main() {
  groupSep = ' | ';
  group('analysis_server', () {
    sdk_ext_test.main();
    utilities_all.main();
  });
}

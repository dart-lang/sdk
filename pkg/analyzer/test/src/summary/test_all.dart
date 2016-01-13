// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.serialization.test_all;

import 'package:unittest/unittest.dart';

import '../../utils.dart';
import 'flat_buffers_test.dart' as flat_buffers_test;
import 'name_filter_test.dart' as name_filter_test;
import 'resynthesize_test.dart' as resynthesize_test;
import 'summary_sdk_test.dart' as summary_sdk_test;
import 'summary_test.dart' as summary_test;

/// Utility for manually running all tests.
main() {
  initializeTestEnvironment();
  group('summary tests', () {
    flat_buffers_test.main();
    name_filter_test.main();
    resynthesize_test.main();
    summary_sdk_test.main();
    summary_test.main();
  });
}

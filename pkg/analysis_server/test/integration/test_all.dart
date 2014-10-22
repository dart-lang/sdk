// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.all;

import 'package:unittest/unittest.dart';

import 'analysis/test_all.dart' as analysis_test_all;
import 'asynchrony_test.dart' as asynchrony_test;
import 'completion/test_all.dart' as completion_test_all;
import 'search/test_all.dart' as search_test_all;
import 'server/test_all.dart' as server_test_all;

// Disable asynchrony test for now.
// TODO(paulberry): re-enable when issue 21252 is fixed.
const bool _ENABLE_ASYNCHRONY_TEST = false;

/**
 * Utility for manually running all integration tests.
 */
main() {
  groupSep = ' | ';
  group('analysis_server_integration', () {
    analysis_test_all.main();
    if (_ENABLE_ASYNCHRONY_TEST) {
      asynchrony_test.main();
    }
    completion_test_all.main();
    search_test_all.main();
    server_test_all.main();
  });
}

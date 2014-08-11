// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.all;

import 'package:unittest/unittest.dart';

import 'analysis/test_all.dart' as analysis_test_all;
import 'completion/test_all.dart' as completion_test_all;
import 'search/test_all.dart' as search_test_all;
import 'server/test_all.dart' as server_test_all;

/**
 * Utility for manually running all integration tests.
 */
main() {
  groupSep = ' | ';
  group('analysis_server_integration', () {
    analysis_test_all.main();
    completion_test_all.main();
    search_test_all.main();
    server_test_all.main();
  });
}

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis/test_all.dart' as analysis_test_all;
import 'analytics/test_all.dart' as analytics_test_all;
import 'completion/test_all.dart' as completion_test_all;
import 'coverage_test.dart' as coverage_test;
import 'diagnostic/test_all.dart' as diagnostic_test_all;
import 'edit/test_all.dart' as edit_test_all;
import 'execution/test_all.dart' as execution_test_all;
import 'kythe/test_all.dart' as kythe_test_all;
import 'search/test_all.dart' as search_test_all;
import 'server/test_all.dart' as server_test_all;

/**
 * Utility for manually running all integration tests.
 */
main() {
  defineReflectiveSuite(() {
    analysis_test_all.main();
    analytics_test_all.main();
    completion_test_all.main();
    diagnostic_test_all.main();
    edit_test_all.main();
    execution_test_all.main();
    kythe_test_all.main();
    search_test_all.main();
    server_test_all.main();

    coverage_test.main();
  }, name: 'analysis_server_integration');
}

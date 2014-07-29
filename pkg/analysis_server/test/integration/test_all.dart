// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';

import 'analysis_domain_int_test.dart' as analysis_domain_int_test;
import 'analysis_error_int_test.dart' as analysis_error_int_test;
import 'completion_domain_int_test.dart' as completion_domain_int_test;
import 'server_domain_int_test.dart' as server_domain_int_test;

/**
 * Utility for manually running all integration tests.
 */
main() {
  groupSep = ' | ';
  group('analysis_server_integration', () {
    analysis_domain_int_test.main();
    analysis_error_int_test.main();
    completion_domain_int_test.main();
    server_domain_int_test.main();
  });
}

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';

import 'analysis_error_inttest.dart' as analysis_error_inttest;
import 'server_domain_inttest.dart' as server_domain_inttest;

/**
 * Utility for manually running all integration tests.
 */
main() {
  groupSep = ' | ';
  group('analysis_server_integration', () {
    analysis_error_inttest.main();
    server_domain_inttest.main();
  });
}

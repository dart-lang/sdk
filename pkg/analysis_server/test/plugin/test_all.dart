// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library test.plugin.analysis_contributor;

import 'package:unittest/unittest.dart';

import '../utils.dart';
import 'protocol_dart_test.dart' as protocol_dart_test;
import 'set_analysis_domain_test.dart' as set_analysis_domain_test;

/**
 * Utility for manually running all tests.
 */
main() {
  initializeTestEnvironment();
  group('plugin', () {
    protocol_dart_test.main();
    set_analysis_domain_test.main();
  });
}

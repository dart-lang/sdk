// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.completion.all;

import 'package:unittest/unittest.dart';

import 'get_suggestions_test.dart' as get_suggestions_test;

/**
 * Utility for manually running all integration tests.
 */
main() {
  groupSep = ' | ';
  group('completion', () {
    get_suggestions_test.main();
  });
}

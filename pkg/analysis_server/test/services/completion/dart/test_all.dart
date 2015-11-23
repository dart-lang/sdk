// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart;

import 'package:unittest/unittest.dart';
import 'inherited_contributor_test.dart' as inherited_contributor_test;

import '../../../utils.dart';

/// Utility for manually running all tests.
main() {
  initializeTestEnvironment();
  group('dart/completion', () {
    inherited_contributor_test.main();
  });
}

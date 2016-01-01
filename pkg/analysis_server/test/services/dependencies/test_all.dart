// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.dependencies;

import 'package:unittest/unittest.dart';

import '../../utils.dart';
import 'library_dependencies_test.dart' as library_dependencies;
import 'reachable_source_collector_test.dart' as reachable_source_collector;

/// Utility for manually running all tests.
main() {
  initializeTestEnvironment();
  group('dependencies', () {
    library_dependencies.main();
    reachable_source_collector.main();
  });
}

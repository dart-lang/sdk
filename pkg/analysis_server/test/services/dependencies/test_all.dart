// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'library_dependencies_test.dart' as library_dependencies;
import 'reachable_source_collector_test.dart' as reachable_source_collector;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    library_dependencies.main();
    reachable_source_collector.main();
  }, name: 'dependencies');
}

// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'package_map_resolver_test.dart' as package_map_resolver;
import 'path_filter_test.dart' as path_filter;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    package_map_resolver.main();
    path_filter.main();
  }, name: 'source');
}

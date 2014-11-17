// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.source;

import 'package:unittest/unittest.dart';

import 'package_map_provider_test.dart' as package_map_provider_test;
import 'package_map_resolver_test.dart' as package_map_resolver_test;


/// Utility for manually running all tests.
main() {
  groupSep = ' | ';
  group('source', () {
    package_map_provider_test.main();
    package_map_resolver_test.main();
  });
}

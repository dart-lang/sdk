// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.source;

import 'caching_put_package_map_provider_test.dart' as caching_provider_test;
import 'optimizing_pub_package_map_provider_test.dart'
    as optimizing_provider_test;
import 'package:unittest/unittest.dart';

/// Utility for manually running all tests.
main() {
  groupSep = ' | ';
  caching_provider_test.main();
  optimizing_provider_test.main();
}

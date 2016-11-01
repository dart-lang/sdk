// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.file_system.test_all;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'memory_file_system_test.dart' as memory_file_system_test;
import 'physical_resource_provider_test.dart'
    as physical_resource_provider_test;
import 'resource_uri_resolver_test.dart' as resource_uri_resolver_test;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    memory_file_system_test.main();
    physical_resource_provider_test.main();
    resource_uri_resolver_test.main();
  }, name: 'file system');
}

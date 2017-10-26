// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'byte_store_test.dart' as byte_store_test;
import 'cache_test.dart' as cache_test;
import 'protected_file_byte_store_test.dart' as protected_file_byte_store_test;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    byte_store_test.main();
    cache_test.main();
    protected_file_byte_store_test.main();
  }, name: 'byte_store');
}

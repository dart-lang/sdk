// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'byte_store_test.dart' as byte_store;
import 'file_state_test.dart' as file_state;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    byte_store.main();
    file_state.main();
  }, name: 'incremental');
}

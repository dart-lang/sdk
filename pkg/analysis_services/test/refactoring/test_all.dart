// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring;

import 'package:unittest/unittest.dart';

import 'rename_local_test.dart' as rename_local_test;

/// Utility for manually running all tests.
main() {
  groupSep = ' | ';
  group('refactoring', () {
    rename_local_test.main();
  });
}
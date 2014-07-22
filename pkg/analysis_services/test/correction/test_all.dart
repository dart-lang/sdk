// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.correction;

import 'package:unittest/unittest.dart';

import 'change_test.dart' as change_test;
import 'fix_test.dart' as fix_test;

/// Utility for manually running all tests.
main() {
  groupSep = ' | ';
  group('correction', () {
    change_test.main();
    fix_test.main();
  });
}
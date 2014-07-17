// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.correction;

import 'package:unittest/unittest.dart';

import 'fix_test.dart' as fix_processor_test;

/// Utility for manually running all tests.
main() {
  groupSep = ' | ';
  group('correction', () {
    fix_processor_test.main();
  });
}
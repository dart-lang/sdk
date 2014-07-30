// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion;

import 'package:unittest/unittest.dart';

import 'top_level_computer_test.dart' as toplevel_test;

/// Utility for manually running all tests.
main() {
  groupSep = ' | ';
  group('completion', () {
    toplevel_test.main();
  });
}
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';

import '../../utils.dart';
import 'index2.dart' as index;

/**
 * Utility for manually running all tests.
 */
main() {
  initializeTestEnvironment();
  group('index', () {
    index.main();
  });
}

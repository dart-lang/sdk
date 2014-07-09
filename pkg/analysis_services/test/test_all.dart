// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';

import 'index/test_all.dart' as index_all;

/// Utility for manually running all tests.
main() {
  groupSep = ' | ';
  index_all.main();
}
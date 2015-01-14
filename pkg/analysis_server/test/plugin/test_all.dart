// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.plugin.all;

import 'package:unittest/unittest.dart';

import 'plugin_impl_test.dart' as plugin_impl;

/**
 * Utility for manually running all tests.
 */
main() {
  groupSep = ' | ';
  group('plugins', () {
    plugin_impl.main();
  });
}

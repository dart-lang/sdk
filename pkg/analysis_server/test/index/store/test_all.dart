// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.index.store;

import 'package:unittest/unittest.dart';

import 'codec_test.dart' as codec_test;
import 'collection_test.dart' as collection_test;
import 'split_store_test.dart' as split_store_test;


/**
 * Utility for manually running all tests.
 */
main() {
  groupSep = ' | ';
  group('store', () {
    codec_test.main();
    collection_test.main();
    split_store_test.main();
  });
}

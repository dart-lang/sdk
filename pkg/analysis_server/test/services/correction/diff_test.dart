// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.correction.diff;

import 'package:analysis_server/src/services/correction/diff.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(DiffTest);
}

@ReflectiveTestCase()
class DiffTest {
  void test_findCommonPrefix() {
    expect(findCommonPrefix('abc', 'xyz'), 0);
    expect(findCommonPrefix('1234abcdef', '1234xyz'), 4);
    expect(findCommonPrefix('123', '123xyz'), 3);
  }

  void test_findCommonSuffix() {
    expect(findCommonSuffix('abc', 'xyz'), 0);
    expect(findCommonSuffix('abcdef1234', 'xyz1234'), 4);
    expect(findCommonSuffix('123', 'xyz123'), 3);
  }
}
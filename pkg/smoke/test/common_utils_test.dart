// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library smoke.test.common_utils;

import 'package:smoke/src/common.dart';
import 'package:unittest/unittest.dart';

main() {
  test('adjustList', () {
    expect(adjustList([1, 2, 3], 1, 2), [1, 2]);
    expect(adjustList([1, 2, 3], 1, 3), [1, 2, 3]);
    expect(adjustList([1, 2, 3], 1, 4), [1, 2, 3]);
    expect(adjustList([1, 2, 3], 4, 4), [1, 2, 3, null]);
    expect(adjustList([], 1, 4), [null]);
  });

  test('compareLists ordered', () {
    expect(compareLists([1, 1, 1], [1, 2, 3]), isFalse);
    expect(compareLists([2, 3, 1], [1, 2, 3]), isFalse);
    expect(compareLists([1, 2, 3], [1, 2, 3]), isTrue);
  });

  test('compareLists unordered', () {
    expect(compareLists([1, 1, 1], [1, 2, 3], unordered: true), isFalse);
    expect(compareLists([2, 3, 1], [1, 2, 3], unordered: true), isTrue);
    expect(compareLists([1, 1, 2, 3, 4, 2], [2, 2, 1, 1, 3, 4],
        unordered: true), isTrue);
    expect(compareLists([1, 4, 2, 3, 1, 2], [2, 2, 1, 1, 3, 4],
        unordered: true), isTrue);
    expect(compareLists([1, 1, 2, 3, 4, 1], [2, 2, 1, 1, 3, 4],
        unordered: true), isFalse);
  });
}

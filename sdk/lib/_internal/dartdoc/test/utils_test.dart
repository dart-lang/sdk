// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';

import '../lib/src/dartdoc/utils.dart';

void main() {
  group('countOccurrences', () {
    test('empty text returns 0', () {
      expect(countOccurrences('', 'needle'), equals(0));
    });

    test('one occurrence', () {
      expect(countOccurrences('bananarama', 'nara'), equals(1));
    });

    test('multiple occurrences', () {
      expect(countOccurrences('bananarama', 'a'), equals(5));
    });

    test('overlapping matches do not count', () {
      expect(countOccurrences('bananarama', 'ana'), equals(1));
    });
  });

  group('repeat', () {
    test('zero times returns an empty string', () {
      expect(repeat('ba', 0), isEmpty);
    });

    test('one time returns the string', () {
      expect(repeat('ba', 1), equals('ba'));
    });

    test('multiple times', () {
      expect(repeat('ba', 3), equals('bababa'));
    });

    test('multiple times with a separator', () {
      expect(repeat('ba', 3, separator: ' '), equals('ba ba ba'));
    });
  });
}

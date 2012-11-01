/**
 * Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

library number_format_test;

import '../../../pkg/unittest/unittest.dart';
import '../lib/number_format.dart';
import '../lib/intl.dart';

/**
 * Tests the Numeric formatting library in dart.
 */
var testNumbers = const {
  "0.001":  0.001,
  "0.01": 0.01,
  "0.1": 0.1,
  "1": 1,
  "2": 2.0,
  "10": 10,
  "100": 100,
  "1,000": 1000,
  "2,000,000,000,000": 2000000000000,
  "10,000,000,000,000,000,000,000,000,000,000":
      10000000000000000000000000000000,
  "0.123": 0.123,
  "1,234": 1234.0,
  "1.234": 1.234,
  "1.23": 1.230,
  "NaN": 0/0,
  "∞": 1/0,
  "-∞": -1/0};

main() {
  test('Basic number printing', () {
    var number = new NumberFormat();
    expect(number.format(3.14),"3.14");
  });

  test('Simple set of numbers', () {
    var number = new NumberFormat();
    for (var x in testNumbers.keys) {
      var formatted = number.format(testNumbers[x]);
      expect(formatted, x);
    }
  });
}
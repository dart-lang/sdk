// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/extensions/numeric.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NumericTest);
  });
}

@reflectiveTest
class NumericTest {
  Future<void> test_asStringWithSuffix() async {
    var expectedResults = {
      1: '1st',
      2: '2nd',
      3: '3rd',
      4: '4th',
      5: '5th',
      6: '6th',
      7: '7th',
      8: '8th',
      9: '9th',
      10: '10th',
      11: '11th',
      12: '12th',
      13: '13th',
      14: '14th',
      15: '15th',
      20: '20th',
      21: '21st',
      22: '22nd',
      23: '23rd',
      24: '24th',
      88: '88th',
      100: '100th',
      101: '101st',
      111: '111th',
      121: '121st',
    };

    for (var MapEntry(:key, :value) in expectedResults.entries) {
      expect(key.toStringWithSuffix(), value);
    }
  }
}

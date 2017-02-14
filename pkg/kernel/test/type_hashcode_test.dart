// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:kernel/kernel.dart';
import 'type_parser.dart';
import 'type_unification_test.dart' show testCases;
import 'package:test/test.dart';

void checkHashCodeEquality(DartType type1, DartType type2) {
  if (type1 == type2 && type1.hashCode != type2.hashCode) {
    fail('Equal types with different hash codes: $type1 and $type2');
  }
}

const int MinimumSmi = -(1 << 30);
const int MaximumSmi = (1 << 30) - 1;

bool isSmallInteger(int hash) {
  return MinimumSmi <= hash && hash <= MaximumSmi;
}

void checkHashCodeRange(DartType type) {
  int hash = type.hashCode;
  if (!isSmallInteger(hash)) {
    fail('Hash code for $type is not a SMI: $hash');
  }
}

void main() {
  for (var testCase in testCases) {
    test('$testCase', () {
      var env = new LazyTypeEnvironment();
      var type1 = env.parse(testCase.type1);
      var type2 = env.parse(testCase.type2);
      checkHashCodeEquality(type1, type2);
      checkHashCodeRange(type1);
      checkHashCodeRange(type2);
    });
  }
}

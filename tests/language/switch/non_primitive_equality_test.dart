// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// With Dart 3.0, switch cases are patterns and constants in cases are no
// longer required to have primitive equality.

import "package:expect/expect.dart";

class ValueType {
  static String test(int value) {
    switch (ValueType(value)) {
      case const ValueType(1):
        return 'one';
      case const ValueType(2):
        return 'two';
      default:
        return 'other';
    }
  }

  final int value;

  const ValueType(this.value);

  bool operator ==(Object other) => other is ValueType && value == other.value;
}

class EquatableToString {
  static String test(String value) {
    switch (value) {
      case const EquatableToString('ape'):
        return 'primate';
      case const EquatableToString('bat'):
        return 'chiroptera';
      default:
        return 'other';
    }
  }

  final String value;

  const EquatableToString(this.value);

  bool operator ==(Object other) => other is String && value == other;
}

String testDouble(double value) {
  switch (value) {
    case 0.0:
      return 'nothing';
    case 1.1:
      return 'one-ish';
    case 2.2:
      return 'two-ish';
    default:
      return 'other';
  }
}

main() {
  Expect.equals('one', ValueType.test(1));
  Expect.equals('two', ValueType.test(2));
  Expect.equals('other', ValueType.test(3));

  Expect.equals('primate', EquatableToString.test('ape'));
  Expect.equals('chiroptera', EquatableToString.test('bat'));
  Expect.equals('other', EquatableToString.test('cat'));

  Expect.equals('nothing', testDouble(0.0));
  Expect.equals('nothing', testDouble(-0.0));
  Expect.equals('one-ish', testDouble(1.1));
  Expect.equals('two-ish', testDouble(2.2));
  Expect.equals('other', testDouble(3.3));
}

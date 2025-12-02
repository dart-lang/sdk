// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/utils/misc.dart';
import 'package:test/test.dart';

class A {
  final int i;
  const A(this.i);

  @override
  bool operator ==(Object o) => o is A && o.i == i;

  @override
  int get hashCode => i;
}

void main() {
  test('listEquals and listHashCode', () {
    void eq(List a, List b) {
      expect(listEquals(a, b), isTrue);
      expect(listHashCode(a), equals(listHashCode(b)));
    }

    void ne(List a, List b) {
      expect(listEquals(a, b), isFalse);
      // Generally it would be incorrect to assume
      // hash codes of non-equal objects are different.
      // However, for the test cases below it should hold.
      expect(listHashCode(a), isNot(equals(listHashCode(b))));
    }

    eq([], []);
    eq(<Object>[], <String>[]);
    ne([A(1)], []);
    ne([], [A(2)]);
    eq([A(1)], const [A(1)]);
    ne([A(1), A(1)], [A(1)]);
    eq([A(1), A(2), A(3)], [A(1), A(2), A(3)]);
    ne([A(1), A(2), A(3)], [A(4), A(2), A(3)]);
    ne([A(1), A(2), A(3)], [A(1), A(4), A(3)]);
    ne([A(1), A(2), A(3)], [A(1), A(2), A(4)]);
  });

  test('isPowerOf2 and log2OfPowerOf2', () {
    expect(isPowerOf2(0), isFalse);
    expect(isPowerOf2(-1), isFalse);
    expect(isPowerOf2(0x20001), isFalse);
    expect(isPowerOf2(0x80000000_40000000), isFalse);

    for (var i = 0; i < 64; ++i) {
      expect(isPowerOf2(1 << i), isTrue);
      expect(log2OfPowerOf2(1 << i), equals(i));

      if (i >= 2) {
        expect(isPowerOf2((1 << i) - 1), isFalse);
        expect(isPowerOf2((1 << i) + 1), isFalse);
      }
    }
  });

  test('roundDown and roundUp', () {
    for (var i = 0; i < 20; ++i) {
      expect(roundDown(i, 1), equals(i));
      expect(roundUp(i, 1), equals(i));
    }

    for (var align = 2; align <= 1024; align <<= 1) {
      for (var k = 0; k < 20; ++k) {
        expect(roundDown(k * align, align), equals(k * align));
        expect(roundDown(k * align + 1, align), equals(k * align));
        expect(roundDown(k * align + align - 1, align), equals(k * align));

        expect(roundUp(k * align, align), equals(k * align));
        expect(roundUp(k * align + 1, align), equals((k + 1) * align));
        expect(roundUp(k * align + align - 1, align), equals((k + 1) * align));
      }
    }
  });
}

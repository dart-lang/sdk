// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/utils/bit_vector.dart';
import 'package:test/test.dart';

void main() {
  test('size 0', () {
    final bv1 = BitVector(0);
    final bv2 = BitVector(0);
    final bv3 = BitVector(0);
    expect(bv1.elements, isEmpty);

    bv1.intersect(bv2);
    expect(bv1.elements, isEmpty);

    expect(bv1.addAll(bv2), isFalse);
    expect(bv1.elements, isEmpty);

    expect(bv1.addSubtraction(bv2, bv3), isFalse);
    expect(bv1.elements, isEmpty);

    expect(bv1.addIntersection(bv2, bv3), isFalse);
    expect(bv1.elements, isEmpty);
  });

  test('indexing add remove', () {
    for (int n in [20, 63, 64, 65, 200, 2000]) {
      final mid = n ~/ 2;
      final bv = BitVector(n);

      expect(bv[0], isFalse);
      expect(bv[mid], isFalse);
      expect(bv[n - 1], isFalse);

      bv.add(0);
      bv.add(mid);
      bv.add(n - 1);
      expect(bv[0], isTrue);
      expect(bv[1], isFalse);
      expect(bv[mid - 1], isFalse);
      expect(bv[mid], isTrue);
      expect(bv[n - 2], isFalse);
      expect(bv[n - 1], isTrue);
      expect(bv.elements.toList(), equals([0, mid, n - 1]));

      bv.remove(0);
      bv.remove(1);
      bv.remove(n - 1);
      expect(bv[0], isFalse);
      expect(bv[1], isFalse);
      expect(bv[mid - 1], isFalse);
      expect(bv[mid], isTrue);
      expect(bv[n - 2], isFalse);
      expect(bv[n - 1], isFalse);
      expect(bv.elements.toList(), equals([mid]));

      bv[0] = true;
      bv[1] = false;
      bv[mid - 1] = true;
      bv[n - 2] = true;
      expect(bv[0], isTrue);
      expect(bv[1], isFalse);
      expect(bv[mid - 1], isTrue);
      expect(bv[mid], isTrue);
      expect(bv[n - 2], isTrue);
      expect(bv[n - 1], isFalse);
      expect(bv.elements.toList(), equals([0, mid - 1, mid, n - 2]));
    }
  });

  test('bulk operations', () {
    for (int n in [20, 63, 64, 65, 200, 2000]) {
      final bv1 = BitVector(n);
      final bv2 = BitVector(n);
      final bv3 = BitVector(n);

      for (int i = 0; i < n; i += 3) {
        bv2[i] = true;
      }
      for (int i = 0; i < n; i += 5) {
        bv3[i] = true;
      }

      expect(bv1.addAll(bv2), isTrue);
      expect(bv1.addAll(bv2), isFalse);
      bv1.intersect(bv3);
      for (int i = 0; i < n; ++i) {
        expect(bv1[i], equals(i % 15 == 0));
        expect(bv2[i], equals(i % 3 == 0));
        expect(bv3[i], equals(i % 5 == 0));
      }

      expect(bv2.addAll(bv1), isFalse);
      expect(bv3.addAll(bv1), isFalse);
      for (int i = 0; i < n; ++i) {
        expect(bv1[i], equals(i % 15 == 0));
        expect(bv2[i], equals(i % 3 == 0));
        expect(bv3[i], equals(i % 5 == 0));
      }

      expect(bv2.addSubtraction(bv3, bv1), isTrue);
      for (int i = 0; i < n; ++i) {
        expect(bv1[i], equals(i % 15 == 0));
        expect(bv2[i], equals(i % 3 == 0 || i % 5 == 0));
        expect(bv3[i], equals(i % 5 == 0));
      }
      expect(bv3.addSubtraction(bv1, bv2), isFalse);

      expect(bv3.addIntersection(bv1, bv2), isFalse);
      expect(bv1.addIntersection(bv2, bv3), isTrue);
      for (int i = 0; i < n; ++i) {
        expect(bv1[i], equals(i % 5 == 0));
        expect(bv2[i], equals(i % 3 == 0 || i % 5 == 0));
        expect(bv3[i], equals(i % 5 == 0));
      }

      bv3.clear();
      for (int i = 0; i < n; ++i) {
        expect(bv3[i], isFalse);
      }

      int k = 0;
      for (int bit in bv1.elements) {
        expect(bit, equals(k * 5));
        ++k;
      }
      expect(k, equals(1 + (n - 1) ~/ 5));
    }
  });
}

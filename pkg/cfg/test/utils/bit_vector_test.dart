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
    for (var n in [20, 63, 64, 65, 200, 2000]) {
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
    for (var n in [20, 63, 64, 65, 200, 2000]) {
      final bv1 = BitVector(n);
      final bv2 = BitVector(n);
      final bv3 = BitVector(n);

      for (var i = 0; i < n; i += 3) {
        bv2[i] = true;
      }
      for (var i = 0; i < n; i += 5) {
        bv3[i] = true;
      }

      expect(bv1.addAll(bv2), isTrue);
      expect(bv1.addAll(bv2), isFalse);
      bv1.intersect(bv3);
      for (var i = 0; i < n; ++i) {
        expect(bv1[i], equals(i % 15 == 0));
        expect(bv2[i], equals(i % 3 == 0));
        expect(bv3[i], equals(i % 5 == 0));
      }

      expect(bv2.addAll(bv1), isFalse);
      expect(bv3.addAll(bv1), isFalse);
      for (var i = 0; i < n; ++i) {
        expect(bv1[i], equals(i % 15 == 0));
        expect(bv2[i], equals(i % 3 == 0));
        expect(bv3[i], equals(i % 5 == 0));
      }

      expect(bv2.addSubtraction(bv3, bv1), isTrue);
      for (var i = 0; i < n; ++i) {
        expect(bv1[i], equals(i % 15 == 0));
        expect(bv2[i], equals(i % 3 == 0 || i % 5 == 0));
        expect(bv3[i], equals(i % 5 == 0));
      }
      expect(bv3.addSubtraction(bv1, bv2), isFalse);

      expect(bv3.addIntersection(bv1, bv2), isFalse);
      expect(bv1.addIntersection(bv2, bv3), isTrue);
      for (var i = 0; i < n; ++i) {
        expect(bv1[i], equals(i % 5 == 0));
        expect(bv2[i], equals(i % 3 == 0 || i % 5 == 0));
        expect(bv3[i], equals(i % 5 == 0));
      }

      bv3.clear();
      for (var i = 0; i < n; ++i) {
        expect(bv3[i], isFalse);
      }

      var k = 0;
      for (int bit in bv1.elements) {
        expect(bit, equals(k * 5));
        ++k;
      }
      expect(k, equals(1 + (n - 1) ~/ 5));
    }
  });

  test('expand', () {
    for (final initialSize in [0, 20, 63, 64, 65, 120]) {
      final bv = BitVector(initialSize);
      final initialCapacity = bv.capacity;

      for (var i = 0; i < initialCapacity; ++i) {
        if (i % 3 == 0) {
          bv[i] = true;
        }
      }

      final expanded = bv.expand(initialCapacity + 100);
      expect(expanded.capacity, greaterThanOrEqualTo(initialCapacity + 100));

      // Existing bits should be preserved.
      for (var i = 0; i < initialCapacity; ++i) {
        expect(expanded[i], equals(i % 3 == 0));
      }

      // Newly added capacity should be initialized to zero/false.
      for (var i = initialCapacity; i < expanded.capacity; ++i) {
        expect(expanded[i], isFalse);
      }
    }
  });

  test('setRange', () {
    void fillPattern(BitVector bv, int seed) {
      for (var i = 0; i < bv.capacity; ++i) {
        bv[i] = ((i * 17 + seed) & 3) == 0;
      }
    }

    void referenceSetRange(
      BitVector dst,
      int start,
      int end,
      BitVector src, [
      int skipCount = 0,
    ]) {
      for (var k = 0; k < end - start; ++k) {
        dst[start + k] = src[skipCount + k];
      }
    }

    void checkSetRange(
      int dstSize,
      int srcSize,
      int start,
      int end,
      int skipCount,
    ) {
      final actual = BitVector(dstSize);
      final expected = BitVector(dstSize);
      final src = BitVector(srcSize);

      fillPattern(actual, 1);
      fillPattern(expected, 1);
      fillPattern(src, 5);

      actual.setRange(start, end, src, skipCount);
      referenceSetRange(expected, start, end, src, skipCount);

      for (var i = 0; i < actual.capacity; ++i) {
        expect(
          actual[i],
          equals(expected[i]),
          reason:
              'Mismatch at bit $i for setRange(start=$start, end=$end, '
              'skipCount=$skipCount, dstCapacity=${actual.capacity}, '
              'srcCapacity=${src.capacity})',
        );
      }
    }

    // Empty range.
    checkSetRange(100, 100, 10, 10, 5);

    // Within a single 64-bit word.
    checkSetRange(100, 100, 5, 35, 10);
    checkSetRange(100, 100, 0, 60, 2);

    // Spanning across a word boundary without whole inner words.
    checkSetRange(128, 128, 50, 75, 10);
    checkSetRange(128, 128, 60, 68, 0);

    // Word-aligned start and end (shiftLo == 0).
    checkSetRange(256, 256, 0, 64, 0);
    checkSetRange(256, 256, 64, 192, 64);
    checkSetRange(256, 256, 64, 192, 0);

    // Aligned relative skipCount ((start & 63) == (skipCount & 63)) -> shiftLo == 0.
    checkSetRange(300, 300, 10, 202, 74);

    // Unaligned relative skipCount -> shiftLo != 0.
    checkSetRange(300, 300, 10, 202, 15);
    checkSetRange(300, 300, 0, 150, 33);
    checkSetRange(300, 300, 63, 195, 1);

    // Exhaustive small/medium range combinations across word boundaries.
    for (final start in [0, 1, 31, 63, 64, 65, 100]) {
      for (final length in [0, 1, 30, 63, 64, 65, 127, 128, 130]) {
        for (final skipCount in [0, 1, 33, 63, 64, 65]) {
          final end = start + length;
          final dstSize = end + 70;
          final srcSize = skipCount + length + 70;
          checkSetRange(dstSize, srcSize, start, end, skipCount);
        }
      }
    }
  });
}

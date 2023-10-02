// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing Bigints with and without intrinsics.
// VMOptions=--intrinsify --no-enable-asserts
// VMOptions=--intrinsify --enable-asserts
// VMOptions=--no-intrinsify --enable-asserts
// VMOptions=--no-intrinsify --no-enable-asserts
// VMOptions=--runtime_allocate_old
// VMOptions=--runtime_allocate_spill_tlab

import "package:expect/expect.dart";

const debugPrint = bool.fromEnvironment('debugPrint');

void check(int length, BigInt base) {
  assert(length >= 5);
  assert(base > BigInt.zero);

  // Check with slight adjustments. We choose -3..+3 so that the lowest bit in
  // the 2's-complement representation is both zero and one for both the
  // positive [n] and its negative complement [m] below.
  for (int delta = -3; delta <= 3; delta++) {
    BigInt n = base + BigInt.from(delta);
    assert(n >= BigInt.zero);

    // Compute the bitLength by shifting the value into a small integer range
    // and adjust the `int.bitLength` value by the shift count.
    int shiftCount = length - 5;
    int shiftedN = (n >> shiftCount).toInt();
    int expectedLength = shiftCount + shiftedN.bitLength;

    int nLength = n.bitLength;
    Expect.equals(expectedLength, nLength);

    // Use identity `x.bitLength == (-x-1).bitLength` to check negative values.
    BigInt m = -n - BigInt.one;
    int mLength = m.bitLength;

    if (debugPrint) {
      final printLength = length + 4;
      final nDigits =
          n.toUnsigned(printLength).toRadixString(2).padLeft(printLength);
      final mDigits = m.toUnsigned(printLength).toRadixString(2);
      print('$nDigits: $nLength');
      print('$mDigits: $mLength');
    }

    Expect.equals(nLength, mLength);
  }
}

void main() {
  // For small values, [BigInt.bitLength] should be the same as [int.bitLength].
  for (int i = 0; i <= 64; i++) {
    Expect.equals(i.bitLength, BigInt.from(i).bitLength);
    // Note: This is not quite redundant for `i==0` since on the web platform
    // `-i` is negative zero and not the same as `0-i`.
    Expect.equals((-i).bitLength, BigInt.from(-i).bitLength);
  }

  // Test x.bitLength for a large variety of lengths.
  for (int length = 5; length <= 512; length++) {
    BigInt base = BigInt.one << (length - 1);
    Expect.equals(length, base.bitLength);

    // Power of two.
    check(length, base);

    // Two high bits set.
    check(length, base | base >> 1);

    // Check for values with an additional bit set near a potential internal
    // digit boundary.
    for (int i1 = 16; i1 < length; i1 += 16) {
      for (int i2 = -1; i2 <= 1; i2++) {
        int i = i1 + i2;
        if (i < length - 1) {
          check(length, base | BigInt.one << (i - 1));
        }
      }
    }
  }
}

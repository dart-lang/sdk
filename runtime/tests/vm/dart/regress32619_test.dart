// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dartbug.com/32619: incorrect widening of smis to int32.

// VMOptions=--optimization-counter-threshold=5 --no-background-compilation

import "package:expect/expect.dart";
import 'dart:typed_data';

const int _digitBits = 32;
const int _digitMask = (1 << _digitBits) - 1;

const int _halfDigitBits = _digitBits >> 1;
const int _halfDigitMask = (1 << _halfDigitBits) - 1;

int _mulAdd(Uint32List multiplicandDigits, int i, Uint32List accumulatorDigits,
    int j, int n) {
  int carry = 0;
  while (--n >= 0) {
    int ml = multiplicandDigits[i] & _halfDigitMask;
    int mh = multiplicandDigits[i++] >> _halfDigitBits;
    int ph = mh * 4;
    int q1 = ((ph & _halfDigitMask) << _halfDigitBits);
    int pl = 4 * ml + q1 + accumulatorDigits[j];
    carry = (pl >> _digitBits) + (ph >> _halfDigitBits);
    accumulatorDigits[j++] = pl & _digitMask;
  }

  return carry;
}

main() {
  var multiplicandDigits = new Uint32List.fromList([0, 294967296, 0, 0]);
  var accumulatorDigits = new Uint32List.fromList([0, 4, 4, 0, 0, 0]);

  var d1 = _mulAdd(multiplicandDigits, 0, accumulatorDigits, 0, 2);

  Expect.equals(0, d1);
}

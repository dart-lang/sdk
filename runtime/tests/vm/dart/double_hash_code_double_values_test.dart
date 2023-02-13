// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This complements corelib/double_hash_code_test.dart and verifies hash code
// values of doubles that are not representable as integers.
//
// VMOptions=--use_sse41
// VMOptions=--no_use_sse41

import 'package:expect/expect.dart';

import 'isolates/fast_object_copy_timeline_test.dart' show slotSize;

void main() {
  // On 32-bit and 64-bit-compressed modes double.hashCode is different for
  // non-integer doubles.
  // NaN values are not being tested because bit patterns for NaN, used for
  // hash code calculations are platform and toolchain dependent.
  if (slotSize == 4) {
    Expect.equals(1072693248, double.infinity.hashCode);
    Expect.equals(1048576, double.maxFinite.hashCode);
    Expect.equals(1, double.minPositive.hashCode);
    Expect.equals(1072693248, double.negativeInfinity.hashCode);
  } else {
    Expect.equals(4607182420946452480, double.infinity.hashCode);
    Expect.equals(4607182416653582336, double.maxFinite.hashCode);
    Expect.equals(1, double.minPositive.hashCode);
    Expect.equals(4607182423093936128, double.negativeInfinity.hashCode);
  }
}

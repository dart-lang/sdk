// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/assert.h"
#include "vm/unit_test.h"
#include "vm/utils.h"

namespace dart {

UNIT_TEST_CASE(Minimum) {
  EXPECT_EQ(0, Utils::Minimum(0, 1));
  EXPECT_EQ(0, Utils::Minimum(1, 0));

  EXPECT_EQ(1, Utils::Minimum(1, 2));
  EXPECT_EQ(1, Utils::Minimum(2, 1));

  EXPECT_EQ(-1, Utils::Minimum(-1, 1));
  EXPECT_EQ(-1, Utils::Minimum(1, -1));

  EXPECT_EQ(-2, Utils::Minimum(-1, -2));
  EXPECT_EQ(-2, Utils::Minimum(-2, -1));
}


UNIT_TEST_CASE(Maximum) {
  EXPECT_EQ(1, Utils::Maximum(0, 1));
  EXPECT_EQ(1, Utils::Maximum(1, 0));

  EXPECT_EQ(2, Utils::Maximum(1, 2));
  EXPECT_EQ(2, Utils::Maximum(2, 1));

  EXPECT_EQ(1, Utils::Maximum(-1, 1));
  EXPECT_EQ(1, Utils::Maximum(1, -1));

  EXPECT_EQ(-1, Utils::Maximum(-1, -2));
  EXPECT_EQ(-1, Utils::Maximum(-2, -1));
}


UNIT_TEST_CASE(IsPowerOfTwo) {
  EXPECT(Utils::IsPowerOfTwo(0));
  EXPECT(Utils::IsPowerOfTwo(1));
  EXPECT(Utils::IsPowerOfTwo(2));
  EXPECT(!Utils::IsPowerOfTwo(3));
  EXPECT(Utils::IsPowerOfTwo(4));
  EXPECT(Utils::IsPowerOfTwo(256));

  EXPECT(!Utils::IsPowerOfTwo(-1));
  EXPECT(!Utils::IsPowerOfTwo(-2));
}


UNIT_TEST_CASE(ShiftForPowerOfTwo) {
  EXPECT_EQ(1, Utils::ShiftForPowerOfTwo(2));
  EXPECT_EQ(2, Utils::ShiftForPowerOfTwo(4));
  EXPECT_EQ(8, Utils::ShiftForPowerOfTwo(256));
}


UNIT_TEST_CASE(IsAligned) {
  EXPECT(Utils::IsAligned(0, 0));
  EXPECT(Utils::IsAligned(0, 1));
  EXPECT(Utils::IsAligned(1, 1));

  EXPECT(Utils::IsAligned(0, 2));
  EXPECT(!Utils::IsAligned(1, 2));
  EXPECT(Utils::IsAligned(2, 2));

  EXPECT(Utils::IsAligned(32, 8));
  EXPECT(!Utils::IsAligned(33, 8));
  EXPECT(Utils::IsAligned(40, 8));
}


UNIT_TEST_CASE(RoundDown) {
  EXPECT_EQ(0, Utils::RoundDown(0, 0));
  EXPECT_EQ(0, Utils::RoundDown(22, 32));
  EXPECT_EQ(32, Utils::RoundDown(33, 32));
  EXPECT_EQ(32, Utils::RoundDown(63, 32));
  uword* address = reinterpret_cast<uword*>(63);
  uword* rounddown_address = reinterpret_cast<uword*>(32);
  EXPECT_EQ(rounddown_address, Utils::RoundDown(address, 32));
}


UNIT_TEST_CASE(RoundUp) {
  EXPECT_EQ(0, Utils::RoundUp(0, 0));
  EXPECT_EQ(0, Utils::RoundUp(1, 0));
  EXPECT_EQ(32, Utils::RoundUp(22, 32));
  EXPECT_EQ(64, Utils::RoundUp(33, 32));
  EXPECT_EQ(64, Utils::RoundUp(63, 32));
  uword* address = reinterpret_cast<uword*>(63);
  uword* roundup_address = reinterpret_cast<uword*>(64);
  EXPECT_EQ(roundup_address, Utils::RoundUp(address, 32));
}


UNIT_TEST_CASE(RoundUpToPowerOfTwo) {
  EXPECT_EQ(0U, Utils::RoundUpToPowerOfTwo(0));
  EXPECT_EQ(1U, Utils::RoundUpToPowerOfTwo(1));
  EXPECT_EQ(2U, Utils::RoundUpToPowerOfTwo(2));
  EXPECT_EQ(4U, Utils::RoundUpToPowerOfTwo(3));
  EXPECT_EQ(4U, Utils::RoundUpToPowerOfTwo(4));
  EXPECT_EQ(8U, Utils::RoundUpToPowerOfTwo(5));
  EXPECT_EQ(8U, Utils::RoundUpToPowerOfTwo(7));
  EXPECT_EQ(16U, Utils::RoundUpToPowerOfTwo(9));
  EXPECT_EQ(16U, Utils::RoundUpToPowerOfTwo(16));
  EXPECT_EQ(0x10000000U, Utils::RoundUpToPowerOfTwo(0x08765432));
}


UNIT_TEST_CASE(CountOneBits) {
  EXPECT_EQ(0, Utils::CountOneBits(0));
  EXPECT_EQ(1, Utils::CountOneBits(0x00000010));
  EXPECT_EQ(1, Utils::CountOneBits(0x00010000));
  EXPECT_EQ(1, Utils::CountOneBits(0x10000000));
  EXPECT_EQ(4, Utils::CountOneBits(0x10101010));
  EXPECT_EQ(8, Utils::CountOneBits(0x03030303));
  EXPECT_EQ(32, Utils::CountOneBits(0xFFFFFFFF));
}


UNIT_TEST_CASE(IsInt) {
  EXPECT(Utils::IsInt(8, 16));
  EXPECT(Utils::IsInt(8, 127));
  EXPECT(Utils::IsInt(8, -128));
  EXPECT(!Utils::IsInt(8, 255));
  EXPECT(Utils::IsInt(16, 16));
  EXPECT(!Utils::IsInt(16, 65535));
  EXPECT(Utils::IsInt(16, 32767));
  EXPECT(Utils::IsInt(16, -32768));
}


UNIT_TEST_CASE(IsUint) {
  EXPECT(Utils::IsUint(8, 16));
  EXPECT(Utils::IsUint(8, 0));
  EXPECT(Utils::IsUint(8, 255));
  EXPECT(!Utils::IsUint(8, 256));
  EXPECT(Utils::IsUint(16, 16));
  EXPECT(Utils::IsUint(16, 0));
  EXPECT(Utils::IsUint(16, 65535));
  EXPECT(!Utils::IsUint(16, 65536));
}


UNIT_TEST_CASE(IsAbsoluteUint) {
  EXPECT(Utils::IsAbsoluteUint(8, 16));
  EXPECT(Utils::IsAbsoluteUint(8, 0));
  EXPECT(Utils::IsAbsoluteUint(8, -128));
  EXPECT(Utils::IsAbsoluteUint(8, 255));
  EXPECT(!Utils::IsAbsoluteUint(8, 256));
  EXPECT(Utils::IsAbsoluteUint(16, 16));
  EXPECT(Utils::IsAbsoluteUint(16, 0));
  EXPECT(Utils::IsAbsoluteUint(16, 65535));
  EXPECT(Utils::IsAbsoluteUint(16, -32768));
  EXPECT(!Utils::IsAbsoluteUint(16, 65536));
}


UNIT_TEST_CASE(LowBits) {
  EXPECT_EQ(0xff00, Utils::Low16Bits(0xffff00));
  EXPECT_EQ(0xff, Utils::High16Bits(0xffff00));
  EXPECT_EQ(0xff00, Utils::Low32Bits(0xff0000ff00LL));
  EXPECT_EQ(0xff, Utils::High32Bits(0xff0000ff00LL));
  EXPECT_EQ(0x00ff0000ff00LL, Utils::LowHighTo64Bits(0xff00, 0x00ff));
}

}  // namespace dart

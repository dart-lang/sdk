// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/utils.h"
#include "platform/assert.h"
#include "vm/unit_test.h"

namespace dart {

VM_UNIT_TEST_CASE(Minimum) {
  EXPECT_EQ(0, Utils::Minimum(0, 1));
  EXPECT_EQ(0, Utils::Minimum(1, 0));

  EXPECT_EQ(1, Utils::Minimum(1, 2));
  EXPECT_EQ(1, Utils::Minimum(2, 1));

  EXPECT_EQ(-1, Utils::Minimum(-1, 1));
  EXPECT_EQ(-1, Utils::Minimum(1, -1));

  EXPECT_EQ(-2, Utils::Minimum(-1, -2));
  EXPECT_EQ(-2, Utils::Minimum(-2, -1));
}

VM_UNIT_TEST_CASE(Maximum) {
  EXPECT_EQ(1, Utils::Maximum(0, 1));
  EXPECT_EQ(1, Utils::Maximum(1, 0));

  EXPECT_EQ(2, Utils::Maximum(1, 2));
  EXPECT_EQ(2, Utils::Maximum(2, 1));

  EXPECT_EQ(1, Utils::Maximum(-1, 1));
  EXPECT_EQ(1, Utils::Maximum(1, -1));

  EXPECT_EQ(-1, Utils::Maximum(-1, -2));
  EXPECT_EQ(-1, Utils::Maximum(-2, -1));
}

VM_UNIT_TEST_CASE(IsPowerOfTwo) {
  EXPECT(!Utils::IsPowerOfTwo(0));
  EXPECT(Utils::IsPowerOfTwo(1));
  EXPECT(Utils::IsPowerOfTwo(2));
  EXPECT(!Utils::IsPowerOfTwo(3));
  EXPECT(Utils::IsPowerOfTwo(4));
  EXPECT(Utils::IsPowerOfTwo(256));

  EXPECT(!Utils::IsPowerOfTwo(-1));
  EXPECT(!Utils::IsPowerOfTwo(-2));
}

VM_UNIT_TEST_CASE(ShiftForPowerOfTwo) {
  EXPECT_EQ(1, Utils::ShiftForPowerOfTwo(2));
  EXPECT_EQ(2, Utils::ShiftForPowerOfTwo(4));
  EXPECT_EQ(8, Utils::ShiftForPowerOfTwo(256));
}

VM_UNIT_TEST_CASE(IsAligned) {
  EXPECT(Utils::IsAligned(0, 1));
  EXPECT(Utils::IsAligned(1, 1));

  EXPECT(Utils::IsAligned(0, 2));
  EXPECT(!Utils::IsAligned(1, 2));
  EXPECT(Utils::IsAligned(2, 2));

  EXPECT(Utils::IsAligned(32, 8));
  EXPECT(!Utils::IsAligned(33, 8));
  EXPECT(Utils::IsAligned(40, 8));
}

VM_UNIT_TEST_CASE(RoundDown) {
  EXPECT_EQ(0, Utils::RoundDown(22, 32));
  EXPECT_EQ(32, Utils::RoundDown(33, 32));
  EXPECT_EQ(32, Utils::RoundDown(63, 32));
  uword* address = reinterpret_cast<uword*>(63);
  uword* rounddown_address = reinterpret_cast<uword*>(32);
  EXPECT_EQ(rounddown_address, Utils::RoundDown(address, 32));
}

VM_UNIT_TEST_CASE(RoundUp) {
  EXPECT_EQ(32, Utils::RoundUp(22, 32));
  EXPECT_EQ(64, Utils::RoundUp(33, 32));
  EXPECT_EQ(64, Utils::RoundUp(63, 32));
  uword* address = reinterpret_cast<uword*>(63);
  uword* roundup_address = reinterpret_cast<uword*>(64);
  EXPECT_EQ(roundup_address, Utils::RoundUp(address, 32));
}

VM_UNIT_TEST_CASE(RoundUpToPowerOfTwo) {
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

VM_UNIT_TEST_CASE(CountOneBits32) {
  EXPECT_EQ(0, Utils::CountOneBits32(0));
  EXPECT_EQ(1, Utils::CountOneBits32(0x00000010));
  EXPECT_EQ(1, Utils::CountOneBits32(0x00010000));
  EXPECT_EQ(1, Utils::CountOneBits32(0x10000000));
  EXPECT_EQ(4, Utils::CountOneBits32(0x10101010));
  EXPECT_EQ(8, Utils::CountOneBits32(0x03030303));
  EXPECT_EQ(32, Utils::CountOneBits32(0xFFFFFFFF));
}

VM_UNIT_TEST_CASE(CountOneBits64) {
  EXPECT_EQ(0, Utils::CountOneBits64(DART_UINT64_C(0)));
  EXPECT_EQ(1, Utils::CountOneBits64(DART_UINT64_C(0x00000010)));
  EXPECT_EQ(1, Utils::CountOneBits64(DART_UINT64_C(0x00010000)));
  EXPECT_EQ(1, Utils::CountOneBits64(DART_UINT64_C(0x10000000)));
  EXPECT_EQ(4, Utils::CountOneBits64(DART_UINT64_C(0x10101010)));
  EXPECT_EQ(8, Utils::CountOneBits64(DART_UINT64_C(0x03030303)));
  EXPECT_EQ(32, Utils::CountOneBits64(DART_UINT64_C(0xFFFFFFFF)));

  EXPECT_EQ(2, Utils::CountOneBits64(DART_UINT64_C(0x0000001000000010)));
  EXPECT_EQ(2, Utils::CountOneBits64(DART_UINT64_C(0x0001000000010000)));
  EXPECT_EQ(2, Utils::CountOneBits64(DART_UINT64_C(0x1000000010000000)));
  EXPECT_EQ(8, Utils::CountOneBits64(DART_UINT64_C(0x1010101010101010)));
  EXPECT_EQ(16, Utils::CountOneBits64(DART_UINT64_C(0x0303030303030303)));
  EXPECT_EQ(64, Utils::CountOneBits64(DART_UINT64_C(0xFFFFFFFFFFFFFFFF)));
}

VM_UNIT_TEST_CASE(CountOneBitsWord) {
  EXPECT_EQ(0, Utils::CountOneBitsWord(0));
  EXPECT_EQ(1, Utils::CountOneBitsWord(0x00000010));
  EXPECT_EQ(1, Utils::CountOneBitsWord(0x00010000));
  EXPECT_EQ(1, Utils::CountOneBitsWord(0x10000000));
  EXPECT_EQ(4, Utils::CountOneBitsWord(0x10101010));
  EXPECT_EQ(8, Utils::CountOneBitsWord(0x03030303));
  EXPECT_EQ(32, Utils::CountOneBitsWord(0xFFFFFFFF));

#if defined(ARCH_IS_64_BIT)
  EXPECT_EQ(2, Utils::CountOneBitsWord(0x0000001000000010));
  EXPECT_EQ(2, Utils::CountOneBitsWord(0x0001000000010000));
  EXPECT_EQ(2, Utils::CountOneBitsWord(0x1000000010000000));
  EXPECT_EQ(8, Utils::CountOneBitsWord(0x1010101010101010));
  EXPECT_EQ(16, Utils::CountOneBitsWord(0x0303030303030303));
  EXPECT_EQ(64, Utils::CountOneBitsWord(0xFFFFFFFFFFFFFFFF));
#endif
}

VM_UNIT_TEST_CASE(CountZeros) {
  EXPECT_EQ(0, Utils::CountTrailingZeros(0x1));
  EXPECT_EQ(kBitsPerWord - 1, Utils::CountLeadingZeros(0x1));
  EXPECT_EQ(1, Utils::CountTrailingZeros(0x2));
  EXPECT_EQ(kBitsPerWord - 2, Utils::CountLeadingZeros(0x2));
  EXPECT_EQ(0, Utils::CountTrailingZeros(0x3));
  EXPECT_EQ(kBitsPerWord - 2, Utils::CountLeadingZeros(0x3));
  EXPECT_EQ(2, Utils::CountTrailingZeros(0x4));
  EXPECT_EQ(kBitsPerWord - 3, Utils::CountLeadingZeros(0x4));
  EXPECT_EQ(0, Utils::CountTrailingZeros(kUwordMax));
  EXPECT_EQ(0, Utils::CountLeadingZeros(kUwordMax));
  static const uword kTopBit = static_cast<uword>(1) << (kBitsPerWord - 1);
  EXPECT_EQ(kBitsPerWord - 1, Utils::CountTrailingZeros(kTopBit));
  EXPECT_EQ(0, Utils::CountLeadingZeros(kTopBit));
}

VM_UNIT_TEST_CASE(IsInt) {
  EXPECT(Utils::IsInt(8, 16));
  EXPECT(Utils::IsInt(8, 127));
  EXPECT(Utils::IsInt(8, -128));
  EXPECT(!Utils::IsInt(8, 255));
  EXPECT(Utils::IsInt(16, 16));
  EXPECT(!Utils::IsInt(16, 65535));
  EXPECT(Utils::IsInt(16, 32767));
  EXPECT(Utils::IsInt(16, -32768));
  EXPECT(Utils::IsInt(32, 16LL));
  EXPECT(Utils::IsInt(32, 2147483647LL));
  EXPECT(Utils::IsInt(32, -2147483648LL));
  EXPECT(!Utils::IsInt(32, 4294967295LL));
}

VM_UNIT_TEST_CASE(IsUint) {
  EXPECT(Utils::IsUint(8, 16));
  EXPECT(Utils::IsUint(8, 0));
  EXPECT(Utils::IsUint(8, 255));
  EXPECT(!Utils::IsUint(8, 256));
  EXPECT(Utils::IsUint(16, 16));
  EXPECT(Utils::IsUint(16, 0));
  EXPECT(Utils::IsUint(16, 65535));
  EXPECT(!Utils::IsUint(16, 65536));
  EXPECT(Utils::IsUint(32, 16LL));
  EXPECT(Utils::IsUint(32, 0LL));
  EXPECT(Utils::IsUint(32, 4294967295LL));
  EXPECT(!Utils::IsUint(32, 4294967296LL));
}

VM_UNIT_TEST_CASE(IsAbsoluteUint) {
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
  EXPECT(Utils::IsAbsoluteUint(32, 16LL));
  EXPECT(Utils::IsAbsoluteUint(32, 0LL));
  EXPECT(Utils::IsAbsoluteUint(32, -2147483648LL));
  EXPECT(Utils::IsAbsoluteUint(32, 4294967295LL));
  EXPECT(!Utils::IsAbsoluteUint(32, 4294967296LL));
}

VM_UNIT_TEST_CASE(LowBits) {
  EXPECT_EQ(0xff00, Utils::Low16Bits(0xffff00));
  EXPECT_EQ(0xff, Utils::High16Bits(0xffff00));
  EXPECT_EQ(0xff00, Utils::Low32Bits(0xff0000ff00LL));
  EXPECT_EQ(0xff, Utils::High32Bits(0xff0000ff00LL));
  EXPECT_EQ(0x00ff0000ff00LL, Utils::LowHighTo64Bits(0xff00, 0x00ff));
}

VM_UNIT_TEST_CASE(Endianity) {
  uint16_t value16be = Utils::HostToBigEndian16(0xf1);
  EXPECT_EQ(0x0, reinterpret_cast<uint8_t*>(&value16be)[0]);
  EXPECT_EQ(0xf1, reinterpret_cast<uint8_t*>(&value16be)[1]);

  uint16_t value16le = Utils::HostToLittleEndian16(0xf1);
  EXPECT_EQ(0xf1, reinterpret_cast<uint8_t*>(&value16le)[0]);
  EXPECT_EQ(0x0, reinterpret_cast<uint8_t*>(&value16le)[1]);

  uint32_t value32be = Utils::HostToBigEndian32(0xf1f2);
  EXPECT_EQ(0x0, reinterpret_cast<uint8_t*>(&value32be)[0]);
  EXPECT_EQ(0x0, reinterpret_cast<uint8_t*>(&value32be)[1]);
  EXPECT_EQ(0xf1, reinterpret_cast<uint8_t*>(&value32be)[2]);
  EXPECT_EQ(0xf2, reinterpret_cast<uint8_t*>(&value32be)[3]);

  uint32_t value32le = Utils::HostToLittleEndian32(0xf1f2);
  EXPECT_EQ(0xf2, reinterpret_cast<uint8_t*>(&value32le)[0]);
  EXPECT_EQ(0xf1, reinterpret_cast<uint8_t*>(&value32le)[1]);
  EXPECT_EQ(0x0, reinterpret_cast<uint8_t*>(&value32le)[2]);
  EXPECT_EQ(0x0, reinterpret_cast<uint8_t*>(&value32le)[3]);

  uint64_t value64be = Utils::HostToBigEndian64(0xf1f2f3f4);
  EXPECT_EQ(0x0, reinterpret_cast<uint8_t*>(&value64be)[0]);
  EXPECT_EQ(0x0, reinterpret_cast<uint8_t*>(&value64be)[1]);
  EXPECT_EQ(0x0, reinterpret_cast<uint8_t*>(&value64be)[2]);
  EXPECT_EQ(0x0, reinterpret_cast<uint8_t*>(&value64be)[3]);
  EXPECT_EQ(0xf1, reinterpret_cast<uint8_t*>(&value64be)[4]);
  EXPECT_EQ(0xf2, reinterpret_cast<uint8_t*>(&value64be)[5]);
  EXPECT_EQ(0xf3, reinterpret_cast<uint8_t*>(&value64be)[6]);
  EXPECT_EQ(0xf4, reinterpret_cast<uint8_t*>(&value64be)[7]);

  uint64_t value64le = Utils::HostToLittleEndian64(0xf1f2f3f4);
  EXPECT_EQ(0xf4, reinterpret_cast<uint8_t*>(&value64le)[0]);
  EXPECT_EQ(0xf3, reinterpret_cast<uint8_t*>(&value64le)[1]);
  EXPECT_EQ(0xf2, reinterpret_cast<uint8_t*>(&value64le)[2]);
  EXPECT_EQ(0xf1, reinterpret_cast<uint8_t*>(&value64le)[3]);
  EXPECT_EQ(0x0, reinterpret_cast<uint8_t*>(&value64le)[4]);
  EXPECT_EQ(0x0, reinterpret_cast<uint8_t*>(&value64le)[5]);
  EXPECT_EQ(0x0, reinterpret_cast<uint8_t*>(&value64le)[6]);
  EXPECT_EQ(0x0, reinterpret_cast<uint8_t*>(&value64le)[7]);
}

VM_UNIT_TEST_CASE(DoublesBitEqual) {
  EXPECT(Utils::DoublesBitEqual(1.0, 1.0));
  EXPECT(!Utils::DoublesBitEqual(1.0, -1.0));
  EXPECT(Utils::DoublesBitEqual(0.0, 0.0));
  EXPECT(!Utils::DoublesBitEqual(0.0, -0.0));
  EXPECT(Utils::DoublesBitEqual(NAN, NAN));
}

}  // namespace dart

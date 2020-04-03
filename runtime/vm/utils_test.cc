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

VM_UNIT_TEST_CASE(CountTrailingZeros32) {
  EXPECT_EQ(0, Utils::CountTrailingZeros32(0x1));
  EXPECT_EQ(1, Utils::CountTrailingZeros32(0x2));
  EXPECT_EQ(4, Utils::CountTrailingZeros32(0x0f0f0));
  EXPECT_EQ(31, Utils::CountTrailingZeros32(0x80000000));
  EXPECT_EQ(32, Utils::CountTrailingZeros32(0x0));
}

VM_UNIT_TEST_CASE(CountTrailingZeros64) {
  EXPECT_EQ(0, Utils::CountTrailingZeros64(0x1));
  EXPECT_EQ(1, Utils::CountTrailingZeros64(0x2));
  EXPECT_EQ(4, Utils::CountTrailingZeros64(0x0f0f0));
  EXPECT_EQ(63, Utils::CountTrailingZeros64(0x8000000000000000LLU));
  EXPECT_EQ(64, Utils::CountTrailingZeros64(0x0));
}

VM_UNIT_TEST_CASE(CountLeadingZeros32) {
  EXPECT_EQ(32, Utils::CountLeadingZeros32(0x0));
  EXPECT_EQ(31, Utils::CountLeadingZeros32(0x1));
  EXPECT_EQ(4, Utils::CountLeadingZeros32(0x0F0F0000));
  EXPECT_EQ(1, Utils::CountLeadingZeros32(0x7FFFFFFF));
  EXPECT_EQ(0, Utils::CountLeadingZeros32(0xFFFFFFFF));
}

VM_UNIT_TEST_CASE(CountLeadingZeros64) {
  EXPECT_EQ(64, Utils::CountLeadingZeros64(0x0));
  EXPECT_EQ(63, Utils::CountLeadingZeros64(0x1));
  EXPECT_EQ(4, Utils::CountLeadingZeros64(0x0F0F000000000000LLU));
  EXPECT_EQ(1, Utils::CountLeadingZeros64(0x7FFFFFFFFFFFFFFFLLU));
  EXPECT_EQ(0, Utils::CountLeadingZeros64(0xFFFFFFFFFFFFFFFFLLU));
}

VM_UNIT_TEST_CASE(CountZerosWord) {
  EXPECT_EQ(kBitsPerWord, Utils::CountTrailingZerosWord(0x0));
  EXPECT_EQ(kBitsPerWord, Utils::CountLeadingZerosWord(0x0));
  EXPECT_EQ(0, Utils::CountTrailingZerosWord(0x1));
  EXPECT_EQ(kBitsPerWord - 1, Utils::CountLeadingZerosWord(0x1));
  EXPECT_EQ(1, Utils::CountTrailingZerosWord(0x2));
  EXPECT_EQ(kBitsPerWord - 2, Utils::CountLeadingZerosWord(0x2));
  EXPECT_EQ(0, Utils::CountTrailingZerosWord(0x3));
  EXPECT_EQ(kBitsPerWord - 2, Utils::CountLeadingZerosWord(0x3));
  EXPECT_EQ(2, Utils::CountTrailingZerosWord(0x4));
  EXPECT_EQ(kBitsPerWord - 3, Utils::CountLeadingZerosWord(0x4));
  EXPECT_EQ(0, Utils::CountTrailingZerosWord(kUwordMax));
  EXPECT_EQ(0, Utils::CountLeadingZerosWord(kUwordMax));
  static const uword kTopBit = static_cast<uword>(1) << (kBitsPerWord - 1);
  EXPECT_EQ(kBitsPerWord - 1, Utils::CountTrailingZerosWord(kTopBit));
  EXPECT_EQ(0, Utils::CountLeadingZerosWord(kTopBit));
}

VM_UNIT_TEST_CASE(ReverseBits32) {
  EXPECT_EQ(0xffffffffU, Utils::ReverseBits32(0xffffffffU));
  EXPECT_EQ(0xf0000000U, Utils::ReverseBits32(0x0000000fU));
  EXPECT_EQ(0x00000001U, Utils::ReverseBits32(0x80000000U));
  EXPECT_EQ(0x22222222U, Utils::ReverseBits32(0x44444444U));
  EXPECT_EQ(0x1E6A2C48U, Utils::ReverseBits32(0x12345678U));
}

VM_UNIT_TEST_CASE(ReverseBits64) {
  EXPECT_EQ(0xffffffffffffffffLLU, Utils::ReverseBits64(0xffffffffffffffffLLU));
  EXPECT_EQ(0xf000000000000000LLU, Utils::ReverseBits64(0x000000000000000fLLU));
  EXPECT_EQ(0x0000000000000001LLU, Utils::ReverseBits64(0x8000000000000000LLU));
  EXPECT_EQ(0x2222222222222222LLU, Utils::ReverseBits64(0x4444444444444444LLU));
  EXPECT_EQ(0x8f7b3d591e6a2c48LLU, Utils::ReverseBits64(0x123456789abcdef1LLU));
}

VM_UNIT_TEST_CASE(ReverseBitsWord) {
  const uword kOne = static_cast<uword>(1);
  const uword kTopBit = kOne << (kBitsPerWord - 1);
  EXPECT_EQ(kTopBit, Utils::ReverseBitsWord(kOne));
  EXPECT_EQ(kOne, Utils::ReverseBitsWord(kTopBit));
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
  EXPECT_EQ(0xf1f2u, Utils::BigEndianToHost32(value32be));

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
  EXPECT_EQ(0xf1f2f3f4ul, Utils::LittleEndianToHost64(value64le));
}

VM_UNIT_TEST_CASE(DoublesBitEqual) {
  EXPECT(Utils::DoublesBitEqual(1.0, 1.0));
  EXPECT(!Utils::DoublesBitEqual(1.0, -1.0));
  EXPECT(Utils::DoublesBitEqual(0.0, 0.0));
  EXPECT(!Utils::DoublesBitEqual(0.0, -0.0));
  EXPECT(Utils::DoublesBitEqual(NAN, NAN));
}

VM_UNIT_TEST_CASE(NBitMask) {
#if defined(ARCH_IS_64_BIT)
  EXPECT_EQ(0ull, Utils::NBitMask(0));
  EXPECT_EQ(0x1ull, Utils::NBitMask(1));
  EXPECT_EQ(0x3ull, Utils::NBitMask(2));
  EXPECT_EQ(0xfull, Utils::NBitMask(4));
  EXPECT_EQ(0xffull, Utils::NBitMask(8));
  EXPECT_EQ(0xffffull, Utils::NBitMask(16));
  EXPECT_EQ(0x1ffffull, Utils::NBitMask(17));
  EXPECT_EQ(0x7fffffffull, Utils::NBitMask(31));
  EXPECT_EQ(0xffffffffull, Utils::NBitMask(32));
  EXPECT_EQ(0x1ffffffffull, Utils::NBitMask(33));
  EXPECT_EQ(0x7fffffffffffffffull, Utils::NBitMask(kBitsPerWord - 1));
  EXPECT_EQ(0xffffffffffffffffull, Utils::NBitMask(kBitsPerWord));
#else
  EXPECT_EQ(0u, Utils::NBitMask(0));
  EXPECT_EQ(0x1u, Utils::NBitMask(1));
  EXPECT_EQ(0x3u, Utils::NBitMask(2));
  EXPECT_EQ(0xfu, Utils::NBitMask(4));
  EXPECT_EQ(0xffu, Utils::NBitMask(8));
  EXPECT_EQ(0xffffu, Utils::NBitMask(16));
  EXPECT_EQ(0x1ffffu, Utils::NBitMask(17));
  EXPECT_EQ(0x7fffffffu, Utils::NBitMask(kBitsPerWord - 1));
  EXPECT_EQ(0xffffffffu, Utils::NBitMask(kBitsPerWord));
#endif
}

}  // namespace dart

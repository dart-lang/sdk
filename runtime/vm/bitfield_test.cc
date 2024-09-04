// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "vm/bitfield.h"
#include "vm/globals.h"
#include "vm/unit_test.h"

namespace dart {

VM_UNIT_TEST_CASE(BitFields) {
  using TestBitFields = BitField<uword, int32_t, 1, 8>;
  EXPECT(TestBitFields::is_valid(16));
  EXPECT(!TestBitFields::is_valid(256));
  EXPECT_EQ(0x00ffU, TestBitFields::mask());
  EXPECT_EQ(0x001feU, TestBitFields::mask_in_place());
  EXPECT_EQ(1, TestBitFields::shift());
  EXPECT_EQ(8, TestBitFields::bitsize());
  EXPECT_EQ(32U, TestBitFields::encode(16));
  EXPECT_EQ(16, TestBitFields::decode(32));
  EXPECT_EQ(2U, TestBitFields::update(1, 16));
}

template <typename T>
static void TestSignExtendedBitField() {
  using F1 = BitField<T, intptr_t, 0, 8, /*sign_extend=*/true>;
  using F2 = BitField<T, uintptr_t, F1::kNextBit, 8, /*sign_extend=*/false>;
  using F3 = BitField<T, intptr_t, F2::kNextBit, 8, /*sign_extend=*/true>;
  using F4 = BitField<T, uintptr_t, F3::kNextBit, 8, /*sign_extend=*/false>;

  const uint32_t value =
      F1::encode(-1) | F2::encode(1) | F3::encode(-2) | F4::encode(2);
  EXPECT_EQ(0x02fe01ffU, value);
  EXPECT_EQ(-1, F1::decode(value));
  EXPECT_EQ(1U, F2::decode(value));
  EXPECT_EQ(-2, F3::decode(value));
  EXPECT_EQ(2U, F4::decode(value));
}

template <typename T>
static void TestNotSignExtendedBitField() {
  using F1 = BitField<T, intptr_t, 0, 8, /*sign_extend=*/false>;
  using F2 = BitField<T, uintptr_t, F1::kNextBit, 8, /*sign_extend=*/false>;
  using F3 = BitField<T, intptr_t, F2::kNextBit, 8, /*sign_extend=*/false>;
  using F4 = BitField<T, uintptr_t, F3::kNextBit, 8, /*sign_extend=*/false>;

  const uint32_t value =
      F1::encode(-1) | F2::encode(1) | F3::encode(-2) | F4::encode(2);
  EXPECT_EQ(0x02fe01ffU, value);
  EXPECT_EQ(3, F1::decode(value));
  EXPECT_EQ(1, F2::decode(value));
  EXPECT_EQ(2, F3::decode(value));
  EXPECT_EQ(2, F3::decode(value));
}

VM_UNIT_TEST_CASE(BitFields_SignedField) {
  TestSignExtendedBitField<uint32_t>();
  TestSignExtendedBitField<int32_t>();
}

VM_UNIT_TEST_CASE(BitFields_Defaults) {
  using F1 = BitField<intptr_t, bool>;
  using F2 = BitField<intptr_t, uint8_t, F1::kNextBit>;
  using F3 = BitField<intptr_t, int16_t, F2::kNextBit>;
  using F3s = BitField<intptr_t, int16_t, F2::kNextBit, kBitsPerInt16,
                       /*sign_extend=*/true>;
  using F4 = BitField<intptr_t, intptr_t, F3::kNextBit>;
  using F4s = SignedBitField<intptr_t, intptr_t, F3::kNextBit>;
  // Like F4/F4s, but based on F3s.
  using F5 = BitField<intptr_t, intptr_t, F3s::kNextBit>;
  using F5s = SignedBitField<intptr_t, intptr_t, F3s::kNextBit>;

  const intptr_t kF4Bitsize = kBitsPerWord - 24;
  const intptr_t kF4Max = (static_cast<intptr_t>(1) << (kF4Bitsize)) - 1;
  const intptr_t kF4sMax = (static_cast<intptr_t>(1) << (kF4Bitsize - 1)) - 1;

  const intptr_t kF5Bitsize = kBitsPerWord - 25;
  const intptr_t kF5Max = (static_cast<intptr_t>(1) << (kF5Bitsize)) - 1;
  const intptr_t kF5sMax = (static_cast<intptr_t>(1) << (kF5Bitsize - 1)) - 1;

  EXPECT_EQ(1, F1::bitsize());
  EXPECT_EQ(8, F2::bitsize());
  EXPECT_EQ(15, F3::bitsize());
  EXPECT_EQ(16, F3s::bitsize());
  EXPECT_EQ(kF4Bitsize, F4::bitsize());
  EXPECT_EQ(kF4Bitsize, F4s::bitsize());
  EXPECT_EQ(kF5Bitsize, F5::bitsize());
  EXPECT_EQ(kF5Bitsize, F5s::bitsize());

  EXPECT_EQ(0, F1::shift());
  EXPECT_EQ(1, F2::shift());
  EXPECT_EQ(9, F3::shift());
  EXPECT_EQ(9, F3s::shift());
  EXPECT_EQ(24, F4::shift());
  EXPECT_EQ(24, F4s::shift());
  EXPECT_EQ(25, F5::shift());
  EXPECT_EQ(25, F5s::shift());

  EXPECT_EQ(false, F1::min());
  EXPECT_EQ(0, F2::min());
  EXPECT_EQ(0, F3::min());
  EXPECT_EQ(~0x7FFF, F3s::min());
  EXPECT_EQ(0, F4::min());
  EXPECT_EQ(~kF4sMax, F4s::min());
  EXPECT_EQ(F5::min(), 0);
  EXPECT_EQ(~kF5sMax, F5s::min());

  EXPECT_EQ(true, F1::max());
  EXPECT_EQ(0xFF, F2::max());
  EXPECT_EQ(0x7FFF, F3::max());
  EXPECT_EQ(0x7FFF, F3s::max());
  EXPECT_EQ(kF4Max, F4::max());
  EXPECT_EQ(kF4sMax, F4s::max());
  EXPECT_EQ(kF5Max, F5::max());
  EXPECT_EQ(kF5sMax, F5s::max());
}

#if defined(DEBUG)
#define DEBUG_CRASH "Crash"
#else
#define DEBUG_CRASH "Pass"
#endif

VM_UNIT_TEST_CASE_WITH_EXPECTATION(BitFields_Assert, DEBUG_CRASH) {
  using F = BitField<uint32_t, uint32_t, 0, 8, /*sign_extend=*/false>;
  const uint32_t value = F::encode(kMaxUint32);
  EXPECT_EQ(kMaxUint8, value);
}

}  // namespace dart

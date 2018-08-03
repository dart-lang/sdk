// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "vm/bitfield.h"
#include "vm/globals.h"
#include "vm/unit_test.h"

namespace dart {

VM_UNIT_TEST_CASE(BitFields) {
  class TestBitFields : public BitField<uword, int32_t, 1, 8> {};
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

}  // namespace dart

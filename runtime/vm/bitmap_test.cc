// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bitmap.h"

#include "platform/assert.h"
#include "vm/code_descriptors.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

// 0x4 is just a placeholder PC offset because no entry of a CSM should
// have a PC offset of 0, otherwise internal assumptions break.
static const uint32_t kTestPcOffset = 0x4;
static const intptr_t kTestSpillSlotBitCount = 0;

static CompressedStackMapsPtr MapsFromBuilder(Zone* zone, BitmapBuilder* bmap) {
  CompressedStackMapsBuilder builder(zone);
  builder.AddEntry(kTestPcOffset, bmap, kTestSpillSlotBitCount);
  return builder.Finalize();
}

ISOLATE_UNIT_TEST_CASE(BitmapBuilder) {
  // Test basic bit map builder operations.
  BitmapBuilder* builder1 = new BitmapBuilder();
  EXPECT_EQ(0, builder1->Length());

  bool value = true;
  for (int32_t i = 0; i < 128; i++) {
    builder1->Set(i, value);
    value = !value;
  }
  EXPECT_EQ(128, builder1->Length());
  value = true;
  for (int32_t i = 0; i < 128; i++) {
    EXPECT_EQ(value, builder1->Get(i));
    value = !value;
  }
  value = true;
  for (int32_t i = 0; i < 1024; i++) {
    builder1->Set(i, value);
    value = !value;
  }
  EXPECT_EQ(1024, builder1->Length());
  value = true;
  for (int32_t i = 0; i < 1024; i++) {
    EXPECT_EQ(value, builder1->Get(i));
    value = !value;
  }

  // Create a CompressedStackMaps object and verify its contents.
  const auto& maps1 = CompressedStackMaps::Handle(
      thread->zone(), MapsFromBuilder(thread->zone(), builder1));
  CompressedStackMaps::Iterator it1(thread, maps1);
  EXPECT(it1.MoveNext());

  EXPECT_EQ(kTestPcOffset, it1.pc_offset());
  EXPECT_EQ(kTestSpillSlotBitCount, it1.SpillSlotBitCount());
  EXPECT_EQ(1024, it1.Length());
  value = true;
  for (int32_t i = 0; i < 1024; i++) {
    EXPECT_EQ(value, it1.IsObject(i));
    value = !value;
  }

  EXPECT(!it1.MoveNext());

  // Test the SetRange function in the builder.
  builder1->SetRange(0, 256, false);
  EXPECT_EQ(1024, builder1->Length());
  builder1->SetRange(257, 1024, true);
  EXPECT_EQ(1025, builder1->Length());
  builder1->SetRange(1025, 2048, false);
  EXPECT_EQ(2049, builder1->Length());
  for (int32_t i = 0; i <= 256; i++) {
    EXPECT(!builder1->Get(i));
  }
  for (int32_t i = 257; i <= 1024; i++) {
    EXPECT(builder1->Get(i));
  }
  for (int32_t i = 1025; i <= 2048; i++) {
    EXPECT(!builder1->Get(i));
  }

  const auto& maps2 = CompressedStackMaps::Handle(
      thread->zone(), MapsFromBuilder(thread->zone(), builder1));
  CompressedStackMaps::Iterator it2(thread, maps2);
  EXPECT(it2.MoveNext());

  EXPECT_EQ(kTestPcOffset, it2.pc_offset());
  EXPECT_EQ(kTestSpillSlotBitCount, it2.SpillSlotBitCount());
  EXPECT_EQ(2049, it2.Length());
  for (int32_t i = 0; i <= 256; i++) {
    EXPECT(!it2.IsObject(i));
  }
  for (int32_t i = 257; i <= 1024; i++) {
    EXPECT(it2.IsObject(i));
  }
  for (int32_t i = 1025; i <= 2048; i++) {
    EXPECT(!it2.IsObject(i));
  }

  EXPECT(!it2.MoveNext());

  // Test using SetLength to shorten the builder, followed by lengthening.
  builder1->SetLength(747);
  EXPECT_EQ(747, builder1->Length());
  for (int32_t i = 257; i < 747; ++i) {
    EXPECT(builder1->Get(i));
  }

  builder1->Set(800, false);
  EXPECT_EQ(801, builder1->Length());
  for (int32_t i = 257; i < 747; ++i) {
    EXPECT(builder1->Get(i));
  }
  for (int32_t i = 747; i < 801; ++i) {
    EXPECT(!builder1->Get(i));
  }

  builder1->Set(900, true);
  EXPECT_EQ(901, builder1->Length());
  for (int32_t i = 257; i < 747; ++i) {
    EXPECT(builder1->Get(i));
  }
  for (int32_t i = 747; i < 900; ++i) {
    EXPECT(!builder1->Get(i));
  }
  EXPECT(builder1->Get(900));
}

}  // namespace dart

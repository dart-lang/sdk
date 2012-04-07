// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/bitmap.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(BitmapBuilder) {
  // Test basic bit map builder operations.
  BitmapBuilder* bmap1_builder = new BitmapBuilder();

  EXPECT_EQ(-1, bmap1_builder->Maximum());
  EXPECT_EQ(-1, bmap1_builder->Minimum());

  bool value = true;
  for (int32_t i = 0; i < 128; i++) {
    bmap1_builder->Set(i, value);
    value = !value;
  }
  value = true;
  for (int32_t i = 0; i < 128; i++) {
    EXPECT_EQ(value, bmap1_builder->Get(i));
    value = !value;
  }
  value = true;
  for (int32_t i = 0; i < 1024; i++) {
    bmap1_builder->Set(i, value);
    value = !value;
  }
  value = true;
  for (int32_t i = 0; i < 1024; i++) {
    EXPECT_EQ(value, bmap1_builder->Get(i));
    value = !value;
  }
  // Create a Bitmap object from the builder and verify it's contents.
  const Stackmap& bmap1 = Stackmap::Handle(
      Stackmap::New(0, Code::Handle(), bmap1_builder));
  EXPECT_EQ(1022, bmap1_builder->Maximum());
  EXPECT_EQ(0, bmap1_builder->Minimum());
  OS::Print("%s\n", bmap1.ToCString());
  value = true;
  for (int32_t i = 0; i < 1024; i++) {
    EXPECT_EQ(value, bmap1.IsObject(i));
    value = !value;
  }
  EXPECT(!bmap1.IsObject(2056));  // Out of range so returns false.

  // Test the SetRange function in the builder.
  bmap1_builder->SetRange(0, 256, false);
  bmap1_builder->SetRange(257, 1024, true);
  bmap1_builder->SetRange(1025, 2048, false);
  for (int32_t i = 0; i <= 256; i++) {
    EXPECT(!bmap1_builder->Get(i));
  }
  for (int32_t i = 257; i <= 1024; i++) {
    EXPECT(bmap1_builder->Get(i));
  }
  for (int32_t i = 1025; i <= 2048; i++) {
    EXPECT(!bmap1_builder->Get(i));
  }
  const Stackmap& bmap2 = Stackmap::Handle(
      Stackmap::New(0, Code::Handle(), bmap1_builder));
  EXPECT_EQ(1024, bmap1_builder->Maximum());
  EXPECT_EQ(257, bmap1_builder->Minimum());
  for (int32_t i = 0; i <= 256; i++) {
    EXPECT(!bmap2.IsObject(i));
  }
  for (int32_t i = 257; i <= 1024; i++) {
    EXPECT(bmap2.IsObject(i));
  }
  for (int32_t i = 1025; i <= 2048; i++) {
    EXPECT(!bmap2.IsObject(i));
  }

  // Test the functionality to copy a Stackmap object into a builder.
  BitmapBuilder* bmap2_builder = new BitmapBuilder();
  bmap2_builder->SetBits(bmap1);
  EXPECT_EQ(1022, bmap2_builder->Maximum());
  EXPECT_EQ(0, bmap2_builder->Minimum());
  value = true;
  for (int32_t i = 0; i < 1024; i++) {
    EXPECT_EQ(value, bmap2_builder->Get(i));
    value = !value;
  }

  BitmapBuilder* bmap3_builder = new BitmapBuilder();
  bmap3_builder->SetBits(bmap2);
  EXPECT_EQ(1024, bmap3_builder->Maximum());
  EXPECT_EQ(257, bmap3_builder->Minimum());
  for (int32_t i = 0; i <= 256; i++) {
    EXPECT(!bmap3_builder->Get(i));
  }
  for (int32_t i = 257; i <= 1024; i++) {
    EXPECT(bmap3_builder->Get(i));
  }
  for (int32_t i = 1025; i <= 2048; i++) {
    EXPECT(!bmap3_builder->Get(i));
  }
}

}  // namespace dart

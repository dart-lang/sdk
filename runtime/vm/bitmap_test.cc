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
  BitmapBuilder* builder1 = new BitmapBuilder();

  EXPECT_EQ(-1, builder1->Maximum());
  EXPECT_EQ(-1, builder1->Minimum());

  bool value = true;
  for (int32_t i = 0; i < 128; i++) {
    builder1->Set(i, value);
    value = !value;
  }
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
  value = true;
  for (int32_t i = 0; i < 1024; i++) {
    EXPECT_EQ(value, builder1->Get(i));
    value = !value;
  }
  // Create a Stackmap object from the builder and verify its contents.
  const Stackmap& stackmap1 =
      Stackmap::Handle(Stackmap::New(0, 1024, builder1));
  EXPECT_EQ(1022, builder1->Maximum());
  EXPECT_EQ(0, builder1->Minimum());
  OS::Print("%s\n", stackmap1.ToCString());
  value = true;
  for (int32_t i = 0; i < 1024; i++) {
    EXPECT_EQ(value, stackmap1.IsObject(i));
    value = !value;
  }
  EXPECT(!stackmap1.IsObject(2056));  // Out of range so returns false.

  // Test the SetRange function in the builder.
  builder1->SetRange(0, 256, false);
  builder1->SetRange(257, 1024, true);
  builder1->SetRange(1025, 2048, false);
  for (int32_t i = 0; i <= 256; i++) {
    EXPECT(!builder1->Get(i));
  }
  for (int32_t i = 257; i <= 1024; i++) {
    EXPECT(builder1->Get(i));
  }
  for (int32_t i = 1025; i <= 2048; i++) {
    EXPECT(!builder1->Get(i));
  }
  const Stackmap& stackmap2 =
      Stackmap::Handle(Stackmap::New(0, 2049, builder1));
  EXPECT_EQ(1024, builder1->Maximum());
  EXPECT_EQ(257, builder1->Minimum());
  for (int32_t i = 0; i <= 256; i++) {
    EXPECT(!stackmap2.IsObject(i));
  }
  for (int32_t i = 257; i <= 1024; i++) {
    EXPECT(stackmap2.IsObject(i));
  }
  for (int32_t i = 1025; i <= 2048; i++) {
    EXPECT(!stackmap2.IsObject(i));
  }

  // Test the functionality to copy a Stackmap object into a builder.
  BitmapBuilder* builder2 = new BitmapBuilder();
  builder2->SetBits(stackmap1);
  EXPECT_EQ(1022, builder2->Maximum());
  EXPECT_EQ(0, builder2->Minimum());
  value = true;
  for (int32_t i = 0; i < 1024; i++) {
    EXPECT_EQ(value, builder2->Get(i));
    value = !value;
  }

  BitmapBuilder* builder3 = new BitmapBuilder();
  builder3->SetBits(stackmap2);
  EXPECT_EQ(1024, builder3->Maximum());
  EXPECT_EQ(257, builder3->Minimum());
  for (int32_t i = 0; i <= 256; i++) {
    EXPECT(!builder3->Get(i));
  }
  for (int32_t i = 257; i <= 1024; i++) {
    EXPECT(builder3->Get(i));
  }
  for (int32_t i = 1025; i <= 2048; i++) {
    EXPECT(!builder3->Get(i));
  }
}

}  // namespace dart

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bitmap.h"
#include "platform/assert.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(BitmapBuilder) {
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
  // Create a StackMap object from the builder and verify its contents.
  const StackMap& stackmap1 = StackMap::Handle(StackMap::New(0, builder1, 0));
  EXPECT_EQ(1024, stackmap1.Length());
  OS::Print("%s\n", stackmap1.ToCString());
  value = true;
  for (int32_t i = 0; i < 1024; i++) {
    EXPECT_EQ(value, stackmap1.IsObject(i));
    value = !value;
  }

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
  const StackMap& stackmap2 = StackMap::Handle(StackMap::New(0, builder1, 0));
  EXPECT_EQ(2049, stackmap2.Length());
  for (int32_t i = 0; i <= 256; i++) {
    EXPECT(!stackmap2.IsObject(i));
  }
  for (int32_t i = 257; i <= 1024; i++) {
    EXPECT(stackmap2.IsObject(i));
  }
  for (int32_t i = 1025; i <= 2048; i++) {
    EXPECT(!stackmap2.IsObject(i));
  }

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

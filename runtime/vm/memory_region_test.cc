// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/memory_region.h"
#include "platform/assert.h"
#include "vm/unit_test.h"

namespace dart {

static void* NewRegion(uword size) {
  void* pointer = new uint8_t[size];
  return pointer;
}

static void DeleteRegion(const MemoryRegion& region) {
  delete[] reinterpret_cast<uint8_t*>(region.pointer());
}

VM_UNIT_TEST_CASE(NullRegion) {
  static const uword kSize = 512;
  MemoryRegion region(NULL, kSize);
  EXPECT(region.pointer() == NULL);
  EXPECT_EQ(kSize, region.size());
}

VM_UNIT_TEST_CASE(NewRegion) {
  static const uword kSize = 1024;
  MemoryRegion region(NewRegion(kSize), kSize);
  EXPECT_EQ(kSize, region.size());
  EXPECT(region.pointer() != NULL);

  region.Store<int32_t>(0, 42);
  EXPECT_EQ(42, region.Load<int32_t>(0));

  DeleteRegion(region);
}

VM_UNIT_TEST_CASE(Subregion) {
  static const uword kSize = 1024;
  static const uword kSubOffset = 128;
  static const uword kSubSize = 512;
  MemoryRegion region(NewRegion(kSize), kSize);
  MemoryRegion sub_region;
  sub_region.Subregion(region, kSubOffset, kSubSize);
  EXPECT_EQ(kSubSize, sub_region.size());
  EXPECT(sub_region.pointer() != NULL);
  EXPECT(sub_region.start() == region.start() + kSubOffset);

  region.Store<int32_t>(0, 42);
  sub_region.Store<int32_t>(0, 100);
  EXPECT_EQ(42, region.Load<int32_t>(0));
  EXPECT_EQ(100, region.Load<int32_t>(kSubOffset));

  DeleteRegion(region);
}

VM_UNIT_TEST_CASE(ExtendedRegion) {
  static const uword kSize = 1024;
  static const uword kSubSize = 512;
  static const uword kExtendSize = 512;
  MemoryRegion region(NewRegion(kSize), kSize);
  MemoryRegion sub_region;
  sub_region.Subregion(region, 0, kSubSize);
  MemoryRegion extended_region;
  extended_region.Extend(sub_region, kExtendSize);
  EXPECT_EQ(kSize, extended_region.size());
  EXPECT(extended_region.pointer() == region.pointer());
  EXPECT(extended_region.pointer() == sub_region.pointer());

  extended_region.Store<int32_t>(0, 42);
  EXPECT_EQ(42, extended_region.Load<int32_t>(0));

  DeleteRegion(region);
}

}  // namespace dart

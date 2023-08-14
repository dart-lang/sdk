// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/zone.h"
#include "platform/address_sanitizer.h"
#include "platform/assert.h"
#include "platform/memory_sanitizer.h"
#include "vm/dart.h"
#include "vm/isolate.h"
#include "vm/unit_test.h"

namespace dart {

VM_UNIT_TEST_CASE(AllocateZone) {
#if defined(DEBUG)
  FLAG_trace_zones = true;
#endif
  TestCase::CreateTestIsolate();
  Thread* thread = Thread::Current();
  EXPECT(thread->zone() == nullptr);
  {
    TransitionNativeToVM transition(thread);
    StackZone stack_zone(thread);
    EXPECT(thread->zone() != nullptr);
    Zone* zone = stack_zone.GetZone();
    uintptr_t allocated_size = 0;

    // The loop is to make sure we overflow one segment and go on
    // to the next segment.
    for (int i = 0; i < 1000; i++) {
      uword first = zone->AllocUnsafe(2 * kWordSize);
      uword second = zone->AllocUnsafe(3 * kWordSize);
      EXPECT(first != second);
      allocated_size = ((2 + 3) * kWordSize);
    }
    EXPECT_LE(allocated_size, zone->SizeInBytes());

    // Test for allocation of large segments.
    const uword kLargeSize = 1 * MB;
    const uword kSegmentSize = 64 * KB;
    ASSERT(kLargeSize > kSegmentSize);
    for (int i = 0; i < 10; i++) {
      EXPECT(zone->AllocUnsafe(kLargeSize) != 0);
      allocated_size += kLargeSize;
    }
    EXPECT_LE(allocated_size, zone->SizeInBytes());

    // Test corner cases of kSegmentSize.
    uint8_t* buffer = nullptr;
    buffer =
        reinterpret_cast<uint8_t*>(zone->AllocUnsafe(kSegmentSize - kWordSize));
    EXPECT(buffer != nullptr);
    buffer[(kSegmentSize - kWordSize) - 1] = 0;
    allocated_size += (kSegmentSize - kWordSize);
    EXPECT_LE(allocated_size, zone->SizeInBytes());

    buffer = reinterpret_cast<uint8_t*>(
        zone->AllocUnsafe(kSegmentSize - (2 * kWordSize)));
    EXPECT(buffer != nullptr);
    buffer[(kSegmentSize - (2 * kWordSize)) - 1] = 0;
    allocated_size += (kSegmentSize - (2 * kWordSize));
    EXPECT_LE(allocated_size, zone->SizeInBytes());

    buffer =
        reinterpret_cast<uint8_t*>(zone->AllocUnsafe(kSegmentSize + kWordSize));
    EXPECT(buffer != nullptr);
    buffer[(kSegmentSize + kWordSize) - 1] = 0;
    allocated_size += (kSegmentSize + kWordSize);
    EXPECT_LE(allocated_size, zone->SizeInBytes());
  }
  EXPECT(thread->zone() == nullptr);
  Dart_ShutdownIsolate();
}

VM_UNIT_TEST_CASE(AllocGeneric_Success) {
#if defined(DEBUG)
  FLAG_trace_zones = true;
#endif
  TestCase::CreateTestIsolate();
  Thread* thread = Thread::Current();
  EXPECT(thread->zone() == nullptr);
  {
    TransitionNativeToVM transition(thread);
    StackZone zone(thread);
    EXPECT(thread->zone() != nullptr);
    uintptr_t allocated_size = 0;

    const intptr_t kNumElements = 1000;
    zone.GetZone()->Alloc<uint32_t>(kNumElements);
    allocated_size += sizeof(uint32_t) * kNumElements;
    EXPECT_LE(allocated_size, zone.SizeInBytes());
  }
  EXPECT(thread->zone() == nullptr);
  Dart_ShutdownIsolate();
}

// This test is expected to crash.
VM_UNIT_TEST_CASE_WITH_EXPECTATION(AllocGeneric_Overflow, "Crash") {
#if defined(DEBUG)
  FLAG_trace_zones = true;
#endif
  TestCase::CreateTestIsolate();
  Thread* thread = Thread::Current();
  EXPECT(thread->zone() == nullptr);
  {
    StackZone zone(thread);
    EXPECT(thread->zone() != nullptr);

    const intptr_t kNumElements = (kIntptrMax / sizeof(uint32_t)) + 1;
    zone.GetZone()->Alloc<uint32_t>(kNumElements);
  }
  Dart_ShutdownIsolate();
}

VM_UNIT_TEST_CASE(ZoneRealloc) {
  TestCase::CreateTestIsolate();
  Thread* thread = Thread::Current();
  {
    TransitionNativeToVM transition(thread);
    StackZone stack_zone(thread);
    auto zone = thread->zone();

    const intptr_t kOldLen = 32;
    const intptr_t kNewLen = 16;
    const intptr_t kNewLen2 = 16;

    auto data_old = zone->Alloc<uint8_t>(kOldLen);
    auto data_new = zone->Realloc<uint8_t>(data_old, kOldLen, kNewLen);
    RELEASE_ASSERT(data_old == data_new);

    auto data_new2 = zone->Realloc<uint8_t>(data_old, kNewLen, kNewLen2);
    RELEASE_ASSERT(data_old == data_new2);
  }
  Dart_ShutdownIsolate();
}

VM_UNIT_TEST_CASE(ZoneAllocated) {
#if defined(DEBUG)
  FLAG_trace_zones = true;
#endif
  TestCase::CreateTestIsolate();
  Thread* thread = Thread::Current();
  EXPECT(thread->zone() == nullptr);
  static int marker;

  class SimpleZoneObject : public ZoneAllocated {
   public:
    SimpleZoneObject() : slot(marker++) {}
    virtual ~SimpleZoneObject() {}
    virtual int GetSlot() { return slot; }
    int slot;
  };

  // Reset the marker.
  marker = 0;

  // Create a few zone allocated objects.
  {
    TransitionNativeToVM transition(thread);
    StackZone zone(thread);
    EXPECT_EQ(0UL, zone.SizeInBytes());
    SimpleZoneObject* first = new SimpleZoneObject();
    EXPECT(first != nullptr);
    SimpleZoneObject* second = new SimpleZoneObject();
    EXPECT(second != nullptr);
    EXPECT(first != second);
    uintptr_t expected_size = (2 * sizeof(SimpleZoneObject));
    EXPECT_LE(expected_size, zone.SizeInBytes());

    // Make sure the constructors were invoked.
    EXPECT_EQ(0, first->slot);
    EXPECT_EQ(1, second->slot);

    // Make sure we can write to the members of the zone objects.
    first->slot = 42;
    second->slot = 87;
    EXPECT_EQ(42, first->slot);
    EXPECT_EQ(87, second->slot);
  }
  EXPECT(thread->zone() == nullptr);
  Dart_ShutdownIsolate();
}

TEST_CASE(PrintToString) {
  TransitionNativeToVM transition(Thread::Current());
  StackZone zone(Thread::Current());
  const char* result = zone.GetZone()->PrintToString("Hello %s!", "World");
  EXPECT_STREQ("Hello World!", result);
}

#if !defined(PRODUCT) && !defined(USING_ADDRESS_SANITIZER) &&                  \
    !defined(USING_MEMORY_SANITIZER)
// RSS hooks absent in PRODUCT mode. Scudo quarantine interferes RSS
// measurements under the sanitizers. Slack to allow for limited pooling
// in the malloc implementation.
static constexpr int64_t kRssSlack = 20 * MB;
#define CHECK_RSS
#endif

// clang-format off
static const size_t kSizes[] = {
  64 * KB,
  64 * KB + 2 * kWordSize,
  64 * KB - 2 * kWordSize,
  128 * KB,
  128 * KB + 2 * kWordSize,
  128 * KB - 2 * kWordSize,
  256 * KB,
  256 * KB + 2 * kWordSize,
  256 * KB - 2 * kWordSize,
  512 * KB,
  512 * KB + 2 * kWordSize,
  512 * KB - 2 * kWordSize,
};
// clang-format on

TEST_CASE(StressMallocDirectly) {
#if defined(CHECK_RSS)
  int64_t start_rss = Service::CurrentRSS();
#endif

  void* allocations[ARRAY_SIZE(kSizes)];
  for (size_t i = 0; i < ((3u * GB) / (512u * KB)); i++) {
    for (size_t j = 0; j < ARRAY_SIZE(kSizes); j++) {
      allocations[j] = malloc(kSizes[j]);
    }
    for (size_t j = 0; j < ARRAY_SIZE(kSizes); j++) {
      free(allocations[j]);
    }
  }

#if defined(CHECK_RSS)
  int64_t stop_rss = Service::CurrentRSS();
  EXPECT_LT(stop_rss, start_rss + kRssSlack);
#endif
}

ISOLATE_UNIT_TEST_CASE(StressMallocThroughZones) {
#if defined(CHECK_RSS)
  int64_t start_rss = Service::CurrentRSS();
#endif

  for (size_t i = 0; i < ((3u * GB) / (512u * KB)); i++) {
    StackZone stack_zone(Thread::Current());
    Zone* zone = stack_zone.GetZone();
    for (size_t j = 0; j < ARRAY_SIZE(kSizes); j++) {
      zone->Alloc<uint8_t>(kSizes[j]);
    }
  }

#if defined(CHECK_RSS)
  int64_t stop_rss = Service::CurrentRSS();
  EXPECT_LT(stop_rss, start_rss + kRssSlack);
#endif
}

#if defined(DART_COMPRESSED_POINTERS)
ISOLATE_UNIT_TEST_CASE(ZonesNotLimitedByCompressedHeap) {
  StackZone stack_zone(Thread::Current());
  Zone* zone = stack_zone.GetZone();

  size_t total = 0;
  while (total <= (4u * GB)) {
    size_t chunk_size = 512u * MB;
    zone->AllocUnsafe(chunk_size);
    total += chunk_size;
  }
}
#endif  // defined(DART_COMPRESSED_POINTERS)

ISOLATE_UNIT_TEST_CASE(ZoneVerificationScaling) {
  // This ought to complete in O(n), not O(n^2).
  const intptr_t n = 1000000;

  StackZone stack_zone(thread);
  Zone* zone = stack_zone.GetZone();

  {
    HANDLESCOPE(thread);
    for (intptr_t i = 0; i < n; i++) {
      const Object& a = Object::Handle(zone);
      DEBUG_ASSERT(!a.IsNotTemporaryScopedHandle());
      USE(a);
      const Object& b = Object::ZoneHandle(zone);
      DEBUG_ASSERT(b.IsNotTemporaryScopedHandle());
      USE(b);
    }
    // Leaves lots of HandleBlocks for recycling.
  }

  for (intptr_t i = 0; i < n; i++) {
    HANDLESCOPE(thread);
    const Object& a = Object::Handle(zone);
    DEBUG_ASSERT(!a.IsNotTemporaryScopedHandle());
    USE(a);
    const Object& b = Object::ZoneHandle(zone);
    DEBUG_ASSERT(b.IsNotTemporaryScopedHandle());
    USE(b);
    // Should not visit those recyclable blocks over and over again.
  }
}

}  // namespace dart

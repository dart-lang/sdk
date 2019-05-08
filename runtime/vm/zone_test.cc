// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/zone.h"
#include "platform/assert.h"
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
  EXPECT(thread->zone() == NULL);
  {
    TransitionNativeToVM transition(thread);
    StackZone stack_zone(thread);
    EXPECT(thread->zone() != NULL);
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
    uint8_t* buffer = NULL;
    buffer =
        reinterpret_cast<uint8_t*>(zone->AllocUnsafe(kSegmentSize - kWordSize));
    EXPECT(buffer != NULL);
    buffer[(kSegmentSize - kWordSize) - 1] = 0;
    allocated_size += (kSegmentSize - kWordSize);
    EXPECT_LE(allocated_size, zone->SizeInBytes());

    buffer = reinterpret_cast<uint8_t*>(
        zone->AllocUnsafe(kSegmentSize - (2 * kWordSize)));
    EXPECT(buffer != NULL);
    buffer[(kSegmentSize - (2 * kWordSize)) - 1] = 0;
    allocated_size += (kSegmentSize - (2 * kWordSize));
    EXPECT_LE(allocated_size, zone->SizeInBytes());

    buffer =
        reinterpret_cast<uint8_t*>(zone->AllocUnsafe(kSegmentSize + kWordSize));
    EXPECT(buffer != NULL);
    buffer[(kSegmentSize + kWordSize) - 1] = 0;
    allocated_size += (kSegmentSize + kWordSize);
    EXPECT_LE(allocated_size, zone->SizeInBytes());
  }
  EXPECT(thread->zone() == NULL);
  Dart_ShutdownIsolate();
}

VM_UNIT_TEST_CASE(AllocGeneric_Success) {
#if defined(DEBUG)
  FLAG_trace_zones = true;
#endif
  TestCase::CreateTestIsolate();
  Thread* thread = Thread::Current();
  EXPECT(thread->zone() == NULL);
  {
    TransitionNativeToVM transition(thread);
    StackZone zone(thread);
    EXPECT(thread->zone() != NULL);
    uintptr_t allocated_size = 0;

    const intptr_t kNumElements = 1000;
    zone.GetZone()->Alloc<uint32_t>(kNumElements);
    allocated_size += sizeof(uint32_t) * kNumElements;
    EXPECT_LE(allocated_size, zone.SizeInBytes());
  }
  EXPECT(thread->zone() == NULL);
  Dart_ShutdownIsolate();
}

// This test is expected to crash.
VM_UNIT_TEST_CASE_WITH_EXPECTATION(AllocGeneric_Overflow, "Crash") {
#if defined(DEBUG)
  FLAG_trace_zones = true;
#endif
  TestCase::CreateTestIsolate();
  Thread* thread = Thread::Current();
  EXPECT(thread->zone() == NULL);
  {
    StackZone zone(thread);
    EXPECT(thread->zone() != NULL);

    const intptr_t kNumElements = (kIntptrMax / sizeof(uint32_t)) + 1;
    zone.GetZone()->Alloc<uint32_t>(kNumElements);
  }
  Dart_ShutdownIsolate();
}

VM_UNIT_TEST_CASE(ZoneAllocated) {
#if defined(DEBUG)
  FLAG_trace_zones = true;
#endif
  TestCase::CreateTestIsolate();
  Thread* thread = Thread::Current();
  EXPECT(thread->zone() == NULL);
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
    EXPECT(first != NULL);
    SimpleZoneObject* second = new SimpleZoneObject();
    EXPECT(second != NULL);
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
  EXPECT(thread->zone() == NULL);
  Dart_ShutdownIsolate();
}

TEST_CASE(PrintToString) {
  TransitionNativeToVM transition(Thread::Current());
  StackZone zone(Thread::Current());
  const char* result = zone.GetZone()->PrintToString("Hello %s!", "World");
  EXPECT_STREQ("Hello World!", result);
}

VM_UNIT_TEST_CASE(NativeScopeZoneAllocation) {
  ASSERT(ApiNativeScope::Current() == NULL);
  ASSERT(Thread::Current() == NULL);
  EXPECT_EQ(0UL, ApiNativeScope::current_memory_usage());
  {
    ApiNativeScope scope;
    EXPECT_EQ(scope.zone()->CapacityInBytes(),
              ApiNativeScope::current_memory_usage());
    (void)Dart_ScopeAllocate(2048);
    EXPECT_EQ(scope.zone()->CapacityInBytes(),
              ApiNativeScope::current_memory_usage());
  }
  EXPECT_EQ(0UL, ApiNativeScope::current_memory_usage());
}

#if !defined(PRODUCT)
// Allow for pooling in the malloc implementation.
static const int64_t kRssSlack = 20 * MB;
#endif  // !defined(PRODUCT)

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
#if !defined(PRODUCT)
  int64_t start_rss = Service::CurrentRSS();
#endif  // !defined(PRODUCT)

  void* allocations[ARRAY_SIZE(kSizes)];
  for (size_t i = 0; i < ((3u * GB) / (512u * KB)); i++) {
    for (size_t j = 0; j < ARRAY_SIZE(kSizes); j++) {
      allocations[j] = malloc(kSizes[j]);
    }
    for (size_t j = 0; j < ARRAY_SIZE(kSizes); j++) {
      free(allocations[j]);
    }
  }

#if !defined(PRODUCT)
  int64_t stop_rss = Service::CurrentRSS();
  EXPECT_LT(stop_rss, start_rss + kRssSlack);
#endif  // !defined(PRODUCT)
}

ISOLATE_UNIT_TEST_CASE(StressMallocThroughZones) {
#if !defined(PRODUCT)
  int64_t start_rss = Service::CurrentRSS();
#endif  // !defined(PRODUCT)

  for (size_t i = 0; i < ((3u * GB) / (512u * KB)); i++) {
    StackZone stack_zone(Thread::Current());
    Zone* zone = stack_zone.GetZone();
    for (size_t j = 0; j < ARRAY_SIZE(kSizes); j++) {
      zone->Alloc<uint8_t>(kSizes[j]);
    }
  }

#if !defined(PRODUCT)
  int64_t stop_rss = Service::CurrentRSS();
  EXPECT_LT(stop_rss, start_rss + kRssSlack);
#endif  // !defined(PRODUCT)
}

}  // namespace dart

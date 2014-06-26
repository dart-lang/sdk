// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/dart.h"
#include "vm/isolate.h"
#include "vm/unit_test.h"
#include "vm/zone.h"

namespace dart {

DECLARE_DEBUG_FLAG(bool, trace_zones);

UNIT_TEST_CASE(AllocateZone) {
#if defined(DEBUG)
  FLAG_trace_zones = true;
#endif
  Isolate* isolate = Isolate::Init(NULL);
  EXPECT(Isolate::Current() == isolate);
  EXPECT(isolate->current_zone() == NULL);
  {
    StackZone stack_zone(isolate);
    EXPECT(isolate->current_zone() != NULL);
    Zone* zone = stack_zone.GetZone();
    intptr_t allocated_size = 0;

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
    buffer = reinterpret_cast<uint8_t*>(
        zone->AllocUnsafe(kSegmentSize - kWordSize));
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

    buffer = reinterpret_cast<uint8_t*>(
        zone->AllocUnsafe(kSegmentSize + kWordSize));
    EXPECT(buffer != NULL);
    buffer[(kSegmentSize + kWordSize) - 1] = 0;
    allocated_size += (kSegmentSize + kWordSize);
    EXPECT_LE(allocated_size, zone->SizeInBytes());
  }
  EXPECT(isolate->current_zone() == NULL);
  isolate->Shutdown();
  delete isolate;
}


UNIT_TEST_CASE(AllocGeneric_Success) {
#if defined(DEBUG)
  FLAG_trace_zones = true;
#endif
  Isolate* isolate = Isolate::Init(NULL);
  EXPECT(Isolate::Current() == isolate);
  EXPECT(isolate->current_zone() == NULL);
  {
    StackZone zone(isolate);
    EXPECT(isolate->current_zone() != NULL);
    intptr_t allocated_size = 0;

    const intptr_t kNumElements = 1000;
    zone.GetZone()->Alloc<uint32_t>(kNumElements);
    allocated_size += sizeof(uint32_t) * kNumElements;
    EXPECT_LE(allocated_size, zone.SizeInBytes());
  }
  EXPECT(isolate->current_zone() == NULL);
  isolate->Shutdown();
  delete isolate;
}


// This test is expected to crash.
UNIT_TEST_CASE(AllocGeneric_Overflow) {
#if defined(DEBUG)
  FLAG_trace_zones = true;
#endif
  Isolate* isolate = Isolate::Init(NULL);
  EXPECT(Isolate::Current() == isolate);
  EXPECT(isolate->current_zone() == NULL);
  {
    StackZone zone(isolate);
    EXPECT(isolate->current_zone() != NULL);

    const intptr_t kNumElements = (kIntptrMax / sizeof(uint32_t)) + 1;
    zone.GetZone()->Alloc<uint32_t>(kNumElements);
  }
  isolate->Shutdown();
  delete isolate;
}


UNIT_TEST_CASE(ZoneAllocated) {
#if defined(DEBUG)
  FLAG_trace_zones = true;
#endif
  Isolate* isolate = Isolate::Init(NULL);
  EXPECT(Isolate::Current() == isolate);
  EXPECT(isolate->current_zone() == NULL);
  static int marker;

  class SimpleZoneObject : public ZoneAllocated {
   public:
    SimpleZoneObject() : slot(marker++) { }
    virtual ~SimpleZoneObject() { }
    virtual int GetSlot() { return slot; }
    int slot;
  };

  // Reset the marker.
  marker = 0;

  // Create a few zone allocated objects.
  {
    StackZone zone(isolate);
    EXPECT_EQ(0, zone.SizeInBytes());
    SimpleZoneObject* first = new SimpleZoneObject();
    EXPECT(first != NULL);
    SimpleZoneObject* second = new SimpleZoneObject();
    EXPECT(second != NULL);
    EXPECT(first != second);
    intptr_t expected_size = (2 * sizeof(SimpleZoneObject));
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
  EXPECT(isolate->current_zone() == NULL);
  isolate->Shutdown();
  delete isolate;
}


TEST_CASE(PrintToString) {
  StackZone zone(Isolate::Current());
  const char* result = zone.GetZone()->PrintToString("Hello %s!", "World");
  EXPECT_STREQ("Hello World!", result);
}

}  // namespace dart

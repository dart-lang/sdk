// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/assert.h"
#include "vm/flags.h"
#include "vm/handles.h"
#include "vm/heap.h"
#include "vm/object.h"
#include "vm/unit_test.h"
#include "vm/zone.h"

namespace dart {

DECLARE_DEBUG_FLAG(bool, trace_handles_count);


// Unit test for Zone handle allocation.
TEST_CASE(AllocateZoneHandle) {
#if defined(DEBUG)
  FLAG_trace_handles_count = true;
#endif
  // The previously run stub code generation may have created zone handles.
  int initial_count = VMHandles::ZoneHandleCount();
  static const int kNumHandles = 65;
  // Create some zone handles.
  for (int i = 0; i < kNumHandles; i++) {
    const Smi& handle = Smi::ZoneHandle(Smi::New(i));
    EXPECT(handle.IsSmi());
    EXPECT_EQ(i, handle.Value());
  }
  EXPECT_EQ(kNumHandles + initial_count, VMHandles::ZoneHandleCount());
  // Create some more zone handles.
  for (int i = kNumHandles; i < (2 * kNumHandles); i++) {
    const Smi& handle = Smi::ZoneHandle(Smi::New(i));
    EXPECT(handle.IsSmi());
    EXPECT_EQ(i, handle.Value());
  }
  EXPECT_EQ((2 * kNumHandles) + initial_count, VMHandles::ZoneHandleCount());
}


// Unit test for Scope handle allocation.
TEST_CASE(AllocateScopeHandle) {
#if defined(DEBUG)
  FLAG_trace_handles_count = true;
#endif
  int32_t handle_count = VMHandles::ScopedHandleCount();
  static const int kNumHandles = 65;
  // Create some scoped handles.
  {
    Isolate* isolate = Isolate::Current();
    HANDLESCOPE(isolate);
    for (int i = 0; i < kNumHandles; i++) {
      const Smi& handle = Smi::Handle(Smi::New(i));
      EXPECT(handle.IsSmi());
      EXPECT_EQ(i, handle.Value());
    }
    EXPECT_EQ((handle_count + kNumHandles), VMHandles::ScopedHandleCount());
    // Create lots of scoped handles in a loop with a nested scope.
    for (int loop = 0; loop < 1000; loop++) {
      HANDLESCOPE(isolate);
      for (int i = 0; i < 2; i++) {
        const Smi& handle = Smi::Handle(Smi::New(i + loop));
        EXPECT(handle.IsSmi());
        EXPECT_EQ(i + loop, handle.Value());
      }
      EXPECT_EQ((handle_count + kNumHandles + 2),
                VMHandles::ScopedHandleCount());
    }
    EXPECT_EQ((handle_count + kNumHandles), VMHandles::ScopedHandleCount());
    for (int i = 0; i < kNumHandles; i++) {
      const Smi& handle = Smi::Handle(Smi::New(i));
      EXPECT(handle.IsSmi());
      EXPECT_EQ(i, handle.Value());
    }
    EXPECT_EQ((handle_count + (2 * kNumHandles)),
              VMHandles::ScopedHandleCount());
  }
  EXPECT_EQ(handle_count, VMHandles::ScopedHandleCount());
}

}  // namespace dart

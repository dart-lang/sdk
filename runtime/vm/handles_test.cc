// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/handles.h"
#include "platform/assert.h"
#include "vm/dart_api_state.h"
#include "vm/flags.h"
#include "vm/heap.h"
#include "vm/object.h"
#include "vm/unit_test.h"
#include "vm/zone.h"

namespace dart {

// Unit test for Zone handle allocation.
TEST_CASE(AllocateZoneHandle) {
#if defined(DEBUG)
  FLAG_trace_handles = true;
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
  FLAG_trace_handles = true;
#endif
  int32_t handle_count = VMHandles::ScopedHandleCount();
  static const int kNumHandles = 65;
  // Create some scoped handles.
  {
    Thread* thread = Thread::Current();
    HANDLESCOPE(thread);
    for (int i = 0; i < kNumHandles; i++) {
      const Smi& handle = Smi::Handle(Smi::New(i));
      EXPECT(handle.IsSmi());
      EXPECT_EQ(i, handle.Value());
    }
    EXPECT_EQ((handle_count + kNumHandles), VMHandles::ScopedHandleCount());
    // Create lots of scoped handles in a loop with a nested scope.
    for (int loop = 0; loop < 1000; loop++) {
      HANDLESCOPE(thread);
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

static void NoopCallback(void* isolate_callback_data,
                         Dart_WeakPersistentHandle handle,
                         void* peer) {}

// Unit test for handle validity checks.
TEST_CASE(CheckHandleValidity) {
#if defined(DEBUG)
  FLAG_trace_handles = true;
#endif
  Thread* current = Thread::Current();
  Dart_Handle handle = NULL;
  // Check validity using zone handles.
  {
    StackZone sz(current);
    handle = reinterpret_cast<Dart_Handle>(&Smi::ZoneHandle(Smi::New(1)));
    EXPECT_VALID(handle);
  }
  EXPECT(!Api::IsValid(handle));

  // Check validity using scoped handles.
  {
    HANDLESCOPE(current);
    Dart_EnterScope();
    handle = reinterpret_cast<Dart_Handle>(&Smi::Handle(Smi::New(1)));
    EXPECT_VALID(handle);
    Dart_ExitScope();
  }
  EXPECT(!Api::IsValid(handle));

  // Check validity using persistent handle.
  Isolate* isolate = Isolate::Current();
  Dart_PersistentHandle persistent_handle =
      Dart_NewPersistentHandle(Api::NewHandle(thread, Smi::New(1)));
  EXPECT_VALID(persistent_handle);

  Dart_DeletePersistentHandle(persistent_handle);
  EXPECT(!Api::IsValid(persistent_handle));

  // Check validity using weak persistent handle.
  handle = reinterpret_cast<Dart_Handle>(Dart_NewWeakPersistentHandle(
      Dart_NewStringFromCString("foo"), NULL, 0, NoopCallback));

  EXPECT_NOTNULL(handle);
  EXPECT_VALID(handle);

  Dart_DeleteWeakPersistentHandle(
      reinterpret_cast<Dart_Isolate>(isolate),
      reinterpret_cast<Dart_WeakPersistentHandle>(handle));
  EXPECT(!Api::IsValid(handle));
}

}  // namespace dart

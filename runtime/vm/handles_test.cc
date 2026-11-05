// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/handles.h"
#include "platform/assert.h"
#include "vm/class_finalizer.h"
#include "vm/dart_api_state.h"
#include "vm/flags.h"
#include "vm/object.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"
#include "vm/zone.h"

namespace dart {

// Unit test for Zone handle allocation.
ISOLATE_UNIT_TEST_CASE(AllocateZoneHandle) {
#if defined(DEBUG)
  FLAG_trace_handles = true;
#endif
  // The previously run stub code generation may have created zone handles.
  int initial_count = VMHandles::ZoneHandleCount();
  const int kNumHandles = 65;
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
ISOLATE_UNIT_TEST_CASE(AllocateScopeHandle) {
#if defined(DEBUG)
  FLAG_trace_handles = true;
#endif
  int32_t handle_count = VMHandles::ScopedHandleCount();
  const int kNumHandles = 65;
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

static void NoopCallback(void* isolate_callback_data, void* peer) {}

// Unit test for handle validity checks.
TEST_CASE(CheckHandleValidity) {
#if defined(DEBUG)
  FLAG_trace_handles = true;
#endif
  Dart_Handle handle = nullptr;
  // Check validity using zone handles.
  {
    TransitionNativeToVM transition(thread);
    StackZone sz(thread);
    handle = reinterpret_cast<Dart_Handle>(&Smi::ZoneHandle(Smi::New(1)));
    {
      TransitionVMToNative to_native(thread);
      EXPECT_VALID(handle);
    }
  }
  EXPECT(!Api::IsValid(handle));

  // Check validity using scoped handles.
  {
    Dart_EnterScope();
    {
      TransitionNativeToVM transition(thread);
      HANDLESCOPE(thread);
      handle = reinterpret_cast<Dart_Handle>(&Smi::Handle(Smi::New(1)));
      {
        TransitionVMToNative to_native(thread);
        EXPECT_VALID(handle);
      }
    }
    Dart_ExitScope();
  }
  EXPECT(!Api::IsValid(handle));

  // Check validity using persistent handle.
  Dart_Handle scoped_handle;
  {
    TransitionNativeToVM transition(thread);
    scoped_handle = Api::NewHandle(thread, Smi::New(1));
  }
  Dart_PersistentHandle persistent_handle =
      Dart_NewPersistentHandle(scoped_handle);
  EXPECT_VALID(persistent_handle);

  Dart_DeletePersistentHandle(persistent_handle);
  EXPECT(!Api::IsValid(persistent_handle));

  // Check validity using weak persistent handle.
  handle = reinterpret_cast<Dart_Handle>(Dart_NewWeakPersistentHandle(
      Dart_NewStringFromCString("foo"), nullptr, 0, NoopCallback));

  EXPECT_NOTNULL(handle);
  EXPECT_VALID(handle);

  Dart_DeleteWeakPersistentHandle(
      reinterpret_cast<Dart_WeakPersistentHandle>(handle));
  EXPECT(!Api::IsValid(handle));
}

TEST_CASE(FieldScriptHandleAllocation) {
  const char* kScriptChars =
      "class Foo {\n"
      "  var field1;\n"
      "  var field2 = 123;\n"
      "  void bar() {}\n"
      "}\n";
  Dart_Handle lib_handle = TestCase::LoadTestScript(kScriptChars, nullptr);
  EXPECT_VALID(lib_handle);

  TransitionNativeToVM transition(thread);
  EXPECT(ClassFinalizer::ProcessPendingClasses());
  const Library& lib =
      Library::Handle(Library::RawCast(Api::UnwrapHandle(lib_handle)));
  EXPECT(!lib.IsNull());
  const Class& cls = Class::Handle(
      lib.LookupClass(String::Handle(Symbols::New(thread, "Foo"))));
  EXPECT(!cls.IsNull());
  const auto& error = cls.EnsureIsFinalized(thread);
  EXPECT(error == Error::null());
  const Array& fields = Array::Handle(cls.fields());
  EXPECT_GT(fields.Length(), 0);
  Field& field = Field::Handle();
  field ^= fields.At(0);

  int32_t handle_count = VMHandles::ScopedHandleCount();
  for (int i = 0; i < 100; i++) {
    field.Script();
  }
  // Field::Script() should not allocate scoped handles.
  EXPECT_EQ(handle_count, VMHandles::ScopedHandleCount());
}

TEST_CASE(FunctionScriptHandleAllocation) {
  const char* kScriptChars =
      "class Foo {\n"
      "  void bar() {}\n"
      "}\n";
  Dart_Handle lib_handle = TestCase::LoadTestScript(kScriptChars, nullptr);
  EXPECT_VALID(lib_handle);

  TransitionNativeToVM transition(thread);
  EXPECT(ClassFinalizer::ProcessPendingClasses());
  const Library& lib =
      Library::Handle(Library::RawCast(Api::UnwrapHandle(lib_handle)));
  EXPECT(!lib.IsNull());
  const Class& cls = Class::Handle(
      lib.LookupClass(String::Handle(Symbols::New(thread, "Foo"))));
  EXPECT(!cls.IsNull());
  const auto& error = cls.EnsureIsFinalized(thread);
  EXPECT(error == Error::null());
  const Array& functions = Array::Handle(cls.current_functions());
  EXPECT_GT(functions.Length(), 0);
  Function& function = Function::Handle();
  function ^= functions.At(0);

  int32_t handle_count = VMHandles::ScopedHandleCount();
  for (int i = 0; i < 100; i++) {
    function.script();
  }
  // Function::script() should not allocate scoped handles.
  EXPECT_EQ(handle_count, VMHandles::ScopedHandleCount());
}

}  // namespace dart

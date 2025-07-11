// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_STUB_CODE_H_
#define RUNTIME_VM_STUB_CODE_H_

#include <functional>

#include "vm/allocation.h"
#include "vm/compiler/runtime_api.h"
#include "vm/object.h"
#include "vm/stub_code_list.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/stub_code_compiler.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

// Forward declarations.
class Code;
class Isolate;
class ObjectPointerVisitor;

// Is it permitted for the stubs above to refer to Object::null(), which is
// allocated in the VM isolate and shared across all isolates.
// However, in cases where a simple GC-safe placeholder is needed on the stack,
// using Smi 0 instead of Object::null() is slightly more efficient, since a Smi
// does not require relocation.

// class StubCode is used to maintain the lifecycle of stubs.
class StubCode : public AllStatic {
 public:
  // Generate all stubs which are shared across all isolates, this is done
  // only once and the stub code resides in the vm_isolate heap.
  static void Init();

  static void Cleanup();

  // Returns true if stub code has been initialized.
  static bool HasBeenInitialized() {
    return initialized_.load(std::memory_order_acquire);
  }
  static void InitializationDone() {
    initialized_.store(true, std::memory_order_release);
  }

  // Check if specified pc is in the dart invocation stub used for
  // transitioning into dart code.
  static bool InInvocationStub(uword pc, bool is_interpreted_frame = false);

  // Check if the specified pc is in the jump to frame stub.
  static bool InJumpToFrameStub(uword pc);

  // Returns nullptr if no stub found.
  static const char* NameOfStub(uword entry_point);

  // Callback is called for each stub until it returns false.
  static void ForEachStub(
      const std::function<bool(const char*, uword)>& callback);

// Define the shared stub code accessors.
#define STUB_CODE_ACCESSOR(name)                                               \
  static const Code& name() { return *entries_[k##name##Index].code; }         \
  static intptr_t name##Size() { return name().Size(); }
  VM_STUB_CODE_LIST(STUB_CODE_ACCESSOR);
#undef STUB_CODE_ACCESSOR

#if !defined(DART_PRECOMPILED_RUNTIME)
  static const Code& SubtypeTestCacheStubForUsedInputs(intptr_t i) {
    switch (i) {
      case 1:
        return StubCode::Subtype1TestCache();
      case 2:
        return StubCode::Subtype2TestCache();
      case 3:
        return StubCode::Subtype3TestCache();
      case 4:
        return StubCode::Subtype4TestCache();
      case 6:
        return StubCode::Subtype6TestCache();
      case 7:
        return StubCode::Subtype7TestCache();
      default:
        UNREACHABLE();
        return StubCode::Subtype7TestCache();
    }
  }
  static CodePtr GetAllocationStubForClass(const Class& cls);
  static CodePtr GetAllocationStubForTypedData(classid_t class_id);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#if !defined(DART_PRECOMPILED_RUNTIME)
  // Generate the stub and finalize the generated code into the stub
  // code executable area.
  static CodePtr Generate(const char* name,
                          compiler::ObjectPoolBuilder* object_pool_builder,
                          void (compiler::StubCodeCompiler::*GenerateStub)());
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  static const Code& UnoptimizedStaticCallEntry(intptr_t num_args_tested);

  static const char* NameAt(intptr_t index) { return entries_[index].name; }

  static const Code& EntryAt(intptr_t index) { return *(entries_[index].code); }
  static void EntryAtPut(intptr_t index, Code* entry) {
    DEBUG_ASSERT(entry->IsReadOnlyHandle());
    ASSERT(entries_[index].code == nullptr);
    entries_[index].code = entry;
  }
  static intptr_t NumEntries() { return kNumStubEntries; }

#if !defined(DART_PRECOMPILED_RUNTIME)
#define GENERATE_STUB(name)                                                    \
  static CodePtr BuildIsolateSpecific##name##Stub(                             \
      compiler::ObjectPoolBuilder* opw) {                                      \
    return StubCode::Generate(                                                 \
        "_iso_stub_" #name, opw,                                               \
        &compiler::StubCodeCompiler::Generate##name##Stub);                    \
  }
  VM_STUB_CODE_LIST(GENERATE_STUB);
#undef GENERATE_STUB
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

 private:
  friend class MegamorphicCacheTable;

  enum {
#define STUB_CODE_ENTRY(name) k##name##Index,
    VM_STUB_CODE_LIST(STUB_CODE_ENTRY)
#undef STUB_CODE_ENTRY
        kNumStubEntries
  };

  struct StubCodeEntry {
    Code* code;
    const char* name;
#if !defined(DART_PRECOMPILED_RUNTIME)
    void (compiler::StubCodeCompiler::*generator)();
#endif
  };
  static StubCodeEntry entries_[kNumStubEntries];
  static AcqRelAtomic<bool> initialized_;
};

}  // namespace dart

#endif  // RUNTIME_VM_STUB_CODE_H_

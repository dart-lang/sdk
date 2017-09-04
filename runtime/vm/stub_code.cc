// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/stub_code.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/assembler.h"
#include "vm/clustered_snapshot.h"
#include "vm/disassembler.h"
#include "vm/flags.h"
#include "vm/object_store.h"
#include "vm/safepoint.h"
#include "vm/snapshot.h"
#include "vm/virtual_memory.h"
#include "vm/visitor.h"

namespace dart {

DEFINE_FLAG(bool, disassemble_stubs, false, "Disassemble generated stubs.");

StubEntry* StubCode::entries_[kNumStubEntries] = {
#define STUB_CODE_DECLARE(name) NULL,
    VM_STUB_CODE_LIST(STUB_CODE_DECLARE)
#undef STUB_CODE_DECLARE
};

StubEntry::StubEntry(const Code& code)
    : code_(code.raw()),
      entry_point_(code.UncheckedEntryPoint()),
      checked_entry_point_(code.CheckedEntryPoint()),
      size_(code.Size()),
      label_(code.UncheckedEntryPoint()) {}

// Visit all object pointers.
void StubEntry::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&code_));
}

#if defined(DART_PRECOMPILED_RUNTIME)
void StubCode::InitOnce() {
  // Stubs will be loaded from the snapshot.
  UNREACHABLE();
}
#else

#define STUB_CODE_GENERATE(name)                                               \
  code ^= Generate("_stub_" #name, StubCode::Generate##name##Stub);            \
  entries_[k##name##Index] = new StubEntry(code);

void StubCode::InitOnce() {
  // Generate all the stubs.
  Code& code = Code::Handle();
  VM_STUB_CODE_LIST(STUB_CODE_GENERATE);
}

#undef STUB_CODE_GENERATE

RawCode* StubCode::Generate(const char* name,
                            void (*GenerateStub)(Assembler* assembler)) {
  Assembler assembler;
  GenerateStub(&assembler);
  const Code& code =
      Code::Handle(Code::FinalizeCode(name, &assembler, false /* optimized */));
#ifndef PRODUCT
  if (FLAG_support_disassembler && FLAG_disassemble_stubs) {
    LogBlock lb;
    THR_Print("Code for stub '%s': {\n", name);
    DisassembleToStdout formatter;
    code.Disassemble(&formatter);
    THR_Print("}\n");
    const ObjectPool& object_pool = ObjectPool::Handle(code.object_pool());
    object_pool.DebugPrint();
  }
#endif  // !PRODUCT
  return code.raw();
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

void StubCode::Init(Isolate* isolate) {}

void StubCode::VisitObjectPointers(ObjectPointerVisitor* visitor) {}

bool StubCode::HasBeenInitialized() {
#if !defined(TARGET_ARCH_DBC)
  // Use JumpToHandler and InvokeDart as canaries.
  const StubEntry* entry_1 = StubCode::JumpToFrame_entry();
  const StubEntry* entry_2 = StubCode::InvokeDartCode_entry();
  return (entry_1 != NULL) && (entry_2 != NULL);
#else
  return true;
#endif
}

bool StubCode::InInvocationStub(uword pc) {
#if !defined(TARGET_ARCH_DBC)
  ASSERT(HasBeenInitialized());
  uword entry = StubCode::InvokeDartCode_entry()->EntryPoint();
  uword size = StubCode::InvokeDartCodeSize();
  return (pc >= entry) && (pc < (entry + size));
#else
  // On DBC we use a special marker PC to signify entry frame because there is
  // no such thing as invocation stub.
  return (pc & 2) != 0;
#endif
}

bool StubCode::InJumpToFrameStub(uword pc) {
#if !defined(TARGET_ARCH_DBC)
  ASSERT(HasBeenInitialized());
  uword entry = StubCode::JumpToFrame_entry()->EntryPoint();
  uword size = StubCode::JumpToFrameSize();
  return (pc >= entry) && (pc < (entry + size));
#else
  // This stub does not exist on DBC.
  return false;
#endif
}

RawCode* StubCode::GetAllocationStubForClass(const Class& cls) {
// These stubs are not used by DBC.
#if !defined(TARGET_ARCH_DBC)
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Error& error = Error::Handle(zone, cls.EnsureIsFinalized(thread));
  ASSERT(error.IsNull());
  if (cls.id() == kArrayCid) {
    return AllocateArray_entry()->code();
  }
  Code& stub = Code::Handle(zone, cls.allocation_stub());
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (stub.IsNull()) {
    Assembler assembler;
    const char* name = cls.ToCString();
    StubCode::GenerateAllocationStubForClass(&assembler, cls);

    if (thread->IsMutatorThread()) {
      stub ^= Code::FinalizeCode(name, &assembler, false /* optimized */);
      // Check if background compilation thread has not already added the stub.
      if (cls.allocation_stub() == Code::null()) {
        stub.set_owner(cls);
        cls.set_allocation_stub(stub);
      }
    } else {
      // This part of stub code generation must be at a safepoint.
      // Stop mutator thread before creating the instruction object and
      // installing code.
      // Mutator thread may not run code while we are creating the
      // instruction object, since the creation of instruction object
      // changes code page access permissions (makes them temporary not
      // executable).
      {
        SafepointOperationScope safepoint_scope(thread);
        stub = cls.allocation_stub();
        // Check if stub was already generated.
        if (!stub.IsNull()) {
          return stub.raw();
        }
        // Do not Garbage collect during this stage and instead allow the
        // heap to grow.
        NoHeapGrowthControlScope no_growth_control;
        stub ^= Code::FinalizeCode(name, &assembler, false /* optimized */);
        stub.set_owner(cls);
        cls.set_allocation_stub(stub);
      }
      Isolate* isolate = thread->isolate();
      if (isolate->heap()->NeedsGarbageCollection()) {
        isolate->heap()->CollectAllGarbage();
      }
    }
#ifndef PRODUCT
    if (FLAG_support_disassembler && FLAG_disassemble_stubs) {
      LogBlock lb;
      THR_Print("Code for allocation stub '%s': {\n", name);
      DisassembleToStdout formatter;
      stub.Disassemble(&formatter);
      THR_Print("}\n");
      const ObjectPool& object_pool = ObjectPool::Handle(stub.object_pool());
      object_pool.DebugPrint();
    }
#endif  // !PRODUCT
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  return stub.raw();
#endif  // !DBC
  UNIMPLEMENTED();
  return Code::null();
}

const StubEntry* StubCode::UnoptimizedStaticCallEntry(
    intptr_t num_args_tested) {
// These stubs are not used by DBC.
#if !defined(TARGET_ARCH_DBC)
  switch (num_args_tested) {
    case 0:
      return ZeroArgsUnoptimizedStaticCall_entry();
    case 1:
      return OneArgUnoptimizedStaticCall_entry();
    case 2:
      return TwoArgsUnoptimizedStaticCall_entry();
    default:
      UNIMPLEMENTED();
      return NULL;
  }
#else
  return NULL;
#endif
}

const char* StubCode::NameOfStub(uword entry_point) {
#define VM_STUB_CODE_TESTER(name)                                              \
  if ((name##_entry() != NULL) &&                                              \
      (entry_point == name##_entry()->EntryPoint())) {                         \
    return "" #name;                                                           \
  }
  VM_STUB_CODE_LIST(VM_STUB_CODE_TESTER);
#undef VM_STUB_CODE_TESTER
  return NULL;
}

}  // namespace dart

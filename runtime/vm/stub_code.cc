// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/stub_code.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/clustered_snapshot.h"
#include "vm/compiler/aot/precompiler.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/flags.h"
#include "vm/heap/safepoint.h"
#include "vm/interpreter.h"
#include "vm/object_store.h"
#include "vm/snapshot.h"
#include "vm/virtual_memory.h"
#include "vm/visitor.h"

namespace dart {

DEFINE_FLAG(bool, disassemble_stubs, false, "Disassemble generated stubs.");
DECLARE_FLAG(bool, precompiled_mode);

DECLARE_FLAG(bool, enable_interpreter);

Code* StubCode::entries_[kNumStubEntries] = {
#define STUB_CODE_DECLARE(name) nullptr,
    VM_STUB_CODE_LIST(STUB_CODE_DECLARE)
#undef STUB_CODE_DECLARE
};

#if defined(DART_PRECOMPILED_RUNTIME)
void StubCode::Init() {
  // Stubs will be loaded from the snapshot.
  UNREACHABLE();
}

#else

#define STUB_CODE_GENERATE(name)                                               \
  entries_[k##name##Index] = Code::ReadOnlyHandle();                           \
  *entries_[k##name##Index] =                                                  \
      Generate("_stub_" #name, &object_pool_builder,                           \
               compiler::StubCodeCompiler::Generate##name##Stub);

#define STUB_CODE_SET_OBJECT_POOL(name)                                        \
  entries_[k##name##Index]->set_object_pool(object_pool.raw());

void StubCode::Init() {
  compiler::ObjectPoolBuilder object_pool_builder;

  // Generate all the stubs.
  VM_STUB_CODE_LIST(STUB_CODE_GENERATE);

  const ObjectPool& object_pool =
      ObjectPool::Handle(ObjectPool::NewFromBuilder(object_pool_builder));

  VM_STUB_CODE_LIST(STUB_CODE_SET_OBJECT_POOL)
}

#undef STUB_CODE_GENERATE
#undef STUB_CODE_SET_OBJECT_POOL

RawCode* StubCode::Generate(
    const char* name,
    compiler::ObjectPoolBuilder* object_pool_builder,
    void (*GenerateStub)(compiler::Assembler* assembler)) {
  compiler::Assembler assembler(object_pool_builder);
  GenerateStub(&assembler);
  const Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      name, nullptr, &assembler, Code::PoolAttachment::kNotAttachPool,
      /*optimized=*/false));
#ifndef PRODUCT
  if (FLAG_support_disassembler && FLAG_disassemble_stubs) {
    LogBlock lb;
    THR_Print("Code for stub '%s': {\n", name);
    DisassembleToStdout formatter;
    code.Disassemble(&formatter);
    THR_Print("}\n");
    const ObjectPool& object_pool = ObjectPool::Handle(code.object_pool());
    if (!object_pool.IsNull()) {
      object_pool.DebugPrint();
    }
  }
#endif  // !PRODUCT
  return code.raw();
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#define STUB_CODE_CLEANUP(name) entries_[k##name##Index] = nullptr;

void StubCode::Cleanup() {
  VM_STUB_CODE_LIST(STUB_CODE_CLEANUP);
}

#undef STUB_CODE_CLEANUP

void StubCode::VisitObjectPointers(ObjectPointerVisitor* visitor) {}

bool StubCode::HasBeenInitialized() {
  // Use AsynchronousGapMarker as canary.
  return entries_[kAsynchronousGapMarkerIndex] != nullptr;
}

bool StubCode::InInvocationStub(uword pc, bool is_interpreted_frame) {
#if !defined(TARGET_ARCH_DBC)
  ASSERT(HasBeenInitialized());
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (FLAG_enable_interpreter) {
    if (is_interpreted_frame) {
      // Recognize special marker set up by interpreter in entry frame.
      return Interpreter::IsEntryFrameMarker(
          reinterpret_cast<const KBCInstr*>(pc));
    }
    {
      uword entry = StubCode::InvokeDartCodeFromBytecode().EntryPoint();
      uword size = StubCode::InvokeDartCodeFromBytecodeSize();
      if ((pc >= entry) && (pc < (entry + size))) {
        return true;
      }
    }
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  uword entry = StubCode::InvokeDartCode().EntryPoint();
  uword size = StubCode::InvokeDartCodeSize();
  return (pc >= entry) && (pc < (entry + size));
#else
  if (FLAG_enable_interpreter) {
    FATAL(
        "Simultaneous usage of DBC simulator "
        "and interpreter not yet supported.");
  }
  // On DBC we use a special marker PC to signify entry frame because there is
  // no such thing as invocation stub.
  return (pc & 2) != 0;
#endif
}

bool StubCode::InJumpToFrameStub(uword pc) {
#if !defined(TARGET_ARCH_DBC)
  ASSERT(HasBeenInitialized());
  uword entry = StubCode::JumpToFrame().EntryPoint();
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
    return AllocateArray().raw();
  }
  Code& stub = Code::Handle(zone, cls.allocation_stub());
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (stub.IsNull()) {
    compiler::ObjectPoolBuilder object_pool_builder;
    Precompiler* precompiler = Precompiler::Instance();

    compiler::ObjectPoolBuilder* wrapper =
        FLAG_use_bare_instructions && precompiler != NULL
            ? precompiler->global_object_pool_builder()
            : &object_pool_builder;

    const auto pool_attachment =
        FLAG_precompiled_mode && FLAG_use_bare_instructions
            ? Code::PoolAttachment::kNotAttachPool
            : Code::PoolAttachment::kAttachPool;

    compiler::Assembler assembler(wrapper);
    const char* name = cls.ToCString();
    compiler::StubCodeCompiler::GenerateAllocationStubForClass(&assembler, cls);

    if (thread->IsMutatorThread()) {
      stub = Code::FinalizeCodeAndNotify(name, nullptr, &assembler,
                                         pool_attachment,
                                         /*optimized1*/ false);
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
        stub = Code::FinalizeCode(nullptr, &assembler, pool_attachment,
                                  /*optimized=*/false, /*stats=*/nullptr);
        stub.set_owner(cls);
        cls.set_allocation_stub(stub);
      }

      // We notify code observers after finalizing the code in order to be
      // outside a [SafepointOperationScope].
      Code::NotifyCodeObservers(nullptr, stub, /*optimized=*/false);

      Isolate* isolate = thread->isolate();
      if (isolate->heap()->NeedsGarbageCollection()) {
        isolate->heap()->CollectMostGarbage();
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
      if (!object_pool.IsNull()) {
        object_pool.DebugPrint();
      }
    }
#endif  // !PRODUCT
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  return stub.raw();
#endif  // !DBC
  UNIMPLEMENTED();
  return Code::null();
}

#if !defined(TARGET_ARCH_DBC) && !defined(TARGET_ARCH_IA32)
RawCode* StubCode::GetBuildMethodExtractorStub(
    compiler::ObjectPoolBuilder* pool) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  auto thread = Thread::Current();
  auto Z = thread->zone();
  auto object_store = thread->isolate()->object_store();

  const auto& closure_class =
      Class::ZoneHandle(Z, object_store->closure_class());
  const auto& closure_allocation_stub =
      Code::ZoneHandle(Z, StubCode::GetAllocationStubForClass(closure_class));
  const auto& context_allocation_stub = StubCode::AllocateContext();

  compiler::ObjectPoolBuilder object_pool_builder;
  compiler::Assembler assembler(pool != nullptr ? pool : &object_pool_builder);
  compiler::StubCodeCompiler::GenerateBuildMethodExtractorStub(
      &assembler, closure_allocation_stub, context_allocation_stub);

  const char* name = "BuildMethodExtractor";
  const Code& stub = Code::Handle(Code::FinalizeCodeAndNotify(
      name, nullptr, &assembler, Code::PoolAttachment::kNotAttachPool,
      /*optimized=*/false));

  if (pool == nullptr) {
    stub.set_object_pool(ObjectPool::NewFromBuilder(object_pool_builder));
  }

#ifndef PRODUCT
  if (FLAG_support_disassembler && FLAG_disassemble_stubs) {
    LogBlock lb;
    THR_Print("Code for isolate stub '%s': {\n", name);
    DisassembleToStdout formatter;
    stub.Disassemble(&formatter);
    THR_Print("}\n");
    const ObjectPool& object_pool = ObjectPool::Handle(stub.object_pool());
    if (!object_pool.IsNull()) {
      object_pool.DebugPrint();
    }
  }
#endif  // !PRODUCT
  return stub.raw();
#else   // !defined(DART_PRECOMPILED_RUNTIME)
  UNIMPLEMENTED();
  return nullptr;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}
#endif  // !defined(TARGET_ARCH_DBC)

const Code& StubCode::UnoptimizedStaticCallEntry(intptr_t num_args_tested) {
// These stubs are not used by DBC.
#if !defined(TARGET_ARCH_DBC)
  switch (num_args_tested) {
    case 0:
      return ZeroArgsUnoptimizedStaticCall();
    case 1:
      return OneArgUnoptimizedStaticCall();
    case 2:
      return TwoArgsUnoptimizedStaticCall();
    default:
      UNIMPLEMENTED();
      return Code::Handle();
  }
#else
  return Code::Handle();
#endif
}

const char* StubCode::NameOfStub(uword entry_point) {
#define VM_STUB_CODE_TESTER(name)                                              \
  if (entries_[k##name##Index] != nullptr &&                                   \
      !entries_[k##name##Index]->IsNull() &&                                   \
      entries_[k##name##Index]->EntryPoint() == entry_point) {                 \
    return "" #name;                                                           \
  }
  VM_STUB_CODE_LIST(VM_STUB_CODE_TESTER);
#undef VM_STUB_CODE_TESTER
  return nullptr;
}

}  // namespace dart

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
    Disassembler::DisassembleStub(name, code);
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

bool StubCode::HasBeenInitialized() {
  // Use AsynchronousGapMarker as canary.
  return entries_[kAsynchronousGapMarkerIndex] != nullptr;
}

bool StubCode::InInvocationStub(uword pc, bool is_interpreted_frame) {
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
}

bool StubCode::InJumpToFrameStub(uword pc) {
  ASSERT(HasBeenInitialized());
  uword entry = StubCode::JumpToFrame().EntryPoint();
  uword size = StubCode::JumpToFrameSize();
  return (pc >= entry) && (pc < (entry + size));
}

RawCode* StubCode::GetAllocationStubForClass(const Class& cls) {
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

    auto mutator_fun = [&]() {
      stub = Code::FinalizeCode(nullptr, &assembler, pool_attachment,
                                /*optimized=*/false,
                                /*stats=*/nullptr);
      // Check if background compilation thread has not already added the stub.
      if (cls.allocation_stub() == Code::null()) {
        stub.set_owner(cls);
        cls.set_allocation_stub(stub);
      }
    };
    auto bg_compiler_fun = [&]() {
      ForceGrowthSafepointOperationScope safepoint_scope(thread);
      stub = cls.allocation_stub();
      // Check if stub was already generated.
      if (!stub.IsNull()) {
        return;
      }
      stub = Code::FinalizeCode(nullptr, &assembler, pool_attachment,
                                /*optimized=*/false, /*stats=*/nullptr);
      stub.set_owner(cls);
      cls.set_allocation_stub(stub);
    };

    // We have to ensure no mutators are running, because:
    //
    //   a) We allocate an instructions object, which might cause us to
    //      temporarily flip page protections from (RX -> RW -> RX).
    //
    //   b) To ensure only one thread succeeds installing an allocation for the
    //      given class.
    //
    thread->isolate_group()->RunWithStoppedMutators(
        mutator_fun, bg_compiler_fun, /*use_force_growth=*/true);

    // We notify code observers after finalizing the code in order to be
    // outside a [SafepointOperationScope].
    Code::NotifyCodeObservers(name, stub, /*optimized=*/false);
#ifndef PRODUCT
    if (FLAG_support_disassembler && FLAG_disassemble_stubs) {
      Disassembler::DisassembleStub(name, stub);
    }
#endif  // !PRODUCT
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  return stub.raw();
}

#if !defined(TARGET_ARCH_IA32)
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
    Disassembler::DisassembleStub(name, stub);
  }
#endif  // !PRODUCT
  return stub.raw();
#else   // !defined(DART_PRECOMPILED_RUNTIME)
  UNIMPLEMENTED();
  return nullptr;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}
#endif  // !defined(TARGET_ARCH_IA32)

const Code& StubCode::UnoptimizedStaticCallEntry(intptr_t num_args_tested) {
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

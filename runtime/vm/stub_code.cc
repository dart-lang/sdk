// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/stub_code.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/clustered_snapshot.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/flags.h"
#include "vm/heap/safepoint.h"
#include "vm/object_store.h"
#include "vm/snapshot.h"
#include "vm/virtual_memory.h"
#include "vm/visitor.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/aot/precompiler.h"
#include "vm/compiler/assembler/assembler.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

DEFINE_FLAG(bool, disassemble_stubs, false, "Disassemble generated stubs.");
DECLARE_FLAG(bool, precompiled_mode);

StubCode::StubCodeEntry StubCode::entries_[kNumStubEntries] = {
#if defined(DART_PRECOMPILED_RUNTIME)
#define STUB_CODE_DECLARE(name) {nullptr, #name},
#else
#define STUB_CODE_DECLARE(name)                                                \
  {nullptr, #name, compiler::StubCodeCompiler::Generate##name##Stub},
#endif
    VM_STUB_CODE_LIST(STUB_CODE_DECLARE)
#undef STUB_CODE_DECLARE
};

#if defined(DART_PRECOMPILED_RUNTIME)
void StubCode::Init() {
  // Stubs will be loaded from the snapshot.
  UNREACHABLE();
}

#else

void StubCode::Init() {
  compiler::ObjectPoolBuilder object_pool_builder;

  // Generate all the stubs.
  for (size_t i = 0; i < ARRAY_SIZE(entries_); i++) {
    entries_[i].code = Code::ReadOnlyHandle();
    *(entries_[i].code) =
        Generate(entries_[i].name, &object_pool_builder, entries_[i].generator);
  }

  const ObjectPool& object_pool =
      ObjectPool::Handle(ObjectPool::NewFromBuilder(object_pool_builder));

  for (size_t i = 0; i < ARRAY_SIZE(entries_); i++) {
    entries_[i].code->set_object_pool(object_pool.raw());
  }
}

#undef STUB_CODE_GENERATE
#undef STUB_CODE_SET_OBJECT_POOL

CodePtr StubCode::Generate(
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

void StubCode::Cleanup() {
  for (size_t i = 0; i < ARRAY_SIZE(entries_); i++) {
    entries_[i].code = nullptr;
  }
}

bool StubCode::HasBeenInitialized() {
  // Use AsynchronousGapMarker as canary.
  return entries_[kAsynchronousGapMarkerIndex].code != nullptr;
}

bool StubCode::InInvocationStub(uword pc) {
  ASSERT(HasBeenInitialized());
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

#if !defined(DART_PRECOMPILED_RUNTIME)
ArrayPtr compiler::StubCodeCompiler::BuildStaticCallsTable(
    Zone* zone,
    compiler::UnresolvedPcRelativeCalls* unresolved_calls) {
  if (unresolved_calls->length() == 0) {
    return Array::null();
  }
  const intptr_t array_length =
      unresolved_calls->length() * Code::kSCallTableEntryLength;
  const auto& static_calls_table =
      Array::Handle(zone, Array::New(array_length, Heap::kOld));
  StaticCallsTable entries(static_calls_table);
  auto& kind_type_and_offset = Smi::Handle(zone);
  for (intptr_t i = 0; i < unresolved_calls->length(); i++) {
    auto& unresolved_call = (*unresolved_calls)[i];
    auto call_kind = unresolved_call->is_tail_call() ? Code::kPcRelativeTailCall
                                                     : Code::kPcRelativeCall;
    kind_type_and_offset =
        Smi::New(Code::KindField::encode(call_kind) |
                 Code::EntryPointField::encode(Code::kDefaultEntry) |
                 Code::OffsetField::encode(unresolved_call->offset()));
    auto view = entries[i];
    view.Set<Code::kSCallTableKindAndOffset>(kind_type_and_offset);
    view.Set<Code::kSCallTableCodeOrTypeTarget>(unresolved_call->target());
  }
  return static_calls_table.raw();
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

CodePtr StubCode::GetAllocationStubForClass(const Class& cls) {
  Thread* thread = Thread::Current();
  auto object_store = thread->isolate()->object_store();
  Zone* zone = thread->zone();
  const Error& error =
      Error::Handle(zone, cls.EnsureIsAllocateFinalized(thread));
  ASSERT(error.IsNull());
  if (cls.id() == kArrayCid) {
    return object_store->allocate_array_stub();
  } else if (cls.id() == kContextCid) {
    return object_store->allocate_context_stub();
  } else if (cls.id() == kUnhandledExceptionCid) {
    return object_store->allocate_unhandled_exception_stub();
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

    auto zone = thread->zone();
    auto object_store = thread->isolate()->object_store();
    auto& allocate_object_stub = Code::ZoneHandle(zone);
    auto& allocate_object_parametrized_stub = Code::ZoneHandle(zone);
    if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
      allocate_object_stub = object_store->allocate_object_stub();
      allocate_object_parametrized_stub =
          object_store->allocate_object_parametrized_stub();
    }

    compiler::Assembler assembler(wrapper);
    compiler::UnresolvedPcRelativeCalls unresolved_calls;
    const char* name = cls.ToCString();
    compiler::StubCodeCompiler::GenerateAllocationStubForClass(
        &assembler, &unresolved_calls, cls, allocate_object_stub,
        allocate_object_parametrized_stub);

    const auto& static_calls_table =
        Array::Handle(zone, compiler::StubCodeCompiler::BuildStaticCallsTable(
                                zone, &unresolved_calls));

    auto mutator_fun = [&]() {
      stub = Code::FinalizeCode(nullptr, &assembler, pool_attachment,
                                /*optimized=*/false,
                                /*stats=*/nullptr);
      // Check if background compilation thread has not already added the stub.
      if (cls.allocation_stub() == Code::null()) {
        stub.set_owner(cls);
        if (!static_calls_table.IsNull()) {
          stub.set_static_calls_target_table(static_calls_table);
        }
        cls.set_allocation_stub(stub);
      }
    };
    auto bg_compiler_fun = [&]() {
      ASSERT(Thread::Current()->IsAtSafepoint());
      stub = cls.allocation_stub();
      // Check if stub was already generated.
      if (!stub.IsNull()) {
        return;
      }
      stub = Code::FinalizeCode(nullptr, &assembler, pool_attachment,
                                /*optimized=*/false, /*stats=*/nullptr);
      stub.set_owner(cls);
      if (!static_calls_table.IsNull()) {
        stub.set_static_calls_target_table(static_calls_table);
      }
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

CodePtr StubCode::GetAllocationStubForTypedData(classid_t class_id) {
  auto object_store = Thread::Current()->isolate()->object_store();
  switch (class_id) {
    case kTypedDataInt8ArrayCid:
      return object_store->allocate_int8_array_stub();
    case kTypedDataUint8ArrayCid:
      return object_store->allocate_uint8_array_stub();
    case kTypedDataUint8ClampedArrayCid:
      return object_store->allocate_uint8_clamped_array_stub();
    case kTypedDataInt16ArrayCid:
      return object_store->allocate_int16_array_stub();
    case kTypedDataUint16ArrayCid:
      return object_store->allocate_uint16_array_stub();
    case kTypedDataInt32ArrayCid:
      return object_store->allocate_int32_array_stub();
    case kTypedDataUint32ArrayCid:
      return object_store->allocate_uint32_array_stub();
    case kTypedDataInt64ArrayCid:
      return object_store->allocate_int64_array_stub();
    case kTypedDataUint64ArrayCid:
      return object_store->allocate_uint64_array_stub();
    case kTypedDataFloat32ArrayCid:
      return object_store->allocate_float32_array_stub();
    case kTypedDataFloat64ArrayCid:
      return object_store->allocate_float64_array_stub();
    case kTypedDataFloat32x4ArrayCid:
      return object_store->allocate_float32x4_array_stub();
    case kTypedDataInt32x4ArrayCid:
      return object_store->allocate_int32x4_array_stub();
    case kTypedDataFloat64x2ArrayCid:
      return object_store->allocate_float64x2_array_stub();
  }
  UNREACHABLE();
  return Code::null();
}

#if !defined(TARGET_ARCH_IA32)
CodePtr StubCode::GetBuildMethodExtractorStub(
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
  for (size_t i = 0; i < ARRAY_SIZE(entries_); i++) {
    if ((entries_[i].code != nullptr) && !entries_[i].code->IsNull() &&
        (entries_[i].code->EntryPoint() == entry_point)) {
      return entries_[i].name;
    }
  }

  auto object_store = Isolate::Current()->object_store();

#define MATCH(member, name)                                                    \
  if (object_store->member() != Code::null() &&                                \
      entry_point == Code::EntryPointOf(object_store->member())) {             \
    return "_iso_stub_" #name "Stub";                                          \
  }
  OBJECT_STORE_STUB_CODE_LIST(MATCH)
  MATCH(build_method_extractor_code, BuildMethodExtractor)
#undef MATCH
  return nullptr;
}

}  // namespace dart

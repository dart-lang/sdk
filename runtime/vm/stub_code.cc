// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/stub_code.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/app_snapshot.h"
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

DECLARE_FLAG(bool, precompiled_mode);

StubCode::StubCodeEntry StubCode::entries_[kNumStubEntries] = {
#if defined(DART_PRECOMPILED_RUNTIME)
#define STUB_CODE_DECLARE(name) {nullptr, #name},
#else
#define STUB_CODE_DECLARE(name)                                                \
  {nullptr, #name, &compiler::StubCodeCompiler::Generate##name##Stub},
#endif
    VM_STUB_CODE_LIST(STUB_CODE_DECLARE)
#undef STUB_CODE_DECLARE
};
AcqRelAtomic<bool> StubCode::initialized_ = {false};

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
    entries_[i].code->set_object_pool(object_pool.ptr());
  }

  InitializationDone();

#if defined(DART_PRECOMPILER)
  {
    // Set Function owner for UnknownDartCode stub so it pretends to
    // be a Dart code.
    Zone* zone = Thread::Current()->zone();
    const auto& signature = FunctionType::Handle(zone, FunctionType::New());
    auto& owner = Object::Handle(zone);
    owner = Object::void_class();
    ASSERT(!owner.IsNull());
    owner = Function::New(signature, Object::null_string(),
                          UntaggedFunction::kRegularFunction,
                          /*is_static=*/true,
                          /*is_const=*/false,
                          /*is_abstract=*/false,
                          /*is_external=*/false,
                          /*is_native=*/false, owner, TokenPosition::kNoSource);
    StubCode::UnknownDartCode().set_owner(owner);
    StubCode::UnknownDartCode().set_exception_handlers(
        Object::empty_exception_handlers());
    StubCode::UnknownDartCode().set_pc_descriptors(Object::empty_descriptors());
    ASSERT(StubCode::UnknownDartCode().IsFunctionCode());
  }
#endif  // defined(DART_PRECOMPILER)
}

#undef STUB_CODE_GENERATE
#undef STUB_CODE_SET_OBJECT_POOL

CodePtr StubCode::Generate(const char* name,
                           compiler::ObjectPoolBuilder* object_pool_builder,
                           void (compiler::StubCodeCompiler::*GenerateStub)()) {
  auto thread = Thread::Current();
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());

  compiler::Assembler assembler(object_pool_builder);
  compiler::StubCodeCompiler stubCodeCompiler(&assembler);
  (stubCodeCompiler.*GenerateStub)();
  const Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      name, nullptr, &assembler, Code::PoolAttachment::kNotAttachPool,
      /*optimized=*/false));
#ifndef PRODUCT
  if (FLAG_support_disassembler && FLAG_disassemble_stubs) {
    Disassembler::DisassembleStub(name, code);
  }
#endif  // !PRODUCT
  return code.ptr();
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

void StubCode::Cleanup() {
  initialized_.store(false, std::memory_order_release);

  for (size_t i = 0; i < ARRAY_SIZE(entries_); i++) {
    entries_[i].code = nullptr;
  }
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
  return static_calls_table.ptr();
}

CodePtr StubCode::GetAllocationStubForClass(const Class& cls) {
  Thread* thread = Thread::Current();
  auto object_store = thread->isolate_group()->object_store();
  Zone* zone = thread->zone();
  const Error& error =
      Error::Handle(zone, cls.EnsureIsAllocateFinalized(thread));
  ASSERT(error.IsNull());
  switch (cls.id()) {
    case kArrayCid:
      return object_store->allocate_array_stub();
#if !defined(TARGET_ARCH_IA32)
    case kGrowableObjectArrayCid:
      return object_store->allocate_growable_array_stub();
#endif  // !defined(TARGET_ARCH_IA32)
    case kContextCid:
      return object_store->allocate_context_stub();
    case kUnhandledExceptionCid:
      return object_store->allocate_unhandled_exception_stub();
    case kMintCid:
      return object_store->allocate_mint_stub();
    case kDoubleCid:
      return object_store->allocate_double_stub();
    case kFloat32x4Cid:
      return object_store->allocate_float32x4_stub();
    case kFloat64x2Cid:
      return object_store->allocate_float64x2_stub();
    case kInt32x4Cid:
      return object_store->allocate_int32x4_stub();
    case kClosureCid:
      return object_store->allocate_closure_stub();
    case kRecordCid:
      return object_store->allocate_record_stub();
  }
  Code& stub = Code::Handle(zone, cls.allocation_stub());
  if (stub.IsNull()) {
    compiler::ObjectPoolBuilder object_pool_builder;
    Precompiler* precompiler = Precompiler::Instance();

    compiler::ObjectPoolBuilder* wrapper =
        precompiler != NULL ? precompiler->global_object_pool_builder()
                            : &object_pool_builder;

    const auto pool_attachment = FLAG_precompiled_mode
                                     ? Code::PoolAttachment::kNotAttachPool
                                     : Code::PoolAttachment::kAttachPool;

    auto zone = thread->zone();
    auto object_store = thread->isolate_group()->object_store();
    auto& allocate_object_stub = Code::ZoneHandle(zone);
    auto& allocate_object_parametrized_stub = Code::ZoneHandle(zone);
    if (FLAG_precompiled_mode) {
      allocate_object_stub = object_store->allocate_object_stub();
      allocate_object_parametrized_stub =
          object_store->allocate_object_parametrized_stub();
    }

    compiler::Assembler assembler(wrapper);
    compiler::UnresolvedPcRelativeCalls unresolved_calls;
    const char* name = cls.ToCString();
    compiler::StubCodeCompiler stubCodeCompiler(&assembler);
    stubCodeCompiler.GenerateAllocationStubForClass(
        &unresolved_calls, cls, allocate_object_stub,
        allocate_object_parametrized_stub);

    const auto& static_calls_table =
        Array::Handle(zone, compiler::StubCodeCompiler::BuildStaticCallsTable(
                                zone, &unresolved_calls));

    SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());

    auto mutator_fun = [&]() {
      stub = Code::FinalizeCode(nullptr, &assembler, pool_attachment,
                                /*optimized=*/false,
                                /*stats=*/nullptr);
      // Check if some other thread has not already added the stub.
      if (cls.allocation_stub() == Code::null()) {
        stub.set_owner(cls);
        if (!static_calls_table.IsNull()) {
          stub.set_static_calls_target_table(static_calls_table);
        }
        cls.set_allocation_stub(stub);
      }
    };

    // We have to ensure no mutators are running, because:
    //
    //   a) We allocate an instructions object, which might cause us to
    //      temporarily flip page protections from (RX -> RW -> RX).
    thread->isolate_group()->RunWithStoppedMutators(mutator_fun,
                                                    /*use_force_growth=*/true);

    // We notify code observers after finalizing the code in order to be
    // outside a [SafepointOperationScope].
    Code::NotifyCodeObservers(name, stub, /*optimized=*/false);
#ifndef PRODUCT
    if (FLAG_support_disassembler && FLAG_disassemble_stubs) {
      Disassembler::DisassembleStub(name, stub);
    }
#endif  // !PRODUCT
  }
  return stub.ptr();
}

CodePtr StubCode::GetAllocationStubForTypedData(classid_t class_id) {
  auto object_store = Thread::Current()->isolate_group()->object_store();
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
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#if !defined(TARGET_ARCH_IA32)
CodePtr StubCode::GetBuildMethodExtractorStub(compiler::ObjectPoolBuilder* pool,
                                              bool generic) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  auto thread = Thread::Current();
  auto Z = thread->zone();
  auto object_store = thread->isolate_group()->object_store();

  const auto& closure_allocation_stub =
      Code::ZoneHandle(Z, object_store->allocate_closure_stub());
  const auto& context_allocation_stub =
      Code::ZoneHandle(Z, object_store->allocate_context_stub());

  compiler::ObjectPoolBuilder object_pool_builder;
  compiler::Assembler assembler(pool != nullptr ? pool : &object_pool_builder);
  compiler::StubCodeCompiler stubCodeCompiler(&assembler);
  stubCodeCompiler.GenerateBuildMethodExtractorStub(
      closure_allocation_stub, context_allocation_stub, generic);

  const char* name = generic ? "BuildGenericMethodExtractor"
                             : "BuildNonGenericMethodExtractor";
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
  return stub.ptr();
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

  auto object_store = IsolateGroup::Current()->object_store();

#define MATCH(member, name)                                                    \
  if (object_store->member() != Code::null() &&                                \
      entry_point == Code::EntryPointOf(object_store->member())) {             \
    return "_iso_stub_" #name "Stub";                                          \
  }
  OBJECT_STORE_STUB_CODE_LIST(MATCH)
  MATCH(build_generic_method_extractor_code, BuildGenericMethodExtractor)
  MATCH(build_nongeneric_method_extractor_code, BuildNonGenericMethodExtractor)
#undef MATCH
  return nullptr;
}

}  // namespace dart

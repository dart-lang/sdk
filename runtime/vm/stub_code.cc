// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/stub_code.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/flags.h"
#include "vm/heap/safepoint.h"
#include "vm/interpreter.h"
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

#ifdef DART_TARGET_SUPPORTS_PROBE_POINTS
DEFINE_FLAG(bool,
            generate_probe_points,
            false,
            "Generate probe points for installation of user space probes");
#endif

#if defined(DART_PRECOMPILED_RUNTIME)
void StubCode::Init() {
  // Stubs will be loaded from the snapshot.
  UNREACHABLE();
}

#else

void StubCode::Init() {
  compiler::ObjectPoolBuilder object_pool_builder;

  // Generate all the stubs.
  static void (compiler::StubCodeCompiler::* const generators[])() = {
#define STUB_CODE_DECLARE(name)                                                \
  &compiler::StubCodeCompiler::Generate##name##Stub,
      VM_STUB_CODE_LIST(STUB_CODE_DECLARE)
#undef STUB_CODE_DECLARE
  };

  for (intptr_t i = 0; i < kNumStubEntries; i++) {
    Roots::stub_handle(i).initRO(
        Generate(StubNames[i], &object_pool_builder, generators[i]));
  }

  const ObjectPool& object_pool =
      ObjectPool::Handle(ObjectPool::NewFromBuilder(object_pool_builder));

  for (intptr_t i = 0; i < kNumStubEntries; i++) {
    Roots::stub_handle(i).set_object_pool(object_pool.ptr());
  }

#if defined(DART_PRECOMPILER)
  {
    // Set Function owner for UnknownDartCode stub so it pretends to
    // be a Dart code.
    Thread* thread = Thread::Current();
    Zone* zone = thread->zone();
    const auto& signature = FunctionType::Handle(zone, FunctionType::New());
    auto& owner = Object::Handle(zone);
    owner = thread->isolate_group()->class_table()->At(kVoidCid);
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

  if (FLAG_write_protect_code) {
    // An FFI call can be executing in CallNativeThroughSafepoint while a
    // safepoint is in progress. It needs to stay executable.
    IsolateGroup::Current()->heap()->old_space()->Freeze(
        Page::Of(StubCode::CallNativeThroughSafepoint().instructions()));
  }
}

#undef STUB_CODE_GENERATE
#undef STUB_CODE_SET_OBJECT_POOL

CodePtr StubCode::Generate(const char* name,
                           compiler::ObjectPoolBuilder* object_pool_builder,
                           void (compiler::StubCodeCompiler::*GenerateStub)()) {
  auto thread = Thread::Current();
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());

  compiler::Assembler assembler(object_pool_builder);
  CompilerState compiler_state(thread, /*is_aot=*/FLAG_precompiled_mode,
                               /*is_optimizing=*/false);
  Zone* zone = thread->zone();
  auto* pc_descriptors_list = new (zone) DescriptorList(zone);
  compiler::StubCodeCompiler stubCodeCompiler(&assembler, pc_descriptors_list);
  (stubCodeCompiler.*GenerateStub)();
  const Code& code = Code::Handle(
      zone, Code::FinalizeCodeAndNotify(name, nullptr, &assembler,
                                        Code::PoolAttachment::kNotAttachPool,
                                        /*optimized=*/false));
  const PcDescriptors& descriptors = PcDescriptors::Handle(
      zone, pc_descriptors_list->FinalizePcDescriptors(code.PayloadStart()));
  code.set_pc_descriptors(descriptors);

#ifndef PRODUCT
  if (FLAG_support_disassembler && FLAG_disassemble_stubs) {
    Disassembler::DisassembleStub(name, code);
  }
#endif  // !PRODUCT
  ASSERT(!code.IsNull());
  return code.ptr();
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

bool StubCode::InInvocationStub(Thread* T,
                                uword pc,
                                bool is_interpreted_frame) {
  // T might differ from the current thread on platforms where profiling is
  // cross thread, like Mac/Windows/Fuchsia.
  Roots* roots = T->isolate_group()->roots();
  if (roots == nullptr) return false;

#if defined(DART_DYNAMIC_MODULES)
  if (is_interpreted_frame) {
    // Recognize special marker set up by interpreter in entry frame.
    return Interpreter::IsEntryFrameMarker(
        reinterpret_cast<const KBCInstr*>(pc));
  }
  {
    const Code& stub = roots->x_stub_handle(kInvokeDartCodeFromBytecodeIndex);
    uword entry = Code::StubEntryPointOf(stub.ptr());
    uword size = Code::StubPayloadSizeOf(stub.ptr());
    if ((pc >= entry) && (pc < (entry + size))) {
      return true;
    }
  }
#endif  // defined(DART_DYNAMIC_MODULES)
  const Code& stub = roots->x_stub_handle(kInvokeDartCodeIndex);
  uword entry = Code::StubEntryPointOf(stub.ptr());
  uword size = Code::StubPayloadSizeOf(stub.ptr());
  return (pc >= entry) && (pc < (entry + size));
}

bool StubCode::InJumpToFrameStub(Thread* T, uword pc) {
  // T might differ from the current thread on platforms where profiling is
  // cross thread, like Mac/Windows/Fuchsia.
  Roots* roots = T->isolate_group()->roots();
  if (roots == nullptr) return false;

  const Code& stub = roots->x_stub_handle(kJumpToFrameIndex);
  if (stub.ptr() == nullptr) {
    return false;  // Still bootstrapping.
  }
  uword entry = Code::StubEntryPointOf(stub.ptr());
  uword size = Code::StubPayloadSizeOf(stub.ptr());
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
  Zone* zone = thread->zone();
  const Error& error =
      Error::Handle(zone, cls.EnsureIsAllocateFinalized(thread));
  ASSERT(error.IsNull());
  switch (cls.id()) {
    case kArrayCid:
      return StubCode::AllocateArray().ptr();
#if !defined(TARGET_ARCH_IA32)
    case kGrowableObjectArrayCid:
      return StubCode::AllocateGrowableArray().ptr();
#endif  // !defined(TARGET_ARCH_IA32)
    case kContextCid:
      return StubCode::AllocateContext().ptr();
    case kUnhandledExceptionCid:
      return StubCode::AllocateUnhandledException().ptr();
    case kMintCid:
      return StubCode::AllocateMint().ptr();
    case kDoubleCid:
      return StubCode::AllocateDouble().ptr();
    case kFloat32x4Cid:
      return StubCode::AllocateFloat32x4().ptr();
    case kFloat64x2Cid:
      return StubCode::AllocateFloat64x2().ptr();
    case kInt32x4Cid:
      return StubCode::AllocateInt32x4().ptr();
    case kClosureCid:
      return StubCode::AllocateClosure1().ptr();
    case kRecordCid:
      return StubCode::AllocateRecord().ptr();
  }
  Code& stub = Code::Handle(zone, cls.allocation_stub());
  if (stub.IsNull()) {
    compiler::ObjectPoolBuilder object_pool_builder;
    Precompiler* precompiler = Precompiler::Instance();

    compiler::ObjectPoolBuilder* wrapper =
        precompiler != nullptr ? precompiler->global_object_pool_builder()
                               : &object_pool_builder;

    const auto pool_attachment = FLAG_precompiled_mode
                                     ? Code::PoolAttachment::kNotAttachPool
                                     : Code::PoolAttachment::kAttachPool;

    auto zone = thread->zone();
    auto& allocate_object_stub = Code::ZoneHandle(zone);
    auto& allocate_object_parametrized_stub = Code::ZoneHandle(zone);
    if (FLAG_precompiled_mode) {
      allocate_object_stub = StubCode::AllocateObject().ptr();
      allocate_object_parametrized_stub =
          StubCode::AllocateObjectParameterized().ptr();
    }

    compiler::Assembler assembler(wrapper);
    CompilerState compiler_state(thread, /*is_aot=*/FLAG_precompiled_mode,
                                 /*is_optimizing=*/false);
    compiler::UnresolvedPcRelativeCalls unresolved_calls;
    const char* name = cls.ToCString();
    compiler::StubCodeCompiler stubCodeCompiler(&assembler, nullptr);
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
    thread->isolate_group()->RunWithStoppedMutators(mutator_fun);

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
  switch (class_id) {
    case kTypedDataInt8ArrayCid:
      return StubCode::AllocateInt8Array().ptr();
    case kTypedDataUint8ArrayCid:
      return StubCode::AllocateUint8Array().ptr();
    case kTypedDataUint8ClampedArrayCid:
      return StubCode::AllocateUint8ClampedArray().ptr();
    case kTypedDataInt16ArrayCid:
      return StubCode::AllocateInt16Array().ptr();
    case kTypedDataUint16ArrayCid:
      return StubCode::AllocateUint16Array().ptr();
    case kTypedDataInt32ArrayCid:
      return StubCode::AllocateInt32Array().ptr();
    case kTypedDataUint32ArrayCid:
      return StubCode::AllocateUint32Array().ptr();
    case kTypedDataInt64ArrayCid:
      return StubCode::AllocateInt64Array().ptr();
    case kTypedDataUint64ArrayCid:
      return StubCode::AllocateUint64Array().ptr();
    case kTypedDataFloat32ArrayCid:
      return StubCode::AllocateFloat32Array().ptr();
    case kTypedDataFloat64ArrayCid:
      return StubCode::AllocateFloat64Array().ptr();
    case kTypedDataFloat32x4ArrayCid:
      return StubCode::AllocateFloat32x4Array().ptr();
    case kTypedDataInt32x4ArrayCid:
      return StubCode::AllocateInt32x4Array().ptr();
    case kTypedDataFloat64x2ArrayCid:
      return StubCode::AllocateFloat64x2Array().ptr();
  }
  UNREACHABLE();
  return Code::null();
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

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

void StubCode::ForEachStub(
    const std::function<bool(const char*, uword)>& callback) {
  for (intptr_t i = 0; i < kNumStubEntries; i++) {
    if (Roots::stub_handle(i).ptr() != nullptr) {
      if (!callback(StubNames[i], Roots::stub_handle(i).EntryPoint())) {
        return;
      }
    }
  }
}

const char* StubCode::NameOfStub(uword entry_point) {
  const char* result = nullptr;
  ForEachStub(
      [&result, &entry_point](const char* name, uword stub_entry_point) {
        if (stub_entry_point == entry_point) {
          result = name;
          return false;  // Found match.
        }
        return true;  // Continue searching.
      });
  return result;
}

}  // namespace dart

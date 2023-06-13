// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <functional>

#include "platform/assert.h"

#include "vm/class_finalizer.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il_test_helper.h"
#include "vm/flags.h"
#include "vm/lockers.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/type_testing_stubs.h"
#include "vm/unit_test.h"
#include "vm/zone_text_buffer.h"

#if !defined(TARGET_ARCH_IA32)

namespace dart {

DECLARE_FLAG(int, max_subtype_cache_entries);
// Note that flags that this affects may only mutable in some modes, e.g.,
// tracing type checks can only be done in DEBUG mode.
DEFINE_FLAG(bool,
            trace_type_testing_stub_tests,
            false,
            "Trace type testing stub tests");
DEFINE_FLAG(bool,
            print_type_testing_stub_test_headers,
            true,
            "Print headers for executed type testing stub tests");

class TraceStubInvocationScope : public ValueObject {
 public:
  TraceStubInvocationScope()
      : old_trace_type_checks_(FLAG_trace_type_checks),
        old_disassemble_stubs_(FLAG_disassemble_stubs) {
    if (FLAG_trace_type_testing_stub_tests) {
#if defined(DEBUG)
      FLAG_trace_type_checks = true;
#endif
#if defined(FORCE_INCLUDE_DISASSEMBLER) || !defined(PRODUCT)
      FLAG_disassemble_stubs = true;
#endif
    }
  }
  ~TraceStubInvocationScope() {
    if (FLAG_trace_type_testing_stub_tests) {
#if defined(DEBUG)
      FLAG_trace_type_checks = old_trace_type_checks_;
#endif
#if defined(FORCE_INCLUDE_DISASSEMBLER) || !defined(PRODUCT)
      FLAG_disassemble_stubs = old_disassemble_stubs_;
#endif
    }
  }

 private:
  const bool old_trace_type_checks_;
  const bool old_disassemble_stubs_;
};

#define __ assembler->

static void GenerateInvokeTTSStub(compiler::Assembler* assembler) {
  auto calculate_breadcrumb = [](const Register& reg) {
    return 0x10 + 2 * (static_cast<intptr_t>(reg));
  };

  __ EnterDartFrame(0);

  for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
    if (((1 << i) & kDartAvailableCpuRegs) == 0) continue;
    if (((1 << i) & TypeTestABI::kAbiRegisters) != 0) continue;
    if (((1 << i) & TTSInternalRegs::kInternalRegisters) != 0) continue;
    const Register reg = static_cast<Register>(i);
    __ LoadImmediate(reg, calculate_breadcrumb(reg));
  }

  // Load the arguments into the right TTS calling convention registers.
  const intptr_t instance_offset =
      (kCallerSpSlotFromFp + 3) * compiler::target::kWordSize;
  const intptr_t inst_type_args_offset =
      (kCallerSpSlotFromFp + 2) * compiler::target::kWordSize;
  const intptr_t fun_type_args_offset =
      (kCallerSpSlotFromFp + 1) * compiler::target::kWordSize;
  const intptr_t dst_type_offset =
      (kCallerSpSlotFromFp + 0) * compiler::target::kWordSize;

  __ LoadMemoryValue(TypeTestABI::kInstanceReg, FPREG, instance_offset);
  __ LoadMemoryValue(TypeTestABI::kInstantiatorTypeArgumentsReg, FPREG,
                     inst_type_args_offset);
  __ LoadMemoryValue(TypeTestABI::kFunctionTypeArgumentsReg, FPREG,
                     fun_type_args_offset);
  __ LoadMemoryValue(TypeTestABI::kDstTypeReg, FPREG, dst_type_offset);

  const intptr_t subtype_test_cache_index = __ object_pool_builder().AddObject(
      Object::null_object(), compiler::ObjectPoolBuilderEntry::kPatchable);
  const intptr_t dst_name_index = __ object_pool_builder().AddObject(
      Symbols::OptimizedOut(), compiler::ObjectPoolBuilderEntry::kPatchable);
  ASSERT_EQUAL(subtype_test_cache_index + 1, dst_name_index);
  ASSERT(__ constant_pool_allowed());

  FlowGraphCompiler::GenerateIndirectTTSCall(
      assembler, TypeTestABI::kDstTypeReg, subtype_test_cache_index);

  // We have the guarantee that TTS preserves all input registers, if the TTS
  // handles the type test successfully.
  //
  // Let the test know which TTS abi registers were not preserved.
  ASSERT(((1 << static_cast<intptr_t>(TypeTestABI::kInstanceReg)) &
          TypeTestABI::kPreservedAbiRegisters) != 0);
  // First we check the instance register, freeing it up in case there are no
  // other safe registers to use since we need two registers: one to accumulate
  // the register mask, another to load the array address when saving the mask.
  __ LoadFromOffset(TypeTestABI::kScratchReg, FPREG, instance_offset);
  compiler::Label instance_matches, done_with_instance;
  __ CompareRegisters(TypeTestABI::kScratchReg, TypeTestABI::kInstanceReg);
  __ BranchIf(EQUAL, &instance_matches, compiler::Assembler::kNearJump);
  __ LoadImmediate(TypeTestABI::kScratchReg,
                   1 << static_cast<intptr_t>(TypeTestABI::kInstanceReg));
  __ Jump(&done_with_instance, compiler::Assembler::kNearJump);
  __ Bind(&instance_matches);
  __ LoadImmediate(TypeTestABI::kScratchReg, 0);
  __ Bind(&done_with_instance);
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
    if (((1 << i) & TypeTestABI::kPreservedAbiRegisters) == 0) continue;
    const Register reg = static_cast<Register>(i);
    compiler::Label done;
    switch (reg) {
      case TypeTestABI::kInstanceReg:
        // Skip the already handled instance register.
        continue;
      case TypeTestABI::kDstTypeReg:
        __ LoadFromOffset(TypeTestABI::kInstanceReg, FPREG, dst_type_offset);
        break;
      case TypeTestABI::kFunctionTypeArgumentsReg:
        __ LoadFromOffset(TypeTestABI::kInstanceReg, FPREG,
                          fun_type_args_offset);
        break;
      case TypeTestABI::kInstantiatorTypeArgumentsReg:
        __ LoadFromOffset(TypeTestABI::kInstanceReg, FPREG,
                          inst_type_args_offset);
        break;
      default:
        FATAL("Unexpected register %s", RegisterNames::RegisterName(reg));
        break;
    }
    __ CompareRegisters(reg, TypeTestABI::kInstanceReg);
    __ BranchIf(EQUAL, &done, compiler::Assembler::kNearJump);
    __ AddImmediate(TypeTestABI::kScratchReg, 1 << i);
    __ Bind(&done);
  }
  __ SmiTag(TypeTestABI::kScratchReg);
  __ LoadFromOffset(TypeTestABI::kInstanceReg, FPREG,
                    (kCallerSpSlotFromFp + 5) * compiler::target::kWordSize);
  __ StoreFieldToOffset(TypeTestABI::kScratchReg, TypeTestABI::kInstanceReg,
                        compiler::target::Array::element_offset(0));

  // Let the test know which non-TTS abi registers were not preserved.
  __ LoadImmediate(TypeTestABI::kScratchReg, 0);
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
    if (((1 << i) & kDartAvailableCpuRegs) == 0) continue;
    if (((1 << i) & TypeTestABI::kAbiRegisters) != 0) continue;
    const Register reg = static_cast<Register>(i);
    compiler::Label done;
    __ CompareImmediate(reg, calculate_breadcrumb(reg));
    __ BranchIf(EQUAL, &done, compiler::Assembler::kNearJump);
    __ AddImmediate(TypeTestABI::kScratchReg, 1 << i);
    __ Bind(&done);
  }
  __ SmiTag(TypeTestABI::kScratchReg);
  __ LoadFromOffset(TypeTestABI::kInstanceReg, FPREG,
                    (kCallerSpSlotFromFp + 4) * compiler::target::kWordSize);
  __ StoreFieldToOffset(TypeTestABI::kScratchReg, TypeTestABI::kInstanceReg,
                        compiler::target::Array::element_offset(0));

  // Set the return from the stub to be null.
  __ LoadObject(CallingConventions::kReturnReg, Object::null_object());
  __ LeaveDartFrame();
  __ Ret();
}

#undef __

static void FinalizeAndCanonicalize(AbstractType* type) {
  *type = ClassFinalizer::FinalizeType(*type);
  ASSERT(type->IsCanonical());
}

static void CanonicalizeTAV(TypeArguments* tav) {
  *tav = tav->Canonicalize(Thread::Current());
}

#if !defined(PRODUCT)
// Defined before CheckFailureForExistingTypeTestCacheEntry in runtime_entry.cc.
extern bool TESTING_runtime_fail_on_existing_STC_entry;
#endif

struct TTSTestCase {
  const Object& instance;
  const TypeArguments& instantiator_tav;
  const TypeArguments& function_tav;
  // Whether the result of the test should be a type error.
  const bool should_fail;
  // Whether a non-default stub will result from specialization.
  const bool should_specialize;
  // Whether the test should not be caught by the TTS, but instead cached
  // in the STC. If should_specialize is false, then the test case is cached
  // in the STC after any invocation, otherwise only on invocations that do
  // not cause a (re)specialization.
  const bool should_be_false_negative;
  // Whether a false negative that is already cached in the STC should be
  // missed by the appropriate SubtypeNTestCache stub.
  //
  // TODO(sstrickl): Remove this option when SubtypeNTestCache stubs handle
  // hash-based caches appropriately, as then no misses should be possible.
  const bool should_miss_in_stc_stub;
  // Whether the test should cause specialization of a stub that is already
  // specialized.
  const bool should_respecialize;

  TTSTestCase(const Object& obj,
              const TypeArguments& i_tav,
              const TypeArguments& f_tav,
              bool should_specialize = true,
              bool should_fail = false,
              bool should_be_false_negative = false,
              bool should_miss_in_stc_stub = false,
              bool should_respecialize = false)
      : instance(obj),
        instantiator_tav(i_tav),
        function_tav(f_tav),
        should_fail(should_fail),
        should_specialize(should_specialize),
        should_be_false_negative(should_be_false_negative),
        should_miss_in_stc_stub(should_miss_in_stc_stub),
        should_respecialize(should_respecialize) {
    // Failure is only compatible with should_specialize (for checking
    // eager specialization a la AOT mode).
    ASSERT(!should_fail || (!should_be_false_negative && !should_respecialize));
    // We can only check the STC and fail if a false negative happens.
    ASSERT(!should_miss_in_stc_stub || should_be_false_negative);
    // Respecialization can only happen for test cases that would specialize
    // and which won't end up cached in the TTS.
    ASSERT(!should_respecialize ||
           (should_specialize && !should_be_false_negative));
  }

  bool HasSameSTCEntry(const TTSTestCase& other) const {
    if (instantiator_tav.ptr() != other.instantiator_tav.ptr()) {
      return false;
    }
    if (function_tav.ptr() != other.function_tav.ptr()) {
      return false;
    }
    if (instance.IsClosure() && other.instance.IsClosure()) {
      const auto& closure = Closure::Cast(instance);
      const auto& other_closure = Closure::Cast(other.instance);
      const auto& sig = FunctionType::Handle(
          Function::Handle(closure.function()).signature());
      const auto& other_sig = FunctionType::Handle(
          Function::Handle(other_closure.function()).signature());
      return sig.ptr() == other_sig.ptr() &&
             closure.instantiator_type_arguments() ==
                 other_closure.instantiator_type_arguments() &&
             closure.function_type_arguments() ==
                 other_closure.function_type_arguments() &&
             closure.delayed_type_arguments() ==
                 other_closure.delayed_type_arguments();
    }
    const intptr_t cid = instance.GetClassId();
    const intptr_t other_cid = other.instance.GetClassId();
    if (cid != other_cid) {
      return false;
    }
    const auto& cls = Class::Handle(instance.clazz());
    if (cls.NumTypeArguments() == 0) {
      return true;
    }
    return Instance::Cast(instance).GetTypeArguments() ==
           Instance::Cast(other.instance).GetTypeArguments();
  }

  bool HasSTCEntry(const SubtypeTestCache& cache,
                   const AbstractType& dst_type,
                   Bool* out_result = nullptr,
                   intptr_t* out_index = nullptr) const {
    if (cache.IsNull()) return false;
    if (instance.IsClosure()) {
      const auto& closure = Closure::Cast(instance);
      const auto& sig = FunctionType::Handle(
          Function::Handle(closure.function()).signature());
      const auto& closure_instantiator_type_arguments =
          TypeArguments::Handle(closure.instantiator_type_arguments());
      const auto& closure_function_type_arguments =
          TypeArguments::Handle(closure.function_type_arguments());
      const auto& closure_delayed_type_arguments =
          TypeArguments::Handle(closure.delayed_type_arguments());
      return cache.HasCheck(
          sig, dst_type, closure_instantiator_type_arguments, instantiator_tav,
          function_tav, closure_function_type_arguments,
          closure_delayed_type_arguments, out_index, out_result);
    }
    const auto& id_smi = Smi::Handle(Smi::New(instance.GetClassId()));
    const auto& cls = Class::Handle(instance.clazz());
    auto& instance_type_arguments = TypeArguments::Handle();
    if (cls.NumTypeArguments() > 0) {
      instance_type_arguments = Instance::Cast(instance).GetTypeArguments();
    }
    return cache.HasCheck(id_smi, dst_type, instance_type_arguments,
                          instantiator_tav, function_tav,
                          Object::null_type_arguments(),
                          Object::null_type_arguments(), out_index, out_result);
  }

 private:
  DISALLOW_ALLOCATION();
};

// Inherits should_specialize from original.
static TTSTestCase Failure(const TTSTestCase& original) {
  return TTSTestCase(original.instance, original.instantiator_tav,
                     original.function_tav, original.should_specialize,
                     /*should_fail=*/true,
                     /*should_be_false_negative=*/false,
                     /*should_miss_in_stc_stub=*/false,
                     /*should_respecialize=*/false);
}

// Inherits should_specialize from original.
static TTSTestCase FalseNegative(const TTSTestCase& original) {
  return TTSTestCase(original.instance, original.instantiator_tav,
                     original.function_tav, original.should_specialize,
                     /*should_fail=*/false,
                     /*should_be_false_negative=*/true,
                     /*should_miss_in_stc_stub=*/false,
                     /*should_respecialize=*/false);
}

// Inherits should_specialize from original.
static TTSTestCase STCMiss(const TTSTestCase& original) {
  return TTSTestCase(original.instance, original.instantiator_tav,
                     original.function_tav, original.should_specialize,
                     /*should_fail=*/false,
                     /*should_be_false_negative=*/true,
                     /*should_miss_in_stc_stub=*/true,
                     /*should_respecialize=*/false);
}

static TTSTestCase Respecialization(const TTSTestCase& original) {
  return TTSTestCase(original.instance, original.instantiator_tav,
                     original.function_tav, /*should_specialize=*/true,
                     /*should_fail=*/false,
                     /*should_be_false_negative=*/false,
                     /*should_miss_in_stc_stub=*/false,
                     /*should_respecialize=*/true);
}

class TTSTestState : public ValueObject {
 public:
  TTSTestState(Thread* thread, const AbstractType& type)
      : thread_(thread),
        type_(AbstractType::Handle(zone(), type.ptr())),
        modified_abi_regs_box_(Array::Handle(zone(), Array::New(1))),
        modified_rest_regs_box_(Array::Handle(zone(), Array::New(1))),
        tts_invoker_(
            Code::Handle(zone(), CreateInvocationStub(thread_, zone()))),
        pool_(ObjectPool::Handle(zone(), tts_invoker_.object_pool())),
        arguments_descriptor_(
            Array::Handle(ArgumentsDescriptor::NewBoxed(0, 6))),
        previous_tts_stub_(Code::Handle(zone())),
        previous_stc_(SubtypeTestCache::Handle(zone())),
        last_arguments_(Array::Handle(zone())),
        last_tested_type_(AbstractType::Handle(zone())),
        new_tts_stub_(Code::Handle(zone())),
        last_stc_(SubtypeTestCache::Handle(zone())),
        last_result_(Object::Handle(zone())) {
    if (FLAG_print_type_testing_stub_test_headers) {
      THR_Print("Creating test state for type %s\n", type.ToCString());
    }
  }

  Zone* zone() const { return thread_->zone(); }
  const SubtypeTestCache& last_stc() const { return last_stc_; }
  // For cases where the STC may have been reset/removed, like reloading.
  const SubtypeTestCachePtr current_stc() const {
    return SubtypeTestCache::RawCast(pool_.ObjectAt(kSubtypeTestCacheIndex));
  }

  AbstractTypePtr TypeToTest(const TTSTestCase& test_case) const {
    if (type_.IsTypeParameter()) {
      return TypeParameter::Cast(type_).GetFromTypeArguments(
          test_case.instantiator_tav, test_case.function_tav);
    }
    return type_.ptr();
  }

  void ClearCache() {
    pool_.SetObjectAt(kSubtypeTestCacheIndex, Object::null_object());
  }

  void InvokeEagerlySpecializedStub(const TTSTestCase& test_case) {
    ASSERT(!test_case.should_respecialize);  // No respecialization possible.
    last_tested_type_ = TypeToTest(test_case);
    const auto& default_stub =
        Code::Handle(zone(), TypeTestingStubGenerator::DefaultCodeForType(
                                 last_tested_type_, /*lazy_specialize=*/false));
    {
      // To make sure we output the disassembled stub if desired.
      TraceStubInvocationScope scope;
      previous_tts_stub_ = TypeTestingStubGenerator::SpecializeStubFor(
          thread_, last_tested_type_);
    }
    EXPECT_EQ(test_case.should_specialize,
              previous_tts_stub_.ptr() != default_stub.ptr());
    last_tested_type_.SetTypeTestingStub(previous_tts_stub_);
    PrintInvocationHeader("eagerly specialized", test_case);
    InvokeStubHelper(test_case);
    // Treat it as a failure if the stub respecializes, since we're attempting
    // to simulate AOT mode.
    EXPECT(previous_tts_stub_.ptr() == new_tts_stub_.ptr());
  }

  void InvokeLazilySpecializedStub(const TTSTestCase& test_case) {
    ASSERT(!test_case.should_respecialize);  // No respecialization possible.
    last_tested_type_ = TypeToTest(test_case);
    const auto& default_stub =
        Code::Handle(zone(), TypeTestingStubGenerator::DefaultCodeForType(
                                 last_tested_type_, /*lazy_specialize=*/false));
    const auto& specializing_stub =
        Code::Handle(zone(), TypeTestingStubGenerator::DefaultCodeForType(
                                 last_tested_type_, /*lazy_specialize=*/true));
    last_tested_type_.SetTypeTestingStub(specializing_stub);
    PrintInvocationHeader("lazy specialized", test_case);
    InvokeStubHelper(test_case,
                     /*is_lazy_specialization=*/test_case.should_specialize);
    if (test_case.should_fail || test_case.instance.IsNull()) {
      // We only specialize if we go to runtime and the runtime check
      // succeeds. The lazy specialization stub for nullable types has a
      // special fast case for null that skips the runtime.
      EXPECT(new_tts_stub_.ptr() == specializing_stub.ptr());
    } else if (test_case.should_specialize) {
      // Specializing test cases should never result in a default TTS.
      EXPECT(new_tts_stub_.ptr() != default_stub.ptr());
    } else {
      // Non-specializing test cases should result in a default TTS.
      EXPECT(new_tts_stub_.ptr() == default_stub.ptr());
    }
  }

  void InvokeExistingStub(const TTSTestCase& test_case) {
    last_tested_type_ = TypeToTest(test_case);
    PrintInvocationHeader("existing", test_case);
    InvokeStubHelper(test_case);
    // Only respecialization should result in a new stub.
    EXPECT_EQ(test_case.should_respecialize,
              previous_tts_stub_.ptr() != new_tts_stub_.ptr());
  }

 private:
  static constexpr intptr_t kSubtypeTestCacheIndex = 0;

  SmiPtr modified_abi_regs() const {
    if (modified_abi_regs_box_.At(0)->IsHeapObject()) return Smi::null();
    return Smi::RawCast(modified_abi_regs_box_.At(0));
  }
  SmiPtr modified_rest_regs() const {
    if (modified_rest_regs_box_.At(0)->IsHeapObject()) return Smi::null();
    return Smi::RawCast(modified_rest_regs_box_.At(0));
  }

  void PrintInvocationHeader(const char* stub_type,
                             const TTSTestCase& test_case) {
    if (!FLAG_print_type_testing_stub_test_headers) return;
    LogBlock lb;
    const auto& tts = Code::Handle(zone(), last_tested_type_.type_test_stub());
    auto* const stub_name = StubCode::NameOfStub(tts.EntryPoint());
    THR_Print("Testing %s %s stub for type %s\n",
              stub_name == nullptr ? "optimized" : stub_name, stub_type,
              last_tested_type_.ToCString());
    if (last_tested_type_.ptr() != type_.ptr()) {
      THR_Print("  Original type: %s\n", type_.ToCString());
    }
    THR_Print("  Instance: %s\n", test_case.instance.ToCString());
    THR_Print("  Instantiator TAV: %s\n",
              test_case.instantiator_tav.ToCString());
    THR_Print("  Function TAV: %s\n", test_case.function_tav.ToCString());
    THR_Print("  Should fail: %s\n", test_case.should_fail ? "true" : "false");
    THR_Print("  Should specialize: %s\n",
              test_case.should_specialize ? "true" : "false");
    THR_Print("  Should be false negative: %s\n",
              test_case.should_be_false_negative ? "true" : "false");
    THR_Print("  Should miss in STC stub: %s\n",
              test_case.should_miss_in_stc_stub ? "true" : "false");
    THR_Print("  Should respecialize: %s\n",
              test_case.should_respecialize ? "true" : "false");
  }

  static CodePtr CreateInvocationStub(Thread* thread, Zone* zone) {
    const auto& klass = Class::Handle(
        zone, thread->isolate_group()->class_table()->At(kInstanceCid));
    const auto& symbol = String::Handle(
        zone, Symbols::New(thread, OS::SCreate(zone, "TTSTest")));
    const auto& signature = FunctionType::Handle(zone, FunctionType::New());
    const auto& function = Function::Handle(
        zone, Function::New(
                  signature, symbol, UntaggedFunction::kRegularFunction, false,
                  false, false, false, false, klass, TokenPosition::kNoSource));

    TraceStubInvocationScope scope;
    compiler::ObjectPoolBuilder pool_builder;
    SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
    compiler::Assembler assembler(&pool_builder);
    GenerateInvokeTTSStub(&assembler);
    const Code& invoke_tts = Code::Handle(Code::FinalizeCodeAndNotify(
        "InvokeTTS", nullptr, &assembler, Code::PoolAttachment::kNotAttachPool,
        /*optimized=*/false));

    const auto& pool =
        ObjectPool::Handle(zone, ObjectPool::NewFromBuilder(pool_builder));
    invoke_tts.set_object_pool(pool.ptr());
    invoke_tts.set_owner(function);
    invoke_tts.set_exception_handlers(
        ExceptionHandlers::Handle(zone, ExceptionHandlers::New(0)));
    EXPECT_EQ(2, pool.Length());

    if (FLAG_support_disassembler && FLAG_disassemble_stubs) {
      Disassembler::DisassembleStub(symbol.ToCString(), invoke_tts);
    }

    return invoke_tts.ptr();
  }

  void InvokeStubHelper(const TTSTestCase& test_case,
                        bool is_lazy_specialization = false) {
    ASSERT(test_case.instantiator_tav.IsNull() ||
           test_case.instantiator_tav.IsCanonical());
    ASSERT(test_case.function_tav.IsNull() ||
           test_case.function_tav.IsCanonical());

    modified_abi_regs_box_.SetAt(0, Object::null_object());
    modified_rest_regs_box_.SetAt(0, Object::null_object());

    last_arguments_ = Array::New(6);
    last_arguments_.SetAt(0, modified_abi_regs_box_);
    last_arguments_.SetAt(1, modified_rest_regs_box_);
    last_arguments_.SetAt(2, test_case.instance);
    last_arguments_.SetAt(3, test_case.instantiator_tav);
    last_arguments_.SetAt(4, test_case.function_tav);
    last_arguments_.SetAt(5, type_);

    previous_tts_stub_ = last_tested_type_.type_test_stub();
    previous_stc_ = current_stc();
    {
      SafepointMutexLocker ml(
          thread_->isolate_group()->subtype_test_cache_mutex());
      previous_stc_ = previous_stc_.Copy(thread_);
    }
    const bool previous_has_entry = test_case.HasSTCEntry(previous_stc_, type_);
#if !defined(PRODUCT)
    // If there's an existing STC entry for this test case, then we should
    // never hit the runtime unless this test explicitly expects the stub to
    // miss the entry.
    if (!test_case.should_miss_in_stc_stub && previous_has_entry) {
      TESTING_runtime_fail_on_existing_STC_entry = true;
    }
#endif
    {
      TraceStubInvocationScope scope;
      last_result_ = DartEntry::InvokeCode(tts_invoker_, arguments_descriptor_,
                                           last_arguments_, thread_);
    }
#if !defined(PRODUCT)
    // Reset runtime failure flag.
    TESTING_runtime_fail_on_existing_STC_entry = false;
#endif
    new_tts_stub_ = last_tested_type_.type_test_stub();
    last_stc_ = current_stc();
    if (test_case.should_fail) {
      EXPECT(!last_result_.IsNull());
      EXPECT(last_result_.IsError());
      EXPECT(last_result_.IsUnhandledException());
      if (last_result_.IsUnhandledException()) {
        const auto& error = Instance::Handle(
            UnhandledException::Cast(last_result_).exception());
        EXPECT(strstr(error.ToCString(), "_TypeError"));
      }
    } else {
      EXPECT(last_result_.IsNull());
      if (!last_result_.IsNull()) {
        EXPECT(last_result_.IsError());
        EXPECT(last_result_.IsUnhandledException());
        if (last_result_.IsUnhandledException()) {
          const auto& exception = UnhandledException::Cast(last_result_);
          dart::Expect(__FILE__, __LINE__)
              .Fail("%s", exception.ToErrorCString());
        }
      } else {
        EXPECT(new_tts_stub_.ptr() != StubCode::LazySpecializeTypeTest().ptr());
        ReportModifiedRegisters(modified_abi_regs());
        // If we shouldn't go to the runtime, report any unexpected changes in
        // non-ABI registers.
        if (!is_lazy_specialization && !test_case.should_respecialize &&
            (!test_case.should_be_false_negative || previous_has_entry)) {
          ReportModifiedRegisters(modified_rest_regs());
        }
      }
    }
    ReportUnexpectedSTCChanges(test_case, is_lazy_specialization);
  }

  static void ReportModifiedRegisters(SmiPtr encoded_reg_mask) {
    if (encoded_reg_mask == Smi::null()) {
      dart::Expect(__FILE__, __LINE__).Fail("No modified register information");
      return;
    }
    const intptr_t reg_mask = Smi::Value(encoded_reg_mask);
    for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
      if (((1 << i) & reg_mask) != 0) {
        const Register reg = static_cast<Register>(i);
        dart::Expect(__FILE__, __LINE__)
            .Fail("%s was modified", RegisterNames::RegisterName(reg));
      }
    }
  }

  void ReportMissingOrChangedEntries(const SubtypeTestCache& old_cache,
                                     const SubtypeTestCache& new_cache) {
    auto& cid_or_sig = Object::Handle(zone());
    auto& type = AbstractType::Handle(zone());
    auto& instance_type_args = TypeArguments::Handle(zone());
    auto& instantiator_type_args = TypeArguments::Handle(zone());
    auto& function_type_args = TypeArguments::Handle(zone());
    auto& instance_parent_type_args = TypeArguments::Handle(zone());
    auto& instance_delayed_type_args = TypeArguments::Handle(zone());
    auto& old_result = Bool::Handle(zone());
    auto& new_result = Bool::Handle(zone());
    SafepointMutexLocker ml(
        thread_->isolate_group()->subtype_test_cache_mutex());
    intptr_t i = 0;
    while (old_cache.GetNextCheck(&i, &cid_or_sig, &type, &instance_type_args,
                                  &instantiator_type_args, &function_type_args,
                                  &instance_parent_type_args,
                                  &instance_delayed_type_args, &old_result)) {
      if (!new_cache.HasCheck(
              cid_or_sig, type, instance_type_args, instantiator_type_args,
              function_type_args, instance_parent_type_args,
              instance_delayed_type_args, /*index=*/nullptr, &new_result)) {
        dart::Expect(__FILE__, __LINE__)
            .Fail("New STC is missing check in old STC");
      }
      if (old_result.value() != new_result.value()) {
        dart::Expect(__FILE__, __LINE__)
            .Fail("New STC has different result from old STC");
      }
    }
  }

  void ReportUnexpectedSTCChanges(const TTSTestCase& test_case,
                                  bool is_lazy_specialization = false) {
    // Make sure should_be_false_negative is not set if respecialization is.
    ASSERT(!test_case.should_be_false_negative ||
           !test_case.should_respecialize);
    const bool hit_check_cap =
        !previous_stc_.IsNull() &&
        previous_stc_.NumberOfChecks() >= FLAG_max_subtype_cache_entries;
    const bool had_stc_entry = test_case.HasSTCEntry(previous_stc_, type_);
    const bool should_update_stc = !is_lazy_specialization &&
                                   test_case.should_be_false_negative &&
                                   !hit_check_cap;
    if (should_update_stc && !had_stc_entry) {
      // We should have changed the STC to include the new entry.
      EXPECT(!last_stc_.IsNull());
      if (!last_stc_.IsNull()) {
        EXPECT(previous_stc_.IsNull() ||
               previous_stc_.cache() != last_stc_.cache());
        // We only should have added one check.
        EXPECT_EQ(
            previous_stc_.IsNull() ? 1 : previous_stc_.NumberOfChecks() + 1,
            last_stc_.NumberOfChecks());
        if (!previous_stc_.IsNull()) {
          // Make sure all the checks in the previous STC are still there.
          ReportMissingOrChangedEntries(previous_stc_, last_stc_);
        }
      }
    } else {
      // Whatever STC existed before, if any, should be unchanged.
      if (previous_stc_.IsNull()) {
        EXPECT(last_stc_.IsNull());
      } else {
        EXPECT(!last_stc_.IsNull());
        const auto& previous_array =
            Array::Handle(zone(), previous_stc_.cache());
        const auto& last_array = Array::Handle(zone(), last_stc_.cache());
        EXPECT(last_array.Equals(previous_array));
      }
    }

    // False negatives should always be an STC hit when not lazily
    // (re)specializing.
    const bool has_stc_entry = test_case.HasSTCEntry(last_stc_, type_);
    if ((!should_update_stc && has_stc_entry) ||
        (should_update_stc && !has_stc_entry)) {
      ZoneTextBuffer buffer(zone());
      buffer.Printf(
          "%s STC entry for:\n  instance:%s\n  destination type: %s",
          test_case.should_be_false_negative ? "Expected" : "Did not expect",
          test_case.instance.ToCString(), type_.ToCString());
      if (last_tested_type_.ptr() != type_.ptr()) {
        buffer.Printf("\n  tested type: %s", last_tested_type_.ToCString());
      }
      buffer.AddString("\ngot:");
      if (last_stc_.IsNull()) {
        buffer.AddString(" null");
      } else {
        buffer.AddString("\n");
        SafepointMutexLocker ml(
            thread_->isolate_group()->subtype_test_cache_mutex());
        last_stc_.WriteToBuffer(zone(), &buffer, "  ");
      }
      dart::Expect(__FILE__, __LINE__).Fail("%s", buffer.buffer());
    }
  }

  Thread* const thread_;
  const AbstractType& type_;
  const Array& modified_abi_regs_box_;
  const Array& modified_rest_regs_box_;
  const Code& tts_invoker_;
  const ObjectPool& pool_;
  const Array& arguments_descriptor_;
  Code& previous_tts_stub_;
  SubtypeTestCache& previous_stc_;
  Array& last_arguments_;
  AbstractType& last_tested_type_;
  Code& new_tts_stub_;
  SubtypeTestCache& last_stc_;
  Object& last_result_;
};

// Tests three situations in turn with the test case and with an
// appropriate null object test:
// 1) Install the lazy specialization stub for JIT and test.
// 2) Test again without installing a stub, so using the stub resulting from 1.
// 3) Install an eagerly specialized stub, similar to AOT mode but keeping any
//    STC created by the earlier steps, and test.
static void RunTTSTest(const AbstractType& dst_type,
                       const TTSTestCase& test_case) {
  bool null_should_fail = !Instance::NullIsAssignableTo(
      dst_type, test_case.instantiator_tav, test_case.function_tav);

  const TTSTestCase null_test(
      Instance::Handle(), test_case.instantiator_tav, test_case.function_tav,
      test_case.should_specialize, null_should_fail,
      // Null is never a false negative.
      /*should_be_false_negative=*/false,
      // Since null is never a false negative, it can't trigger
      // respecialization.
      /*should_respecialize=*/false);

  TTSTestState state(Thread::Current(), dst_type);
  // First check the null case. This should _never_ create an STC.
  state.InvokeLazilySpecializedStub(null_test);
  state.InvokeExistingStub(null_test);
  state.InvokeEagerlySpecializedStub(null_test);
  EXPECT(state.last_stc().IsNull());

  // Now run the actual test case.
  state.InvokeLazilySpecializedStub(test_case);
  state.InvokeExistingStub(test_case);
  state.InvokeEagerlySpecializedStub(test_case);
}

const char* kSubtypeRangeCheckScript =
    R"(
      class I<T, U> {}
      class I2 {}

      class Base<T> {}

      class A extends Base<int> {}
      class A1 extends A implements I2 {}
      class A2<T> extends A implements I<int, T> {}

      class B extends Base<String> {}
      class B1 extends B implements I2 {}
      class B2<T> extends B implements I<T, String> {}

      genericFun<A, B>() {}

      createI() => I<int, String>();
      createI2() => I2();
      createBaseInt() => Base<int>();
      createBaseNull() => Base<Null>();
      createBaseNever() => Base<Never>();
      createA() => A();
      createA1() => A1();
      createA2() => A2<int>();
      createB() => B();
      createB1() => B1();
      createB2() => B2<int>();
      createBaseIStringDouble() => Base<I<String, double>>();
      createBaseA2Int() => Base<A2<int>>();
      createBaseA2A1() => Base<A2<A1>>();
      createBaseB2Int() => Base<B2<int>>();
)";

ISOLATE_UNIT_TEST_CASE(TTS_SubtypeRangeCheck) {
  const auto& root_library =
      Library::Handle(LoadTestScript(kSubtypeRangeCheckScript));
  const auto& class_a = Class::Handle(GetClass(root_library, "A"));
  const auto& class_base = Class::Handle(GetClass(root_library, "Base"));
  const auto& class_i = Class::Handle(GetClass(root_library, "I"));
  const auto& class_i2 = Class::Handle(GetClass(root_library, "I2"));

  const auto& obj_i = Object::Handle(Invoke(root_library, "createI"));
  const auto& obj_i2 = Object::Handle(Invoke(root_library, "createI2"));
  const auto& obj_base_int =
      Object::Handle(Invoke(root_library, "createBaseInt"));
  const auto& obj_base_null =
      Object::Handle(Invoke(root_library, "createBaseNull"));
  const auto& obj_base_never =
      Object::Handle(Invoke(root_library, "createBaseNever"));
  const auto& obj_a = Object::Handle(Invoke(root_library, "createA"));
  const auto& obj_a1 = Object::Handle(Invoke(root_library, "createA1"));
  const auto& obj_a2 = Object::Handle(Invoke(root_library, "createA2"));
  const auto& obj_b = Object::Handle(Invoke(root_library, "createB"));
  const auto& obj_b1 = Object::Handle(Invoke(root_library, "createB1"));
  const auto& obj_b2 = Object::Handle(Invoke(root_library, "createB2"));

  const auto& type_dynamic = Type::Handle(Type::DynamicType());
  auto& type_object = Type::Handle(Type::ObjectType());
  type_object = type_object.ToNullability(Nullability::kNullable, Heap::kNew);

  const auto& tav_null = TypeArguments::Handle(TypeArguments::null());

  auto& tav_object = TypeArguments::Handle(TypeArguments::New(1));
  tav_object.SetTypeAt(0, type_object);
  CanonicalizeTAV(&tav_object);

  auto& tav_object_dynamic = TypeArguments::Handle(TypeArguments::New(2));
  tav_object_dynamic.SetTypeAt(0, type_object);
  tav_object_dynamic.SetTypeAt(1, type_dynamic);
  CanonicalizeTAV(&tav_object_dynamic);

  auto& tav_dynamic_t = TypeArguments::Handle(TypeArguments::New(2));
  tav_dynamic_t.SetTypeAt(0, type_dynamic);
  tav_dynamic_t.SetTypeAt(
      1, TypeParameter::Handle(GetClassTypeParameter(class_base, 0)));
  CanonicalizeTAV(&tav_dynamic_t);

  // We will generate specialized TTS for instantiated interface types
  // where there are no type arguments or the type arguments are top
  // types.
  //
  //   obj as A                   // Subclass ranges
  //   obj as Base<Object?>       // Subclass ranges with top-type tav
  //   obj as I2                  // Subtype ranges
  //   obj as I<Object?, dynamic> // Subtype ranges with top-type tav
  //

  // <...> as A
  const auto& type_a = AbstractType::Handle(class_a.RareType());
  RunTTSTest(type_a, Failure({obj_i, tav_null, tav_null}));
  RunTTSTest(type_a, Failure({obj_i2, tav_null, tav_null}));
  RunTTSTest(type_a, Failure({obj_base_int, tav_null, tav_null}));
  RunTTSTest(type_a, {obj_a, tav_null, tav_null});
  RunTTSTest(type_a, {obj_a1, tav_null, tav_null});
  RunTTSTest(type_a, {obj_a2, tav_null, tav_null});
  RunTTSTest(type_a, Failure({obj_b, tav_null, tav_null}));
  RunTTSTest(type_a, Failure({obj_b1, tav_null, tav_null}));
  RunTTSTest(type_a, Failure({obj_b2, tav_null, tav_null}));

  // <...> as Base<Object?>
  auto& type_base = AbstractType::Handle(Type::New(class_base, tav_object));
  FinalizeAndCanonicalize(&type_base);
  RunTTSTest(type_base, Failure({obj_i, tav_null, tav_null}));
  RunTTSTest(type_base, Failure({obj_i2, tav_null, tav_null}));
  RunTTSTest(type_base, {obj_base_int, tav_null, tav_null});
  RunTTSTest(type_base, {obj_base_null, tav_null, tav_null});
  RunTTSTest(type_base, {obj_a, tav_null, tav_null});
  RunTTSTest(type_base, {obj_a1, tav_null, tav_null});
  RunTTSTest(type_base, {obj_a2, tav_null, tav_null});
  RunTTSTest(type_base, {obj_b, tav_null, tav_null});
  RunTTSTest(type_base, {obj_b1, tav_null, tav_null});
  RunTTSTest(type_base, {obj_b2, tav_null, tav_null});

  // Base<Null|Never> as Base<int?>
  // This is a regression test verifying that we don't fall through into
  // runtime for Null and Never.
  auto& type_nullable_int = Type::Handle(Type::IntType());
  type_nullable_int = type_nullable_int.ToNullability(
      TestCase::IsNNBD() ? Nullability::kNullable : Nullability::kLegacy,
      Heap::kNew);
  auto& tav_nullable_int = TypeArguments::Handle(TypeArguments::New(1));
  tav_nullable_int.SetTypeAt(0, type_nullable_int);
  CanonicalizeTAV(&tav_nullable_int);
  auto& type_base_nullable_int =
      AbstractType::Handle(Type::New(class_base, tav_nullable_int));
  FinalizeAndCanonicalize(&type_base_nullable_int);
  RunTTSTest(type_base_nullable_int, {obj_base_null, tav_null, tav_null});
  RunTTSTest(type_base_nullable_int, {obj_base_never, tav_null, tav_null});

  if (TestCase::IsNNBD()) {
    // Base<Null|Never> as Base<int>
    auto& type_int = Type::Handle(Type::IntType());
    type_int = type_int.ToNullability(Nullability::kNonNullable, Heap::kNew);
    auto& tav_int = TypeArguments::Handle(TypeArguments::New(1));
    tav_int.SetTypeAt(0, type_int);
    CanonicalizeTAV(&tav_int);
    auto& type_base_int = Type::Handle(Type::New(class_base, tav_int));
    type_base_int =
        type_base_int.ToNullability(Nullability::kNonNullable, Heap::kNew);
    FinalizeAndCanonicalize(&type_base_int);
    if (IsolateGroup::Current()->null_safety()) {
      RunTTSTest(type_base_int, Failure({obj_base_null, tav_null, tav_null}));
    }
    RunTTSTest(type_base_int, {obj_base_never, tav_null, tav_null});
  }

  // <...> as I2
  const auto& type_i2 = AbstractType::Handle(class_i2.RareType());
  RunTTSTest(type_i2, Failure({obj_i, tav_null, tav_null}));
  RunTTSTest(type_i2, {obj_i2, tav_null, tav_null});
  RunTTSTest(type_i2, Failure({obj_base_int, tav_null, tav_null}));
  RunTTSTest(type_i2, Failure({obj_a, tav_null, tav_null}));
  RunTTSTest(type_i2, {obj_a1, tav_null, tav_null});
  RunTTSTest(type_i2, Failure({obj_a2, tav_null, tav_null}));
  RunTTSTest(type_i2, Failure({obj_b, tav_null, tav_null}));
  RunTTSTest(type_i2, {obj_b1, tav_null, tav_null});
  RunTTSTest(type_i2, Failure({obj_b2, tav_null, tav_null}));

  // <...> as I<Object, dynamic>
  auto& type_i_object_dynamic =
      AbstractType::Handle(Type::New(class_i, tav_object_dynamic));
  FinalizeAndCanonicalize(&type_i_object_dynamic);
  RunTTSTest(type_i_object_dynamic, {obj_i, tav_null, tav_null});
  RunTTSTest(type_i_object_dynamic, Failure({obj_i2, tav_null, tav_null}));
  RunTTSTest(type_i_object_dynamic,
             Failure({obj_base_int, tav_null, tav_null}));
  RunTTSTest(type_i_object_dynamic, Failure({obj_a, tav_null, tav_null}));
  RunTTSTest(type_i_object_dynamic, Failure({obj_a1, tav_null, tav_null}));
  RunTTSTest(type_i_object_dynamic, {obj_a2, tav_null, tav_null});
  RunTTSTest(type_i_object_dynamic, Failure({obj_b, tav_null, tav_null}));
  RunTTSTest(type_i_object_dynamic, Failure({obj_b1, tav_null, tav_null}));
  RunTTSTest(type_i_object_dynamic, {obj_b2, tav_null, tav_null});

  // We do generate TTSes for uninstantiated types when we need to use
  // subtype range checks for the class of the interface type, but the TTS
  // may be partial (returns a false negative in some cases that means going
  // to the STC/runtime).
  //
  //   obj as I<dynamic, T>
  //
  auto& type_dynamic_t =
      AbstractType::Handle(Type::New(class_i, tav_dynamic_t));
  FinalizeAndCanonicalize(&type_dynamic_t);
  RunTTSTest(type_dynamic_t, {obj_i, tav_object, tav_null});
  RunTTSTest(type_dynamic_t, Failure({obj_i2, tav_object, tav_null}));
  RunTTSTest(type_dynamic_t, Failure({obj_base_int, tav_object, tav_null}));
  RunTTSTest(type_dynamic_t, Failure({obj_a, tav_object, tav_null}));
  RunTTSTest(type_dynamic_t, Failure({obj_a1, tav_object, tav_null}));
  RunTTSTest(type_dynamic_t, {obj_a2, tav_object, tav_null});
  RunTTSTest(type_dynamic_t, Failure({obj_b, tav_object, tav_null}));
  RunTTSTest(type_dynamic_t, Failure({obj_b1, tav_object, tav_null}));
  RunTTSTest(type_dynamic_t, FalseNegative({obj_b2, tav_object, tav_null}));

  // obj as Object (with null safety)
  auto isolate_group = IsolateGroup::Current();
  if (isolate_group->null_safety()) {
    auto& type_non_nullable_object =
        Type::Handle(isolate_group->object_store()->non_nullable_object_type());
    RunTTSTest(type_non_nullable_object, {obj_a, tav_null, tav_null});
    RunTTSTest(type_non_nullable_object,
               Failure({Object::null_object(), tav_null, tav_null}));
  }
}

ISOLATE_UNIT_TEST_CASE(TTS_GenericSubtypeRangeCheck) {
  const auto& root_library =
      Library::Handle(LoadTestScript(kSubtypeRangeCheckScript));
  const auto& class_a1 = Class::Handle(GetClass(root_library, "A1"));
  const auto& class_a2 = Class::Handle(GetClass(root_library, "A2"));
  const auto& class_base = Class::Handle(GetClass(root_library, "Base"));
  const auto& class_i = Class::Handle(GetClass(root_library, "I"));
  const auto& fun_generic =
      Function::Handle(GetFunction(root_library, "genericFun"));

  const auto& obj_i = Object::Handle(Invoke(root_library, "createI"));
  const auto& obj_i2 = Object::Handle(Invoke(root_library, "createI2"));
  const auto& obj_base_int =
      Object::Handle(Invoke(root_library, "createBaseInt"));
  const auto& obj_a = Object::Handle(Invoke(root_library, "createA"));
  const auto& obj_a1 = Object::Handle(Invoke(root_library, "createA1"));
  const auto& obj_a2 = Object::Handle(Invoke(root_library, "createA2"));
  const auto& obj_b = Object::Handle(Invoke(root_library, "createB"));
  const auto& obj_b1 = Object::Handle(Invoke(root_library, "createB1"));
  const auto& obj_b2 = Object::Handle(Invoke(root_library, "createB2"));
  const auto& obj_basea2int =
      Object::Handle(Invoke(root_library, "createBaseA2Int"));
  const auto& obj_basea2a1 =
      Object::Handle(Invoke(root_library, "createBaseA2A1"));
  const auto& obj_baseb2int =
      Object::Handle(Invoke(root_library, "createBaseB2Int"));
  const auto& obj_baseistringdouble =
      Object::Handle(Invoke(root_library, "createBaseIStringDouble"));

  const auto& type_dynamic = Type::Handle(Type::DynamicType());
  auto& type_int = Type::Handle(Type::IntType());
  if (!TestCase::IsNNBD()) {
    type_int = type_int.ToNullability(Nullability::kLegacy, Heap::kNew);
  }
  auto& type_string = Type::Handle(Type::StringType());
  if (!TestCase::IsNNBD()) {
    type_string = type_string.ToNullability(Nullability::kLegacy, Heap::kNew);
  }
  auto& type_object = Type::Handle(Type::ObjectType());
  type_object = type_object.ToNullability(
      TestCase::IsNNBD() ? Nullability::kNullable : Nullability::kLegacy,
      Heap::kNew);
  auto& type_a1 = Type::Handle(class_a1.DeclarationType());
  if (!TestCase::IsNNBD()) {
    type_a1 = type_a1.ToNullability(Nullability::kLegacy, Heap::kNew);
  }
  FinalizeAndCanonicalize(&type_a1);

  const auto& tav_null = TypeArguments::Handle(TypeArguments::null());

  auto& tav_object_dynamic = TypeArguments::Handle(TypeArguments::New(2));
  tav_object_dynamic.SetTypeAt(0, type_object);
  tav_object_dynamic.SetTypeAt(1, type_dynamic);
  CanonicalizeTAV(&tav_object_dynamic);

  auto& tav_dynamic_int = TypeArguments::Handle(TypeArguments::New(2));
  tav_dynamic_int.SetTypeAt(0, type_dynamic);
  tav_dynamic_int.SetTypeAt(1, type_int);
  CanonicalizeTAV(&tav_dynamic_int);

  auto& tav_dynamic_string = TypeArguments::Handle(TypeArguments::New(2));
  tav_dynamic_string.SetTypeAt(0, type_dynamic);
  tav_dynamic_string.SetTypeAt(1, type_string);
  CanonicalizeTAV(&tav_dynamic_string);

  auto& tav_int = TypeArguments::Handle(TypeArguments::New(1));
  tav_int.SetTypeAt(0, type_int);
  CanonicalizeTAV(&tav_int);

  auto& type_i_object_dynamic =
      AbstractType::Handle(Type::New(class_i, tav_object_dynamic));
  FinalizeAndCanonicalize(&type_i_object_dynamic);
  const auto& tav_iod = TypeArguments::Handle(TypeArguments::New(1));
  tav_iod.SetTypeAt(0, type_i_object_dynamic);

  // We will generate specialized TTS for instantiated interface types
  // where there are no type arguments or the type arguments are top
  // types.
  //
  //   obj as Base<I<Object, dynamic>>   // Subclass ranges for Base, subtype
  //                                     // ranges tav arguments.
  //   obj as Base<T>                    // Subclass ranges for Base, type
  //                                     // equality for instantiator type arg T
  //   obj as Base<B>                    // Subclass ranges for Base, type
  //                                     // equality for function type arg B.
  //

  // <...> as Base<I<Object, dynamic>>
  auto& type_base_i_object_dynamic =
      AbstractType::Handle(Type::New(class_base, tav_iod));
  FinalizeAndCanonicalize(&type_base_i_object_dynamic);
  RunTTSTest(type_base_i_object_dynamic, {obj_baseb2int, tav_null, tav_null});
  RunTTSTest(type_base_i_object_dynamic,
             {obj_baseistringdouble, tav_null, tav_null});
  RunTTSTest(type_base_i_object_dynamic, Failure({obj_a, tav_null, tav_null}));
  RunTTSTest(type_base_i_object_dynamic, Failure({obj_a1, tav_null, tav_null}));
  RunTTSTest(type_base_i_object_dynamic, Failure({obj_a2, tav_null, tav_null}));
  RunTTSTest(type_base_i_object_dynamic, Failure({obj_b, tav_null, tav_null}));
  RunTTSTest(type_base_i_object_dynamic, Failure({obj_b1, tav_null, tav_null}));
  RunTTSTest(type_base_i_object_dynamic, Failure({obj_b2, tav_null, tav_null}));

  // <...> as Base<T>  with T instantiantiator type parameter (T == int)
  const auto& tav_baset = TypeArguments::Handle(TypeArguments::New(1));
  tav_baset.SetTypeAt(
      0, TypeParameter::Handle(GetClassTypeParameter(class_base, 0)));
  auto& type_base_t = AbstractType::Handle(Type::New(class_base, tav_baset));
  FinalizeAndCanonicalize(&type_base_t);
  RunTTSTest(type_base_t, {obj_base_int, tav_int, tav_null});
  RunTTSTest(type_base_t, Failure({obj_baseistringdouble, tav_int, tav_null}));

  // <...> as Base<B>  with B function type parameter
  const auto& tav_baseb = TypeArguments::Handle(TypeArguments::New(1));
  tav_baseb.SetTypeAt(
      0, TypeParameter::Handle(GetFunctionTypeParameter(fun_generic, 1)));
  auto& type_base_b = AbstractType::Handle(Type::New(class_base, tav_baseb));
  FinalizeAndCanonicalize(&type_base_b);
  // With B == int
  RunTTSTest(type_base_b, {obj_base_int, tav_null, tav_dynamic_int});
  RunTTSTest(type_base_b,
             Failure({obj_baseistringdouble, tav_null, tav_dynamic_int}));
  // With B == dynamic (null vector)
  RunTTSTest(type_base_b, {obj_base_int, tav_null, tav_null});
  RunTTSTest(type_base_b, Failure({obj_i2, tav_null, tav_null}));

  // We generate TTS for implemented classes and uninstantiated types, but
  // any class that implements the type class but does not match in both
  // instance TAV offset and type argument indices is guaranteed to be a
  // false negative.
  //
  //   obj as I<dynamic, String>       // I is generic & implemented.
  //   obj as Base<A2<T>>              // A2<T> is not instantiated.
  //   obj as Base<A2<A1>>             // A2<A1> is not a rare type.
  //

  //   <...> as I<dynamic, String>
  RELEASE_ASSERT(class_i.is_implemented());
  auto& type_i_dynamic_string =
      Type::Handle(Type::New(class_i, tav_dynamic_string));
  type_i_dynamic_string = type_i_dynamic_string.ToNullability(
      Nullability::kNonNullable, Heap::kNew);
  FinalizeAndCanonicalize(&type_i_dynamic_string);
  RunTTSTest(type_i_dynamic_string, {obj_i, tav_null, tav_null});
  RunTTSTest(type_i_dynamic_string,
             Failure({obj_base_int, tav_null, tav_null}));

  //   <...> as Base<A2<T>>
  const auto& tav_t = TypeArguments::Handle(TypeArguments::New(1));
  tav_t.SetTypeAt(0,
                  TypeParameter::Handle(GetClassTypeParameter(class_base, 0)));
  auto& type_a2_t = Type::Handle(Type::New(class_a2, tav_t));
  type_a2_t = type_a2_t.ToNullability(Nullability::kLegacy, Heap::kNew);
  FinalizeAndCanonicalize(&type_a2_t);
  const auto& tav_a2_t = TypeArguments::Handle(TypeArguments::New(1));
  tav_a2_t.SetTypeAt(0, type_a2_t);
  auto& type_base_a2_t = Type::Handle(Type::New(class_base, tav_a2_t));
  type_base_a2_t =
      type_base_a2_t.ToNullability(Nullability::kNonNullable, Heap::kNew);
  FinalizeAndCanonicalize(&type_base_a2_t);
  RunTTSTest(type_base_a2_t, FalseNegative({obj_basea2int, tav_null, tav_null,
                                            /*should_specialize=*/false}));
  RunTTSTest(type_base_a2_t, Failure({obj_base_int, tav_null, tav_null,
                                      /*should_specialize=*/false}));

  //   <...> as Base<A2<A1>>
  const auto& tav_a1 = TypeArguments::Handle(TypeArguments::New(1));
  tav_a1.SetTypeAt(0, type_a1);
  auto& type_a2_a1 = Type::Handle(Type::New(class_a2, tav_a1));
  type_a2_a1 = type_a2_a1.ToNullability(Nullability::kLegacy, Heap::kNew);
  FinalizeAndCanonicalize(&type_a2_a1);
  const auto& tav_a2_a1 = TypeArguments::Handle(TypeArguments::New(1));
  tav_a2_a1.SetTypeAt(0, type_a2_a1);
  auto& type_base_a2_a1 = Type::Handle(Type::New(class_base, tav_a2_a1));
  type_base_a2_a1 =
      type_base_a2_a1.ToNullability(Nullability::kNonNullable, Heap::kNew);
  FinalizeAndCanonicalize(&type_base_a2_a1);
  RunTTSTest(type_base_a2_a1, FalseNegative({obj_basea2a1, tav_null, tav_null,
                                             /*should_specialize=*/false}));
  RunTTSTest(type_base_a2_a1, Failure({obj_basea2int, tav_null, tav_null,
                                       /*should_specialize=*/false}));
}

const char* kRecordSubtypeRangeCheckScript =
    R"(
      class A {}
      class B extends A {}
      class C implements A {}
      class D<T> {}

      getType<T>() => T;
      getRecordType1() => getType<(int, A)>();
      getRecordType2() => getType<(A, int, String)>();
      getRecordType3() => getType<(int, D)>();

      createObj1() => (1, B());
      createObj2() => (1, 'bye');
      createObj3() => (1, foo: B());
      createObj4() => (1, B(), 2);
      createObj5() => (C(), 2, 'hi');
      createObj6() => (D(), 2, 'hi');
      createObj7() => (3, D<int>());
      createObj8() => (D<int>(), 3);
)";

ISOLATE_UNIT_TEST_CASE(TTS_RecordSubtypeRangeCheck) {
  const auto& root_library =
      Library::Handle(LoadTestScript(kRecordSubtypeRangeCheckScript));

  const auto& type1 = AbstractType::Cast(
      Object::Handle(Invoke(root_library, "getRecordType1")));
  const auto& type2 = AbstractType::Cast(
      Object::Handle(Invoke(root_library, "getRecordType2")));
  const auto& type3 = AbstractType::Cast(
      Object::Handle(Invoke(root_library, "getRecordType3")));

  const auto& obj1 = Object::Handle(Invoke(root_library, "createObj1"));
  const auto& obj2 = Object::Handle(Invoke(root_library, "createObj2"));
  const auto& obj3 = Object::Handle(Invoke(root_library, "createObj3"));
  const auto& obj4 = Object::Handle(Invoke(root_library, "createObj4"));
  const auto& obj5 = Object::Handle(Invoke(root_library, "createObj5"));
  const auto& obj6 = Object::Handle(Invoke(root_library, "createObj6"));
  const auto& obj7 = Object::Handle(Invoke(root_library, "createObj7"));
  const auto& obj8 = Object::Handle(Invoke(root_library, "createObj8"));

  const auto& tav_null = TypeArguments::Handle(TypeArguments::null());

  // (1, B())      as (int, A)
  // (1, 'bye')    as (int, A)
  // (1, foo: B()) as (int, A)
  // (1, B(), 2)   as (int, A)
  RunTTSTest(type1, {obj1, tav_null, tav_null});
  RunTTSTest(type1, Failure({obj2, tav_null, tav_null}));
  RunTTSTest(type1, Failure({obj3, tav_null, tav_null}));
  RunTTSTest(type1, Failure({obj4, tav_null, tav_null}));

  // (C(), 2, 'hi') as (A, int, String)
  // (D(), 2, 'hi') as (A, int, String)
  RunTTSTest(type2, {obj5, tav_null, tav_null});
  RunTTSTest(type2, Failure({obj6, tav_null, tav_null}));

  // (3, D<int>()) as (int, D)
  // (D<int>(), 3) as (int, D)
  RunTTSTest(type3, {obj7, tav_null, tav_null});
  RunTTSTest(type3, Failure({obj8, tav_null, tav_null}));
}

ISOLATE_UNIT_TEST_CASE(TTS_Generic_Implements_Instantiated_Interface) {
  const char* kScript =
      R"(
      abstract class I<T> {}
      class B<R> implements I<String> {}

      createBInt() => B<int>();
)";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& class_i = Class::Handle(GetClass(root_library, "I"));
  const auto& obj_b_int = Object::Handle(Invoke(root_library, "createBInt"));

  const auto& tav_null = Object::null_type_arguments();
  auto& tav_string = TypeArguments::Handle(TypeArguments::New(1));
  tav_string.SetTypeAt(0, Type::Handle(Type::StringType()));
  CanonicalizeTAV(&tav_string);

  auto& type_i_string = Type::Handle(Type::New(class_i, tav_string));
  FinalizeAndCanonicalize(&type_i_string);
  const auto& type_i_t = Type::Handle(class_i.DeclarationType());

  RunTTSTest(type_i_string, {obj_b_int, tav_null, tav_null});
  // Optimized TTSees don't currently handle the case where the implemented
  // type is known, but the type being checked requires instantiation at
  // runtime.
  RunTTSTest(type_i_t, FalseNegative({obj_b_int, tav_string, tav_null}));
}

ISOLATE_UNIT_TEST_CASE(TTS_Future) {
  const char* kScript =
      R"(
      import "dart:async";

      Future<int> createFutureInt() async => 3;
      Future<int Function()> createFutureFunction() async => () => 3;
      Future<int Function()?> createFutureNullableFunction() async =>
          (() => 3) as int Function()?;
)";

  SetupCoreLibrariesForUnitTest();

  const auto& class_future =
      Class::Handle(IsolateGroup::Current()->object_store()->future_class());

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& class_closure =
      Class::Handle(IsolateGroup::Current()->object_store()->closure_class());
  const auto& obj_futureint =
      Object::Handle(Invoke(root_library, "createFutureInt"));
  const auto& obj_futurefunction =
      Object::Handle(Invoke(root_library, "createFutureFunction"));
  const auto& obj_futurenullablefunction =
      Object::Handle(Invoke(root_library, "createFutureNullableFunction"));

  const auto& tav_null = Object::null_type_arguments();
  const auto& type_object = Type::Handle(
      IsolateGroup::Current()->object_store()->non_nullable_object_type());
  const auto& type_legacy_object = Type::Handle(
      IsolateGroup::Current()->object_store()->legacy_object_type());
  const auto& type_nullable_object = Type::Handle(
      IsolateGroup::Current()->object_store()->nullable_object_type());
  const auto& type_int = Type::Handle(
      IsolateGroup::Current()->object_store()->non_nullable_int_type());

  auto& type_string = Type::Handle(Type::StringType());
  type_string =
      type_string.ToNullability(Nullability::kNonNullable, Heap::kNew);
  FinalizeAndCanonicalize(&type_string);
  auto& type_num = Type::Handle(Type::Number());
  type_num = type_num.ToNullability(Nullability::kNonNullable, Heap::kNew);
  FinalizeAndCanonicalize(&type_num);

  auto& tav_dynamic = TypeArguments::Handle(TypeArguments::New(1));
  tav_dynamic.SetTypeAt(0, Object::dynamic_type());
  CanonicalizeTAV(&tav_dynamic);
  auto& tav_object = TypeArguments::Handle(TypeArguments::New(1));
  tav_object.SetTypeAt(0, type_object);
  CanonicalizeTAV(&tav_object);
  auto& tav_legacy_object = TypeArguments::Handle(TypeArguments::New(1));
  tav_legacy_object.SetTypeAt(0, type_legacy_object);
  CanonicalizeTAV(&tav_legacy_object);
  auto& tav_nullable_object = TypeArguments::Handle(TypeArguments::New(1));
  tav_nullable_object.SetTypeAt(0, type_nullable_object);
  CanonicalizeTAV(&tav_nullable_object);
  auto& tav_int = TypeArguments::Handle(TypeArguments::New(1));
  tav_int.SetTypeAt(0, type_int);
  CanonicalizeTAV(&tav_int);
  auto& tav_num = TypeArguments::Handle(TypeArguments::New(1));
  tav_num.SetTypeAt(0, type_num);
  CanonicalizeTAV(&tav_num);
  auto& tav_string = TypeArguments::Handle(TypeArguments::New(1));
  tav_string.SetTypeAt(0, type_string);
  CanonicalizeTAV(&tav_string);

  auto& type_future = Type::Handle(
      Type::New(class_future, tav_null, Nullability::kNonNullable));
  FinalizeAndCanonicalize(&type_future);
  auto& type_future_dynamic = Type::Handle(
      Type::New(class_future, tav_dynamic, Nullability::kNonNullable));
  FinalizeAndCanonicalize(&type_future_dynamic);
  auto& type_future_object = Type::Handle(
      Type::New(class_future, tav_object, Nullability::kNonNullable));
  FinalizeAndCanonicalize(&type_future_object);
  auto& type_future_legacy_object = Type::Handle(
      Type::New(class_future, tav_legacy_object, Nullability::kNonNullable));
  FinalizeAndCanonicalize(&type_future_legacy_object);
  auto& type_future_nullable_object = Type::Handle(
      Type::New(class_future, tav_nullable_object, Nullability::kNonNullable));
  FinalizeAndCanonicalize(&type_future_nullable_object);
  auto& type_future_int =
      Type::Handle(Type::New(class_future, tav_int, Nullability::kNonNullable));
  FinalizeAndCanonicalize(&type_future_int);
  auto& type_future_string = Type::Handle(
      Type::New(class_future, tav_string, Nullability::kNonNullable));
  FinalizeAndCanonicalize(&type_future_string);
  auto& type_future_num =
      Type::Handle(Type::New(class_future, tav_num, Nullability::kNonNullable));
  FinalizeAndCanonicalize(&type_future_num);
  const auto& type_future_t = Type::Handle(class_future.DeclarationType());

  THR_Print("********************************************************\n");
  THR_Print("               Testing Future<int>\n");
  THR_Print("********************************************************\n\n");

  // Some more tests of generic implemented classes, using Future. Here,
  // obj is an object of type Future<int>.
  //
  // True positives from TTS:
  //   obj as Future          : Null type args
  //   obj as Future<dynamic> : Canonicalized to same as previous case.
  //   obj as Future<Object?> : Type arg is top type
  //   obj as Future<Object*> : Type arg is top type
  //   obj as Future<Object>  : Type arg is certain supertype
  //   obj as Future<int>     : Type arg is the same type
  //   obj as Future<num>     : Type arg is a supertype that can be matched
  //                            with cid range
  //   obj as Future<X>,      : Type arg is a type parameter instantiated with
  //       X = int            :    ... the same type
  //
  RunTTSTest(type_future, {obj_futureint, tav_null, tav_null});
  RunTTSTest(type_future_dynamic, {obj_futureint, tav_null, tav_null});
  RunTTSTest(type_future_object, {obj_futureint, tav_null, tav_null});
  RunTTSTest(type_future_legacy_object, {obj_futureint, tav_null, tav_null});
  RunTTSTest(type_future_nullable_object, {obj_futureint, tav_null, tav_null});
  RunTTSTest(type_future_int, {obj_futureint, tav_null, tav_null});
  RunTTSTest(type_future_num, {obj_futureint, tav_null, tav_null});
  RunTTSTest(type_future_t, {obj_futureint, tav_int, tav_null});

  // False negatives from TTS (caught by STC/runtime):
  //   obj as Future<X>,      : Type arg is a type parameter instantiated with
  //       X = num            :    ... a supertype
  RunTTSTest(type_future_t, FalseNegative({obj_futureint, tav_num, tav_null}));

  // Errors:
  //   obj as Future<String>  : Type arg is not a supertype
  //   obj as Future<X>,      : Type arg is a type parameter instantiated with
  //       X = String         :    ... an unrelated type
  //
  RunTTSTest(type_future_string, Failure({obj_futureint, tav_null, tav_null}));
  RunTTSTest(type_future_t, Failure({obj_futureint, tav_string, tav_null}));

  auto& type_function = Type::Handle(Type::DartFunctionType());
  type_function =
      type_function.ToNullability(Nullability::kNonNullable, Heap::kNew);
  FinalizeAndCanonicalize(&type_function);
  auto& type_legacy_function = Type::Handle(
      type_function.ToNullability(Nullability::kLegacy, Heap::kNew));
  FinalizeAndCanonicalize(&type_legacy_function);
  auto& type_nullable_function = Type::Handle(
      type_function.ToNullability(Nullability::kNullable, Heap::kOld));
  FinalizeAndCanonicalize(&type_nullable_function);
  auto& type_closure = Type::Handle(
      Type::New(class_closure, tav_null, Nullability::kNonNullable));
  FinalizeAndCanonicalize(&type_closure);
  auto& type_legacy_closure = Type::Handle(
      type_closure.ToNullability(Nullability::kLegacy, Heap::kOld));
  FinalizeAndCanonicalize(&type_legacy_closure);
  auto& type_nullable_closure = Type::Handle(
      type_closure.ToNullability(Nullability::kNullable, Heap::kOld));
  FinalizeAndCanonicalize(&type_nullable_closure);
  auto& type_function_int_nullary =
      FunctionType::Handle(FunctionType::New(0, Nullability::kNonNullable));
  // Testing with a closure, so it has an implicit parameter, and we want a
  // type that is canonically equal to the type of the closure.
  type_function_int_nullary.set_num_implicit_parameters(1);
  type_function_int_nullary.set_num_fixed_parameters(1);
  type_function_int_nullary.set_parameter_types(Array::Handle(Array::New(1)));
  type_function_int_nullary.SetParameterTypeAt(0, Type::dynamic_type());
  type_function_int_nullary.set_result_type(type_int);
  FinalizeAndCanonicalize(&type_function_int_nullary);
  auto& type_legacy_function_int_nullary =
      FunctionType::Handle(type_function_int_nullary.ToNullability(
          Nullability::kLegacy, Heap::kOld));
  FinalizeAndCanonicalize(&type_legacy_function_int_nullary);
  auto& type_nullable_function_int_nullary =
      FunctionType::Handle(type_function_int_nullary.ToNullability(
          Nullability::kNullable, Heap::kOld));
  FinalizeAndCanonicalize(&type_nullable_function_int_nullary);

  auto& tav_function = TypeArguments::Handle(TypeArguments::New(1));
  tav_function.SetTypeAt(0, type_function);
  CanonicalizeTAV(&tav_function);
  auto& tav_legacy_function = TypeArguments::Handle(TypeArguments::New(1));
  tav_legacy_function.SetTypeAt(0, type_legacy_function);
  CanonicalizeTAV(&tav_legacy_function);
  auto& tav_nullable_function = TypeArguments::Handle(TypeArguments::New(1));
  tav_nullable_function.SetTypeAt(0, type_nullable_function);
  CanonicalizeTAV(&tav_nullable_function);
  auto& tav_closure = TypeArguments::Handle(TypeArguments::New(1));
  tav_closure.SetTypeAt(0, type_closure);
  CanonicalizeTAV(&tav_closure);
  auto& tav_legacy_closure = TypeArguments::Handle(TypeArguments::New(1));
  tav_legacy_closure.SetTypeAt(0, type_legacy_closure);
  CanonicalizeTAV(&tav_legacy_closure);
  auto& tav_nullable_closure = TypeArguments::Handle(TypeArguments::New(1));
  tav_nullable_closure.SetTypeAt(0, type_nullable_closure);
  CanonicalizeTAV(&tav_nullable_closure);
  auto& tav_function_int_nullary = TypeArguments::Handle(TypeArguments::New(1));
  tav_function_int_nullary.SetTypeAt(0, type_function_int_nullary);
  CanonicalizeTAV(&tav_function_int_nullary);
  auto& tav_legacy_function_int_nullary =
      TypeArguments::Handle(TypeArguments::New(1));
  tav_legacy_function_int_nullary.SetTypeAt(0,
                                            type_legacy_function_int_nullary);
  CanonicalizeTAV(&tav_legacy_function_int_nullary);
  auto& tav_nullable_function_int_nullary =
      TypeArguments::Handle(TypeArguments::New(1));
  tav_nullable_function_int_nullary.SetTypeAt(
      0, type_nullable_function_int_nullary);
  CanonicalizeTAV(&tav_nullable_function_int_nullary);

  auto& type_future_function = Type::Handle(
      Type::New(class_future, tav_function, Nullability::kNonNullable));
  FinalizeAndCanonicalize(&type_future_function);
  auto& type_future_legacy_function = Type::Handle(
      Type::New(class_future, tav_legacy_function, Nullability::kNonNullable));
  FinalizeAndCanonicalize(&type_future_legacy_function);
  auto& type_future_nullable_function = Type::Handle(Type::New(
      class_future, tav_nullable_function, Nullability::kNonNullable));
  FinalizeAndCanonicalize(&type_future_nullable_function);
  auto& type_future_closure = Type::Handle(
      Type::New(class_future, tav_closure, Nullability::kNonNullable));
  FinalizeAndCanonicalize(&type_future_closure);
  auto& type_future_legacy_closure = Type::Handle(
      Type::New(class_future, tav_legacy_closure, Nullability::kNonNullable));
  FinalizeAndCanonicalize(&type_future_legacy_closure);
  auto& type_future_nullable_closure = Type::Handle(
      Type::New(class_future, tav_nullable_closure, Nullability::kNonNullable));
  FinalizeAndCanonicalize(&type_future_nullable_closure);
  auto& type_future_function_int_nullary =
      Type::Handle(Type::New(class_future, tav_function_int_nullary));
  FinalizeAndCanonicalize(&type_future_function_int_nullary);
  auto& type_future_legacy_function_int_nullary =
      Type::Handle(Type::New(class_future, tav_legacy_function_int_nullary));
  FinalizeAndCanonicalize(&type_future_legacy_function_int_nullary);
  auto& type_future_nullable_function_int_nullary =
      Type::Handle(Type::New(class_future, tav_nullable_function_int_nullary));
  FinalizeAndCanonicalize(&type_future_nullable_function_int_nullary);

  THR_Print("\n********************************************************\n");
  THR_Print("            Testing Future<int Function()>\n");
  THR_Print("********************************************************\n\n");

  // And here, obj is an object of type Future<int Function()>. Note that
  // int Function() <: Function, but int Function() </: _Closure. That is,
  // _Closure is a separate subtype of Function from FunctionTypes.
  //
  // True positive from TTS:
  //   obj as Future            : Null type args
  //   obj as Future<dynamic>   : Canonicalized to same as previous case.
  //   obj as Future<Object?>   : Type arg is top type
  //   obj as Future<Object*>   : Type arg is top typ
  //   obj as Future<Object>    : Type arg is certain supertype
  //   obj as Future<Function?> : Type arg is certain supertype
  //   obj as Future<Function*> : Type arg is certain supertype
  //   obj as Future<Function>  : Type arg is certain supertype
  //   obj as Future<X>,        : Type arg is a type parameter instantiated with
  //       X = dynamic          :    ... a top type
  //       X = Object?          :    ... a top type
  //       X = Object*          :    ... a top type
  //       X = Object           :    ... a certain supertype
  //       X = int Function()   :    ... the same type.
  //
  RunTTSTest(type_future, {obj_futurefunction, tav_null, tav_null});
  RunTTSTest(type_future_dynamic, {obj_futurefunction, tav_null, tav_null});
  RunTTSTest(type_future_nullable_object,
             {obj_futurefunction, tav_null, tav_null});
  RunTTSTest(type_future_legacy_object,
             {obj_futurefunction, tav_null, tav_null});
  RunTTSTest(type_future_object, {obj_futurefunction, tav_null, tav_null});
  RunTTSTest(type_future_nullable_object,
             {obj_futurefunction, tav_null, tav_null});
  RunTTSTest(type_future_legacy_object,
             {obj_futurefunction, tav_null, tav_null});
  RunTTSTest(type_future_object, {obj_futurefunction, tav_null, tav_null});
  RunTTSTest(type_future_nullable_function,
             {obj_futurefunction, tav_null, tav_null});
  RunTTSTest(type_future_legacy_function,
             {obj_futurefunction, tav_null, tav_null});
  RunTTSTest(type_future_function, {obj_futurefunction, tav_null, tav_null});
  RunTTSTest(type_future_t, {obj_futurefunction, tav_null, tav_null});
  RunTTSTest(type_future_t,
             {obj_futurefunction, tav_nullable_object, tav_null});
  RunTTSTest(type_future_t, {obj_futurefunction, tav_legacy_object, tav_null});
  RunTTSTest(type_future_t, {obj_futurefunction, tav_object, tav_null});
  RunTTSTest(type_future_t,
             {obj_futurefunction, tav_function_int_nullary, tav_null});

  // False negative from TTS (caught by runtime or STC):
  //   obj as Future<int Function()?> : No specialization.
  //   obj as Future<int Function()*> : No specialization.
  //   obj as Future<int Function()>  : No specialization.
  //   obj as Future<X>,        : Type arg is a type parameter instantiated with
  //       X = Function?        :    ... a certain supertype (but not checked)
  //       X = Function*        :    ... a certain supertype (but not checked)
  //       X = Function         :    ... a certain supertype (but not checked)
  //       X = int Function()?  :    ... a canonically different type.
  //       X = int Function()*  :    ... a canonically different type.
  //
  RunTTSTest(type_future_nullable_function_int_nullary,
             FalseNegative({obj_futurefunction, tav_null, tav_null,
                            /*should_specialize=*/false}));
  RunTTSTest(type_future_legacy_function_int_nullary,
             FalseNegative({obj_futurefunction, tav_null, tav_null,
                            /*should_specialize=*/false}));
  RunTTSTest(type_future_function_int_nullary,
             FalseNegative({obj_futurefunction, tav_null, tav_null,
                            /*should_specialize=*/false}));
  RunTTSTest(type_future_t, FalseNegative({obj_futurefunction,
                                           tav_nullable_function, tav_null}));
  RunTTSTest(type_future_t, FalseNegative({obj_futurefunction,
                                           tav_legacy_function, tav_null}));
  RunTTSTest(type_future_t,
             FalseNegative({obj_futurefunction, tav_function, tav_null}));
  RunTTSTest(type_future_t,
             FalseNegative({obj_futurefunction,
                            tav_nullable_function_int_nullary, tav_null}));
  RunTTSTest(type_future_t,
             FalseNegative({obj_futurefunction, tav_legacy_function_int_nullary,
                            tav_null}));

  // Errors:
  //   obj as Future<_Closure?> : Type arg is not a supertype
  //   obj as Future<_Closure*> : Type arg is not a supertype
  //   obj as Future<_Closure>  : Type arg is not a supertype
  //   obj as Future<X>,        : Type arg is a type parameter instantiated with
  //       X = _Closure?        :    ... an unrelated type.
  //       X = _Closure*        :    ... an unrelated type.
  //       X = _Closure         :    ... an unrelated type.
  //
  RunTTSTest(type_future_nullable_closure,
             Failure({obj_futurefunction, tav_null, tav_null}));
  RunTTSTest(type_future_legacy_closure,
             Failure({obj_futurefunction, tav_null, tav_null}));
  RunTTSTest(type_future_closure,
             Failure({obj_futurefunction, tav_null, tav_null}));
  RunTTSTest(type_future_t,
             Failure({obj_futurefunction, tav_nullable_closure, tav_null}));
  RunTTSTest(type_future_t,
             Failure({obj_futurefunction, tav_legacy_closure, tav_null}));
  RunTTSTest(type_future_t,
             Failure({obj_futurefunction, tav_closure, tav_null}));

  THR_Print("\n********************************************************\n");
  THR_Print("            Testing Future<int Function()?>\n");
  THR_Print("********************************************************\n\n");

  const bool strict_null_safety =
      thread->isolate_group()->use_strict_null_safety_checks();

  // And here, obj is an object of type Future<int Function()?>.
  //
  // True positive from TTS:
  //   obj as Future            : Null type args
  //   obj as Future<dynamic>   : Canonicalized to same as previous case.
  //   obj as Future<Object?>   : Type arg is top type
  //   obj as Future<Object*>   : Type arg is top typ
  //   obj as Future<Function?> : Type arg is certain supertype
  //   obj as Future<Function*> : Type arg is certain supertype
  //   obj as Future<X>,        : Type arg is a type parameter instantiated with
  //       X = dynamic          :    ... a top type
  //       X = Object?          :    ... a top type
  //       X = Object*          :    ... a top type
  //       X = int Function()?  :    ... the same type.
  //
  // If not null safe:
  //   obj as Future<Object>    : Type arg is certain supertype
  //   obj as Future<Function>  : Type arg is certain supertype
  //   obj as Future<X>,        : Type arg is a type parameter instantiated with
  //       X = Object           :    ... a certain supertype
  RunTTSTest(type_future, {obj_futurenullablefunction, tav_null, tav_null});
  RunTTSTest(type_future_dynamic,
             {obj_futurenullablefunction, tav_null, tav_null});
  RunTTSTest(type_future_nullable_object,
             {obj_futurenullablefunction, tav_null, tav_null});
  RunTTSTest(type_future_legacy_object,
             {obj_futurenullablefunction, tav_null, tav_null});
  RunTTSTest(type_future_nullable_object,
             {obj_futurefunction, tav_null, tav_null});
  RunTTSTest(type_future_legacy_object,
             {obj_futurenullablefunction, tav_null, tav_null});
  RunTTSTest(type_future_nullable_function,
             {obj_futurenullablefunction, tav_null, tav_null});
  RunTTSTest(type_future_legacy_function,
             {obj_futurenullablefunction, tav_null, tav_null});
  RunTTSTest(type_future_t, {obj_futurenullablefunction, tav_null, tav_null});
  RunTTSTest(type_future_t,
             {obj_futurenullablefunction, tav_nullable_object, tav_null});
  RunTTSTest(type_future_t,
             {obj_futurenullablefunction, tav_legacy_object, tav_null});
  RunTTSTest(type_future_t, {obj_futurenullablefunction,
                             tav_nullable_function_int_nullary, tav_null});

  if (!strict_null_safety) {
    RunTTSTest(type_future_object,
               {obj_futurenullablefunction, tav_null, tav_null});
    RunTTSTest(type_future_function,
               {obj_futurenullablefunction, tav_null, tav_null});
    RunTTSTest(type_future_t,
               {obj_futurenullablefunction, tav_object, tav_null});
  }

  // False negative from TTS (caught by runtime or STC):
  //   obj as Future<int Function()?> : No specialization.
  //   obj as Future<int Function()*> : No specialization.
  //   obj as Future<X>,        : Type arg is a type parameter instantiated with
  //       X = Function?        :    ... a certain supertype (but not checked)
  //       X = Function*        :    ... a certain supertype (but not checked)
  //       X = int Function()*  :    ... a canonically different type.
  //
  // If not null safe:
  //   obj as Future<int Function()>  : No specialization.
  //   obj as Future<X>,        : Type arg is a type parameter instantiated with
  //       X = Function         :    ... a certain supertype (but not checked)
  //       X = int Function()   :    ... a canonically different type.

  RunTTSTest(type_future_nullable_function_int_nullary,
             FalseNegative({obj_futurenullablefunction, tav_null, tav_null,
                            /*should_specialize=*/false}));
  RunTTSTest(type_future_legacy_function_int_nullary,
             FalseNegative({obj_futurenullablefunction, tav_null, tav_null,
                            /*should_specialize=*/false}));
  RunTTSTest(type_future_t, FalseNegative({obj_futurenullablefunction,
                                           tav_nullable_function, tav_null}));
  RunTTSTest(type_future_t, FalseNegative({obj_futurenullablefunction,
                                           tav_legacy_function, tav_null}));
  RunTTSTest(type_future_t,
             FalseNegative({obj_futurenullablefunction,
                            tav_legacy_function_int_nullary, tav_null}));

  if (!strict_null_safety) {
    RunTTSTest(type_future_function_int_nullary,
               FalseNegative({obj_futurenullablefunction, tav_null, tav_null,
                              /*should_specialize=*/false}));
    RunTTSTest(type_future_t, FalseNegative({obj_futurenullablefunction,
                                             tav_function, tav_null}));
    RunTTSTest(type_future_t,
               FalseNegative({obj_futurenullablefunction,
                              tav_function_int_nullary, tav_null}));
  }

  // Errors:
  //   obj as Future<_Closure?> : Type arg is not a supertype
  //   obj as Future<_Closure*> : Type arg is not a supertype
  //   obj as Future<_Closure>  : Type arg is not a supertype
  //   obj as Future<X>,        : Type arg is a type parameter instantiated with
  //       X = _Closure?        :    ... an unrelated type.
  //       X = _Closure*        :    ... an unrelated type.
  //       X = _Closure         :    ... an unrelated type.
  //
  // If null safe:
  //   obj as Future<int Function()>  : Nullable type cannot be subtype of a
  //                                    non-nullable type.
  //   obj as Future<Object>    : Nullable type cannot be subtype of a
  //                              non-nullable type.
  //   obj as Future<Function>  : Nullable type cannot be subtype of a
  //                              non-nullable type.
  //   obj as Future<X>,        : Type arg is a type parameter instantiated with
  //       X = Object           :    ... a non-nullable type.
  //       X = Function         :    ... a non-nullable type.
  //       X = int Function()   :    ... a non-nullable type.

  RunTTSTest(type_future_nullable_closure,
             Failure({obj_futurenullablefunction, tav_null, tav_null}));
  RunTTSTest(type_future_legacy_closure,
             Failure({obj_futurenullablefunction, tav_null, tav_null}));
  RunTTSTest(type_future_closure,
             Failure({obj_futurenullablefunction, tav_null, tav_null}));
  RunTTSTest(type_future_t, Failure({obj_futurenullablefunction,
                                     tav_nullable_closure, tav_null}));
  RunTTSTest(type_future_t, Failure({obj_futurenullablefunction,
                                     tav_legacy_closure, tav_null}));
  RunTTSTest(type_future_t,
             Failure({obj_futurenullablefunction, tav_closure, tav_null}));

  if (strict_null_safety) {
    RunTTSTest(type_future_function_int_nullary,
               Failure({obj_futurenullablefunction, tav_null, tav_null,
                        /*should_specialize=*/false}));
    RunTTSTest(type_future_object,
               Failure({obj_futurenullablefunction, tav_null, tav_null}));
    RunTTSTest(type_future_function,
               Failure({obj_futurenullablefunction, tav_null, tav_null}));
    RunTTSTest(type_future_t,
               Failure({obj_futurenullablefunction, tav_object, tav_null}));
    RunTTSTest(type_future_t,
               Failure({obj_futurenullablefunction, tav_function, tav_null}));
    RunTTSTest(type_future_t, Failure({obj_futurenullablefunction,
                                       tav_function_int_nullary, tav_null}));
  }
}

ISOLATE_UNIT_TEST_CASE(TTS_Regress40964) {
  const char* kScript =
      R"(
          class A<T> {
            test(x) => x as B<T>;
          }
          class B<T> {}
          class C<T> {}

          createACint() => A<C<int>>();
          createBCint() => B<C<int>>();
          createBCnum() => B<C<num>>();
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& class_b = Class::Handle(GetClass(root_library, "B"));

  const auto& acint = Object::Handle(Invoke(root_library, "createACint"));
  const auto& bcint = Object::Handle(Invoke(root_library, "createBCint"));
  const auto& bcnum = Object::Handle(Invoke(root_library, "createBCnum"));

  // dst_type = B<T>
  const auto& dst_tav = TypeArguments::Handle(TypeArguments::New(1));
  dst_tav.SetTypeAt(0,
                    TypeParameter::Handle(GetClassTypeParameter(class_b, 0)));
  auto& dst_type = Type::Handle(Type::New(class_b, dst_tav));
  FinalizeAndCanonicalize(&dst_type);
  const auto& cint_tav =
      TypeArguments::Handle(Instance::Cast(acint).GetTypeArguments());
  const auto& function_tav = TypeArguments::Handle();

  // a as B<T> -- a==B<C<int>, T==<C<int>>
  RunTTSTest(dst_type, {bcint, cint_tav, function_tav});

  // a as B<T> -- a==B<C<num>, T==<C<int>>
  RunTTSTest(dst_type, Failure({bcnum, cint_tav, function_tav}));
}

ISOLATE_UNIT_TEST_CASE(TTS_TypeParameter) {
  const char* kScript =
      R"(
          class A<T> {
            T test(dynamic x) => x as T;
          }
          H genericFun<H>(dynamic x) => x as H;

          createAInt() => A<int>();
          createAString() => A<String>();
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& class_a = Class::Handle(GetClass(root_library, "A"));
  ClassFinalizer::FinalizeTypesInClass(class_a);

  const auto& fun_generic =
      Function::Handle(GetFunction(root_library, "genericFun"));

  const auto& dst_type_t =
      TypeParameter::Handle(GetClassTypeParameter(class_a, 0));

  const auto& dst_type_h =
      TypeParameter::Handle(GetFunctionTypeParameter(fun_generic, 0));

  const auto& aint = Object::Handle(Invoke(root_library, "createAInt"));
  const auto& astring = Object::Handle(Invoke(root_library, "createAString"));

  const auto& int_tav =
      TypeArguments::Handle(Instance::Cast(aint).GetTypeArguments());
  const auto& string_tav =
      TypeArguments::Handle(Instance::Cast(astring).GetTypeArguments());

  const auto& int_instance = Integer::Handle(Integer::New(1));
  const auto& string_instance = String::Handle(String::New("foo"));

  THR_Print("Testing int instance, class parameter instantiated to int\n");
  RunTTSTest(dst_type_t, {int_instance, int_tav, string_tav});
  THR_Print("\nTesting string instance, class parameter instantiated to int\n");
  RunTTSTest(dst_type_t, Failure({string_instance, int_tav, string_tav}));

  THR_Print(
      "\nTesting string instance, function parameter instantiated to string\n");
  RunTTSTest(dst_type_h, {string_instance, int_tav, string_tav});
  RunTTSTest(dst_type_h, Failure({int_instance, int_tav, string_tav}));
}

// Check that we generate correct TTS for _Smi type.
ISOLATE_UNIT_TEST_CASE(TTS_Smi) {
  const auto& type_smi = Type::Handle(Type::SmiType());
  const auto& tav_null = Object::null_type_arguments();

  // Test on some easy-to-make instances.
  RunTTSTest(type_smi, {Smi::Handle(Smi::New(0)), tav_null, tav_null});
  RunTTSTest(type_smi, Failure({Integer::Handle(Integer::New(kMaxInt64)),
                                tav_null, tav_null}));
  RunTTSTest(type_smi,
             Failure({Double::Handle(Double::New(1.0)), tav_null, tav_null}));
  RunTTSTest(type_smi, Failure({Symbols::Empty(), tav_null, tav_null}));
  RunTTSTest(type_smi,
             Failure({Array::Handle(Array::New(1)), tav_null, tav_null}));
}

// Check that we generate correct TTS for int type.
ISOLATE_UNIT_TEST_CASE(TTS_Int) {
  const auto& type_int = Type::Handle(Type::IntType());
  const auto& tav_null = Object::null_type_arguments();

  // Test on some easy-to-make instances.
  RunTTSTest(type_int, {Smi::Handle(Smi::New(0)), tav_null, tav_null});
  RunTTSTest(type_int,
             {Integer::Handle(Integer::New(kMaxInt64)), tav_null, tav_null});
  RunTTSTest(type_int,
             Failure({Double::Handle(Double::New(1.0)), tav_null, tav_null}));
  RunTTSTest(type_int, Failure({Symbols::Empty(), tav_null, tav_null}));
  RunTTSTest(type_int,
             Failure({Array::Handle(Array::New(1)), tav_null, tav_null}));
}

// Check that we generate correct TTS for num type.
ISOLATE_UNIT_TEST_CASE(TTS_Num) {
  const auto& type_num = Type::Handle(Type::Number());
  const auto& tav_null = Object::null_type_arguments();

  // Test on some easy-to-make instances.
  RunTTSTest(type_num, {Smi::Handle(Smi::New(0)), tav_null, tav_null});
  RunTTSTest(type_num,
             {Integer::Handle(Integer::New(kMaxInt64)), tav_null, tav_null});
  RunTTSTest(type_num, {Double::Handle(Double::New(1.0)), tav_null, tav_null});
  RunTTSTest(type_num, Failure({Symbols::Empty(), tav_null, tav_null}));
  RunTTSTest(type_num,
             Failure({Array::Handle(Array::New(1)), tav_null, tav_null}));
}

// Check that we generate correct TTS for Double type.
ISOLATE_UNIT_TEST_CASE(TTS_Double) {
  const auto& type_num = Type::Handle(Type::Double());
  const auto& tav_null = Object::null_type_arguments();

  // Test on some easy-to-make instances.
  RunTTSTest(type_num, Failure({Smi::Handle(Smi::New(0)), tav_null, tav_null}));
  RunTTSTest(type_num, Failure({Integer::Handle(Integer::New(kMaxInt64)),
                                tav_null, tav_null}));
  RunTTSTest(type_num, {Double::Handle(Double::New(1.0)), tav_null, tav_null});
  RunTTSTest(type_num, Failure({Symbols::Empty(), tav_null, tav_null}));
  RunTTSTest(type_num,
             Failure({Array::Handle(Array::New(1)), tav_null, tav_null}));
}

// Check that we generate correct TTS for Object type.
ISOLATE_UNIT_TEST_CASE(TTS_Object) {
  const auto& type_obj =
      Type::Handle(IsolateGroup::Current()->object_store()->object_type());
  const auto& tav_null = Object::null_type_arguments();

  auto make_test_case = [&](const Instance& instance) -> TTSTestCase {
    if (IsolateGroup::Current()->use_strict_null_safety_checks()) {
      // The stub for non-nullable object should specialize, but only fails
      // on null, which is already checked within RunTTSTest.
      return {instance, tav_null, tav_null};
    } else {
      // The default type testing stub for nullable object is the top type
      // stub, so it should neither specialize _or_ return false negatives.
      return {instance, tav_null, tav_null, /*should_specialize=*/false};
    }
  };

  // Test on some easy-to-make instances.
  RunTTSTest(type_obj, make_test_case(Smi::Handle(Smi::New(0))));
  RunTTSTest(type_obj,
             make_test_case(Integer::Handle(Integer::New(kMaxInt64))));
  RunTTSTest(type_obj, make_test_case(Double::Handle(Double::New(1.0))));
  RunTTSTest(type_obj, make_test_case(Symbols::Empty()));
  RunTTSTest(type_obj, make_test_case(Array::Handle(Array::New(1))));
}

// Check that we generate correct TTS for type Function (the non-FunctionType
// version).
ISOLATE_UNIT_TEST_CASE(TTS_Function) {
  const char* kScript =
      R"(
          class A<T> {}

          createF() => (){};
          createG() => () => 3;
          createH() => (int x, String y, {int z = 0}) =>  x + z;

          createAInt() => A<int>();
          createAFunction() => A<Function>();
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& obj_f = Object::Handle(Invoke(root_library, "createF"));
  const auto& obj_g = Object::Handle(Invoke(root_library, "createG"));
  const auto& obj_h = Object::Handle(Invoke(root_library, "createH"));

  const auto& tav_null = TypeArguments::Handle(TypeArguments::null());
  const auto& type_function = Type::Handle(Type::DartFunctionType());

  RunTTSTest(type_function, {obj_f, tav_null, tav_null});
  RunTTSTest(type_function, {obj_g, tav_null, tav_null});
  RunTTSTest(type_function, {obj_h, tav_null, tav_null});

  const auto& class_a = Class::Handle(GetClass(root_library, "A"));
  const auto& obj_a_int = Object::Handle(Invoke(root_library, "createAInt"));
  const auto& obj_a_function =
      Object::Handle(Invoke(root_library, "createAFunction"));

  auto& tav_function = TypeArguments::Handle(TypeArguments::New(1));
  tav_function.SetTypeAt(0, type_function);
  CanonicalizeTAV(&tav_function);
  auto& type_a_function = Type::Handle(Type::New(class_a, tav_function));
  FinalizeAndCanonicalize(&type_a_function);

  RunTTSTest(type_a_function, {obj_a_function, tav_null, tav_null});
  RunTTSTest(type_a_function, Failure({obj_a_int, tav_null, tav_null}));
}

ISOLATE_UNIT_TEST_CASE(TTS_Partial) {
  const char* kScript =
      R"(
      class B<T> {}

      class C {}
      class D extends C {}
      class E extends D {}

      F<A>() {}
      createBE() => B<E>();
      createBENullable() => B<E?>();
      createBNull() => B<Null>();
      createBNever() => B<Never>();
)";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& class_b = Class::Handle(GetClass(root_library, "B"));
  const auto& class_c = Class::Handle(GetClass(root_library, "C"));
  const auto& class_d = Class::Handle(GetClass(root_library, "D"));
  const auto& class_e = Class::Handle(GetClass(root_library, "E"));
  const auto& fun_f = Function::Handle(GetFunction(root_library, "F"));
  const auto& obj_b_e = Object::Handle(Invoke(root_library, "createBE"));
  const auto& obj_b_e_nullable =
      Object::Handle(Invoke(root_library, "createBENullable"));
  const auto& obj_b_null = Object::Handle(Invoke(root_library, "createBNull"));
  const auto& obj_b_never =
      Object::Handle(Invoke(root_library, "createBNever"));

  const auto& tav_null = Object::null_type_arguments();
  auto& tav_nullable_object = TypeArguments::Handle(TypeArguments::New(1));
  tav_nullable_object.SetTypeAt(
      0, Type::Handle(
             IsolateGroup::Current()->object_store()->nullable_object_type()));
  CanonicalizeTAV(&tav_nullable_object);
  auto& tav_legacy_object = TypeArguments::Handle(TypeArguments::New(1));
  tav_legacy_object.SetTypeAt(
      0, Type::Handle(
             IsolateGroup::Current()->object_store()->legacy_object_type()));
  CanonicalizeTAV(&tav_legacy_object);
  auto& tav_object = TypeArguments::Handle(TypeArguments::New(1));
  tav_object.SetTypeAt(
      0, Type::Handle(IsolateGroup::Current()->object_store()->object_type()));
  CanonicalizeTAV(&tav_object);

  auto& type_e =
      Type::Handle(Type::New(class_e, tav_null, Nullability::kNonNullable));
  FinalizeAndCanonicalize(&type_e);
  auto& type_d =
      Type::Handle(Type::New(class_d, tav_null, Nullability::kNonNullable));
  FinalizeAndCanonicalize(&type_d);
  auto& type_c =
      Type::Handle(Type::New(class_c, tav_null, Nullability::kNonNullable));
  FinalizeAndCanonicalize(&type_c);
  auto& type_c_nullable =
      Type::Handle(Type::New(class_c, tav_null, Nullability::kNullable));
  FinalizeAndCanonicalize(&type_c_nullable);
  auto& type_c_legacy =
      Type::Handle(Type::New(class_c, tav_null, Nullability::kLegacy));
  FinalizeAndCanonicalize(&type_c_legacy);

  auto& tav_e = TypeArguments::Handle(TypeArguments::New(1));
  tav_e.SetTypeAt(0, type_e);
  CanonicalizeTAV(&tav_e);
  auto& tav_d = TypeArguments::Handle(TypeArguments::New(1));
  tav_d.SetTypeAt(0, type_d);
  CanonicalizeTAV(&tav_d);
  auto& tav_c = TypeArguments::Handle(TypeArguments::New(1));
  tav_c.SetTypeAt(0, type_c);
  CanonicalizeTAV(&tav_c);
  auto& tav_nullable_c = TypeArguments::Handle(TypeArguments::New(1));
  tav_nullable_c.SetTypeAt(0, type_c_nullable);
  CanonicalizeTAV(&tav_nullable_c);
  auto& tav_legacy_c = TypeArguments::Handle(TypeArguments::New(1));
  tav_legacy_c.SetTypeAt(0, type_c_legacy);
  CanonicalizeTAV(&tav_legacy_c);

  // One case where optimized TTSes can be partial is if the type is
  // uninstantiated with a type parameter at the same position as one of the
  // class's type parameters. The type parameter in the type is instantiated at
  // runtime and compared with the corresponding instance type argument using
  // pointer equality, which misses the case where the instantiated type
  // parameter in the type is a supertype of the instance type argument.
  const auto& type_a =
      TypeParameter::Handle(GetFunctionTypeParameter(fun_f, 0));
  auto& tav_a = TypeArguments::Handle(TypeArguments::New(1));
  tav_a.SetTypeAt(0, type_a);
  CanonicalizeTAV(&tav_a);
  auto& type_b_a = AbstractType::Handle(
      Type::New(class_b, tav_a, Nullability::kNonNullable));
  FinalizeAndCanonicalize(&type_b_a);
  TTSTestState state(thread, type_b_a);

  TTSTestCase b_e_testcase{obj_b_e, tav_null, tav_e};
  TTSTestCase b_d_testcase = FalseNegative({obj_b_e, tav_null, tav_d});
  TTSTestCase b_c_testcase = FalseNegative({obj_b_e, tav_null, tav_c});

  // First, test that the positive test case is handled by the TTS.
  state.InvokeLazilySpecializedStub(b_e_testcase);
  state.InvokeExistingStub(b_e_testcase);

  // Now restart, using the false negative test cases.
  state.ClearCache();

  state.InvokeLazilySpecializedStub(b_d_testcase);
  state.InvokeExistingStub(b_d_testcase);
  state.InvokeEagerlySpecializedStub(b_d_testcase);

  state.InvokeExistingStub(b_e_testcase);
  state.InvokeExistingStub(b_c_testcase);
  state.InvokeExistingStub(b_d_testcase);
  state.InvokeExistingStub(b_e_testcase);

  state.InvokeExistingStub({obj_b_never, tav_null, tav_d});
  state.InvokeExistingStub({obj_b_null, tav_null, tav_nullable_c});
  state.InvokeExistingStub({obj_b_null, tav_null, tav_legacy_c});
  if (IsolateGroup::Current()->use_strict_null_safety_checks()) {
    state.InvokeExistingStub(Failure({obj_b_null, tav_null, tav_c}));
  } else {
    state.InvokeExistingStub({obj_b_null, tav_null, tav_c});
  }

  state.InvokeExistingStub({obj_b_e, tav_null, tav_nullable_object});
  state.InvokeExistingStub({obj_b_e_nullable, tav_null, tav_nullable_object});
  state.InvokeExistingStub({obj_b_e, tav_null, tav_legacy_object});
  state.InvokeExistingStub({obj_b_e_nullable, tav_null, tav_legacy_object});
  state.InvokeExistingStub({obj_b_e, tav_null, tav_object});
  if (IsolateGroup::Current()->use_strict_null_safety_checks()) {
    state.InvokeExistingStub(Failure({obj_b_e_nullable, tav_null, tav_object}));
  } else {
    state.InvokeExistingStub({obj_b_e_nullable, tav_null, tav_object});
  }
}

ISOLATE_UNIT_TEST_CASE(TTS_Partial_Incremental) {
#define FILE_RESOLVE_URI(Uri) "file:///" Uri
#define FIRST_PARTIAL_LIBRARY_NAME "test-lib"
#define SECOND_PARTIAL_LIBRARY_NAME "test-lib-2"
#define THIRD_PARTIAL_LIBRARY_NAME "test-lib-3"

  // Same test script as TTS_Partial.
  const char* kFirstScript =
      R"(
      class B<T> {}
      createB() => B<int>();
)";

  // A test script which imports the B class and extend it, to test
  // respecialization when the hierarchy changes without reloading.
  const char* kSecondScript =
      R"(
      import ")" FIRST_PARTIAL_LIBRARY_NAME R"(";
      class B2<T> extends B<T> {}
      createB2() => B2<int>();
)";

  // Another one to test respecialization a second time.
  const char* kThirdScript =
      R"(
      import ")" FIRST_PARTIAL_LIBRARY_NAME R"(";
      class B3<T> extends B<T> {}
      createB3() => B3<int>();
)";

  const char* kFirstUri = FILE_RESOLVE_URI(FIRST_PARTIAL_LIBRARY_NAME);
  const char* kSecondUri = FILE_RESOLVE_URI(SECOND_PARTIAL_LIBRARY_NAME);
  const char* kThirdUri = FILE_RESOLVE_URI(THIRD_PARTIAL_LIBRARY_NAME);

#undef THIRD_PARTIAL_LIBRARY_URI
#undef SECOND_PARTIAL_LIBRARY_URI
#undef FIRST_PARTIAL_LIBRARY_URI
#undef FILE_RESOLVE_URI

  THR_Print("------------------------------------------------------\n");
  THR_Print("             Loading %s\n", kFirstUri);
  THR_Print("------------------------------------------------------\n");
  const auto& first_library = Library::Handle(
      LoadTestScript(kFirstScript, /*resolver=*/nullptr, kFirstUri));

  const auto& class_b = Class::Handle(GetClass(first_library, "B"));
  const auto& obj_b = Object::Handle(Invoke(first_library, "createB"));

  const auto& tav_null = Object::null_type_arguments();
  auto& tav_int = TypeArguments::Handle(TypeArguments::New(1));
  tav_int.SetTypeAt(0, Type::Handle(Type::IntType()));
  CanonicalizeTAV(&tav_int);
  auto& tav_num = TypeArguments::Handle(TypeArguments::New(1));
  tav_num.SetTypeAt(0, Type::Handle(Type::Number()));
  CanonicalizeTAV(&tav_num);

  auto& type_b2_t = AbstractType::Handle(class_b.DeclarationType());
  FinalizeAndCanonicalize(&type_b2_t);
  TTSTestState state(thread, type_b2_t);

  TTSTestCase first_positive{obj_b, tav_int, tav_null};
  TTSTestCase first_false_negative = FalseNegative({obj_b, tav_num, tav_null});
  // No test case should possibly hit the same STC entry as another.
  ASSERT(!first_false_negative.HasSameSTCEntry(first_positive));
  // The type with the tested stub must be the same in all test cases.
  ASSERT(state.TypeToTest(first_positive) ==
         state.TypeToTest(first_false_negative));

  state.InvokeLazilySpecializedStub(first_false_negative);
  state.InvokeExistingStub(first_false_negative);
  state.InvokeEagerlySpecializedStub(first_false_negative);

  state.InvokeExistingStub(first_positive);
  state.InvokeExistingStub(first_false_negative);

  Array& stc_cache = Array::Handle(
      state.last_stc().IsNull() ? Array::null() : state.last_stc().cache());
  THR_Print("------------------------------------------------------\n");
  THR_Print("             Loading %s\n", kSecondUri);
  THR_Print("------------------------------------------------------\n");
  const auto& second_library = Library::Handle(
      LoadTestScript(kSecondScript, /*resolver=*/nullptr, kSecondUri));
  // Loading the new library shouldn't invalidate the old STC.
  EXPECT(state.last_stc().ptr() == state.current_stc());
  // Loading the new library should not reset the STCs, as no respecialization
  // should happen yet.
  EXPECT((state.last_stc().IsNull() && stc_cache.IsNull()) ||
         stc_cache.ptr() == state.last_stc().cache());

  const auto& obj_b2 = Object::Handle(Invoke(second_library, "createB2"));

  TTSTestCase second_positive{obj_b2, tav_int, tav_null};
  TTSTestCase second_false_negative =
      FalseNegative({obj_b2, tav_num, tav_null});
  // No test case should possibly hit the same STC entry as another.
  ASSERT(!second_positive.HasSameSTCEntry(second_false_negative));
  ASSERT(!second_positive.HasSameSTCEntry(first_positive));
  ASSERT(!second_positive.HasSameSTCEntry(first_false_negative));
  ASSERT(!second_false_negative.HasSameSTCEntry(first_positive));
  ASSERT(!second_false_negative.HasSameSTCEntry(first_false_negative));
  // The type with the tested stub must be the same in all test cases.
  ASSERT(state.TypeToTest(second_positive) ==
         state.TypeToTest(second_false_negative));
  ASSERT(state.TypeToTest(first_positive) == state.TypeToTest(second_positive));

  // Old positive should still be caught by TTS.
  state.InvokeExistingStub(first_positive);
  // Same false negative should still be caught by STC and not cause
  // respecialization.
  state.InvokeExistingStub(first_false_negative);

  // The new positive should be a false negative at the TTS level that causes
  // respecialization, as the class hierarchy has changed.
  state.InvokeExistingStub(Respecialization(second_positive));

  // The first false positive is still in the cache.
  state.InvokeExistingStub(first_false_negative);

  // This false negative is not yet in the cache.
  state.InvokeExistingStub(second_false_negative);

  state.InvokeExistingStub(first_positive);
  state.InvokeExistingStub(second_positive);

  // Now the second false negative is in the cache.
  state.InvokeExistingStub(second_false_negative);

  stc_cache =
      state.last_stc().IsNull() ? Array::null() : state.last_stc().cache();
  THR_Print("------------------------------------------------------\n");
  THR_Print("             Loading %s\n", kThirdUri);
  THR_Print("------------------------------------------------------\n");
  const auto& third_library = Library::Handle(
      LoadTestScript(kThirdScript, /*resolver=*/nullptr, kThirdUri));
  // Loading the new library shouldn't invalidate the old STC.
  EXPECT(state.last_stc().ptr() == state.current_stc());
  // Loading the new library should not reset the STCs, as no respecialization
  // should happen yet.
  EXPECT((state.last_stc().IsNull() && stc_cache.IsNull()) ||
         stc_cache.ptr() == state.last_stc().cache());

  const auto& obj_b3 = Object::Handle(Invoke(third_library, "createB3"));

  TTSTestCase third_positive{obj_b3, tav_int, tav_null};
  TTSTestCase third_false_negative = FalseNegative({obj_b3, tav_num, tav_null});
  // No test case should possibly hit the same STC entry as another.
  ASSERT(!third_positive.HasSameSTCEntry(third_false_negative));
  ASSERT(!third_positive.HasSameSTCEntry(first_positive));
  ASSERT(!third_positive.HasSameSTCEntry(first_false_negative));
  ASSERT(!third_positive.HasSameSTCEntry(second_positive));
  ASSERT(!third_positive.HasSameSTCEntry(second_false_negative));
  ASSERT(!third_false_negative.HasSameSTCEntry(first_positive));
  ASSERT(!third_false_negative.HasSameSTCEntry(first_false_negative));
  ASSERT(!third_false_negative.HasSameSTCEntry(second_positive));
  ASSERT(!third_false_negative.HasSameSTCEntry(second_false_negative));
  // The type with the tested stub must be the same in all test cases.
  ASSERT(state.TypeToTest(third_positive) ==
         state.TypeToTest(third_false_negative));
  ASSERT(state.TypeToTest(first_positive) == state.TypeToTest(third_positive));

  // Again, cases that have run before should still pass as before without STC
  // changes/respecialization.
  state.InvokeExistingStub(first_positive);
  state.InvokeExistingStub(second_positive);
  state.InvokeExistingStub(first_false_negative);
  state.InvokeExistingStub(second_false_negative);

  // Now we lead with the new false negative, to make sure it also triggers
  // respecialization but doesn't get immediately added to the STC.
  state.InvokeExistingStub(Respecialization(third_false_negative));

  // True positives still work as before.
  state.InvokeExistingStub(third_positive);
  state.InvokeExistingStub(second_positive);
  state.InvokeExistingStub(first_positive);

  // No additional checks added by rerunning the previous false negatives.
  state.InvokeExistingStub(first_false_negative);
  state.InvokeExistingStub(second_false_negative);

  // Now a check is recorded when rerunning the third false negative.
  state.InvokeExistingStub(third_false_negative);
}

// TTS deoptimization on reload only happens in non-product mode currently.
#if !defined(PRODUCT)
static const char* kLoadedScript =
    R"(
          class A<T> {}

          createAInt() => A<int>();
          createAString() => A<String>();

          (int, int) createRecordIntInt() => (1, 2);
          (String, int) createRecordStringInt() => ("foo", 2);
          (int, String) createRecordIntString() => (1, "bar");
  )";

static const char* kReloadedScript =
    R"(
          class A<T> {}
          class A2<T> extends A<T> {}

          createAInt() => A<int>();
          createAString() => A<String>();
          createA2Int() => A2<int>();
          createA2String() => A2<String>();

          (int, int) createRecordIntInt() => (1, 2);
          (String, int) createRecordStringInt() => ("foo", 2);
          (int, String) createRecordIntString() => (1, "bar");
  )";

ISOLATE_UNIT_TEST_CASE(TTS_Reload) {
  auto* const zone = thread->zone();

  auto& root_library = Library::Handle(LoadTestScript(kLoadedScript));
  const auto& class_a = Class::Handle(GetClass(root_library, "A"));
  ClassFinalizer::FinalizeTypesInClass(class_a);

  const auto& aint = Object::Handle(Invoke(root_library, "createAInt"));
  const auto& astring = Object::Handle(Invoke(root_library, "createAString"));

  const auto& record_int_int =
      Instance::CheckedHandle(zone, Invoke(root_library, "createRecordIntInt"));
  const auto& record_int_string = Instance::CheckedHandle(
      zone, Invoke(root_library, "createRecordIntString"));
  const auto& record_string_int = Instance::CheckedHandle(
      zone, Invoke(root_library, "createRecordStringInt"));

  const auto& tav_null = Object::null_type_arguments();
  const auto& tav_int =
      TypeArguments::Handle(Instance::Cast(aint).GetTypeArguments());
  auto& tav_num = TypeArguments::Handle(TypeArguments::New(1));
  tav_num.SetTypeAt(0, Type::Handle(Type::Number()));
  CanonicalizeTAV(&tav_num);

  auto& type_a_int = Type::Handle(Type::New(class_a, tav_int));
  FinalizeAndCanonicalize(&type_a_int);

  auto& type_record_int_int =
      AbstractType::Handle(record_int_int.GetType(Heap::kNew));
  FinalizeAndCanonicalize(&type_record_int_int);

  TTSTestState state(thread, type_a_int);
  state.InvokeLazilySpecializedStub({aint, tav_null, tav_null});
  state.InvokeExistingStub(Failure({astring, tav_null, tav_null}));

  TTSTestState record_state(thread, type_record_int_int);
  record_state.InvokeLazilySpecializedStub(
      {record_int_int, tav_null, tav_null});
  record_state.InvokeExistingStub(
      Failure({record_string_int, tav_null, tav_null}));
  record_state.InvokeExistingStub(
      Failure({record_int_string, tav_null, tav_null}));

  // Make sure the stubs are specialized prior to reload.
  EXPECT(type_a_int.type_test_stub() !=
         TypeTestingStubGenerator::DefaultCodeForType(type_a_int));
  EXPECT(type_record_int_int.type_test_stub() !=
         TypeTestingStubGenerator::DefaultCodeForType(type_record_int_int));

  root_library = ReloadTestScript(kReloadedScript);
  const auto& a2int = Object::Handle(Invoke(root_library, "createA2Int"));
  const auto& a2string = Object::Handle(Invoke(root_library, "createA2String"));

  // Reloading resets all type testing stubs to the (possibly lazy specializing)
  // default stub for that type.
  EXPECT(type_a_int.type_test_stub() ==
         TypeTestingStubGenerator::DefaultCodeForType(type_a_int));
  EXPECT(type_record_int_int.type_test_stub() ==
         TypeTestingStubGenerator::DefaultCodeForType(type_record_int_int));
  // Reloading either removes or resets the type testing cache.
  EXPECT(state.current_stc() == SubtypeTestCache::null() ||
         (state.current_stc() == state.last_stc().ptr() &&
          state.last_stc().NumberOfChecks() == 0));
  EXPECT(record_state.current_stc() == SubtypeTestCache::null() ||
         (record_state.current_stc() == record_state.last_stc().ptr() &&
          record_state.last_stc().NumberOfChecks() == 0));

  state.InvokeExistingStub(Respecialization({aint, tav_null, tav_null}));
  state.InvokeExistingStub(Failure({astring, tav_null, tav_null}));
  state.InvokeExistingStub({a2int, tav_null, tav_null});
  state.InvokeExistingStub(Failure({a2string, tav_null, tav_null}));

  record_state.InvokeExistingStub(
      Respecialization({record_int_int, tav_null, tav_null}));
  record_state.InvokeExistingStub(
      Failure({record_string_int, tav_null, tav_null}));
  record_state.InvokeExistingStub(
      Failure({record_int_string, tav_null, tav_null}));
}

ISOLATE_UNIT_TEST_CASE(TTS_Partial_Reload) {
  auto& root_library = Library::Handle(LoadTestScript(kLoadedScript));
  const auto& class_a = Class::Handle(GetClass(root_library, "A"));
  ClassFinalizer::FinalizeTypesInClass(class_a);

  const auto& aint = Object::Handle(Invoke(root_library, "createAInt"));
  const auto& astring = Object::Handle(Invoke(root_library, "createAString"));

  const auto& tav_null = Object::null_type_arguments();
  const auto& tav_int =
      TypeArguments::Handle(Instance::Cast(aint).GetTypeArguments());
  const auto& tav_string =
      TypeArguments::Handle(Instance::Cast(astring).GetTypeArguments());
  auto& tav_num = TypeArguments::Handle(TypeArguments::New(1));
  tav_num.SetTypeAt(0, Type::Handle(Type::Number()));
  CanonicalizeTAV(&tav_num);

  // Create a partial TTS to test resets of STCs with false negatives.
  const auto& type_a_t = Type::Handle(class_a.DeclarationType());
  TTSTestCase positive1{aint, tav_int, tav_null};
  TTSTestCase positive2{astring, tav_string, tav_null};
  TTSTestCase negative1 = Failure({astring, tav_int, tav_null});
  TTSTestCase negative2 = Failure({aint, tav_string, tav_null});
  TTSTestCase false_negative = FalseNegative({aint, tav_num, tav_null});
  TTSTestState state(thread, type_a_t);
  state.InvokeLazilySpecializedStub(positive1);
  state.InvokeExistingStub(positive2);
  state.InvokeExistingStub(negative1);
  state.InvokeExistingStub(negative2);
  state.InvokeExistingStub(false_negative);

  root_library = ReloadTestScript(kReloadedScript);
  const auto& a2int = Object::Handle(Invoke(root_library, "createA2Int"));
  const auto& a2string = Object::Handle(Invoke(root_library, "createA2String"));

  // Reloading resets all type testing stubs to the (possibly lazy specializing)
  // default stub for that type.
  EXPECT(type_a_t.type_test_stub() ==
         TypeTestingStubGenerator::DefaultCodeForType(type_a_t));
  // Reloading either removes or resets the type testing cache.
  EXPECT(state.current_stc() == SubtypeTestCache::null() ||
         (state.current_stc() == state.last_stc().ptr() &&
          state.last_stc().NumberOfChecks() == 0));

  state.InvokeExistingStub(Respecialization(positive1));
  state.InvokeExistingStub(positive2);
  state.InvokeExistingStub(negative1);
  state.InvokeExistingStub(negative2);
  state.InvokeExistingStub(false_negative);
  state.InvokeExistingStub({a2int, tav_int, tav_null});
  state.InvokeExistingStub({a2string, tav_string, tav_null});
  state.InvokeExistingStub(Failure({a2string, tav_int, tav_null}));
  state.InvokeExistingStub(Failure({a2int, tav_string, tav_null}));
  state.InvokeExistingStub(FalseNegative({a2int, tav_num, tav_null}));
}
#endif  // !defined(PRODUCT)

// This test checks for a failure due to not reloading the class id between
// different uses of GenerateCidRangeChecks when loading the instance type
// arguments vector in a TTS for an implemented class. GenerateCidRangeChecks
// might clobber the register that holds the class ID to check, hence the need
// to reload.
//
// To ensure that the register is clobbered on all architectures, we set things
// up by generating the following classes:
// * B<X>, a generic abstract class which is implemented by the others.
// * I, implements B<String>, has a single int field x, and is
//   used to create the checked instance.
// * G<Y>, which implements B<Y> and has no fields (so its TAV field
//   offset will correspond to that of the offset of x in I).
// * C and D, consecutively defined non-generic classes which both implement
//   B<int>.
// * U0 - UN, unrelated concrete classes as needed for cid alignment.
//
// We'll carefully set things up so that the following equation between their
// class ids holds:
//
//   G = I - C.
//
// Thus, when we create a TTS for B<int> and check it against an instance V
// of I. The cid for I will be loaded into a register R, and then two
// check blocks will be generated:
//
//   * A check for the cid range [C-D], which has the side effect of
//     subtracting the cid of C from the contents of R (here, the cid of I).
//
//   * A check that R contains the cid for G.
//
// Thus, if the cid of I is not reloaded into R before the second check, and
// the equation earlier holds, we'll get a false positive that V is an instance
// of G, so the code will then try to load the instance type arguments from V
// as if it was an instance of G. This means the contents of x will be loaded
// and attempted to be used as a TypeArgumentsPtr, which will cause a crash
// during the checks that the instantiation of Y is int.
ISOLATE_UNIT_TEST_CASE(TTS_Regress_CidRangeChecks) {
  // We create the classes in this order: B, G, C, D, U..., I. We need
  // G = I - C => G + C = I
  //           => G + C = D + N + 1 (where N is the number of U classes)
  //           => (B + 1) + C = (C + 1) + N + 1
  //           => B - 1 = N.
  // The cid for B will be the next allocated cid, which is the number of
  // non-top-level cids in the current class table.
  ClassTable* const class_table = IsolateGroup::Current()->class_table();
  const intptr_t kNumUnrelated = class_table->NumCids() - 1;
  TextBuffer buffer(1024);
  buffer.AddString(R"(
      abstract class B<X> {}
      class G<Y> implements B<Y> {}
      class C implements B<int> {}
      class D implements B<int> {}
)");
  for (intptr_t i = 0; i < kNumUnrelated; i++) {
    buffer.Printf(R"(
      class U%)" Pd R"( {}
)",
                  i);
  }
  buffer.AddString(R"(
      class I implements B<String> {
        final x = 1;
      }

      createI() => I();
)");

  const auto& root_library = Library::Handle(LoadTestScript(buffer.buffer()));
  const auto& class_b = Class::Handle(GetClass(root_library, "B"));
  const auto& class_g = Class::Handle(GetClass(root_library, "G"));
  const auto& class_c = Class::Handle(GetClass(root_library, "C"));
  const auto& class_d = Class::Handle(GetClass(root_library, "D"));
  const auto& class_u0 = Class::Handle(GetClass(root_library, "U0"));
  const auto& class_i = Class::Handle(GetClass(root_library, "I"));
  const auto& obj_i = Object::Handle(Invoke(root_library, "createI"));
  {
    SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
    ClassFinalizer::FinalizeClass(class_g);
  }

  // Double-check assumptions from calculating kNumUnrelated.
  EXPECT_EQ(kNumUnrelated, class_b.id() - 1);
  EXPECT_EQ(class_b.id() + 1, class_g.id());
  EXPECT_EQ(class_c.id() + 1, class_d.id());
  EXPECT_EQ(class_d.id() + 1, class_u0.id());
  EXPECT_EQ(class_u0.id() + kNumUnrelated, class_i.id());
  EXPECT_EQ(class_g.id(), class_i.id() - class_c.id());

  const auto& tav_null = Object::null_type_arguments();
  auto& tav_int = TypeArguments::Handle(TypeArguments::New(1));
  tav_int.SetTypeAt(0, Type::Handle(Type::IntType()));
  CanonicalizeTAV(&tav_int);

  auto& type_b_int = Type::Handle(Type::New(class_b, tav_int));
  FinalizeAndCanonicalize(&type_b_int);

  TTSTestState state(thread, type_b_int);
  state.InvokeEagerlySpecializedStub(Failure({obj_i, tav_null, tav_null}));
}

static void SubtypeTestCacheHashTest(Thread* thread, intptr_t num_classes) {
  TextBuffer buffer(MB);
  buffer.AddString("class D<S> {}\n");
  buffer.AddString("D<int> Function() createClosureD() => () => D<int>();\n");
  for (intptr_t i = 0; i < num_classes; i++) {
    buffer.Printf(R"(class C%)" Pd R"(<S> extends D<S> {}
        C%)" Pd R"(<int> Function() createClosureC%)" Pd R"(() => () => C%)" Pd
                  R"(<int>();
)",
                  i, i, i, i);
  }

  Dart_Handle api_lib = TestCase::LoadTestScript(buffer.buffer(), nullptr);
  EXPECT_VALID(api_lib);

  // D + C0...CN, where N = kNumClasses - 1
  EXPECT(IsolateGroup::Current()->class_table()->NumCids() > num_classes);

  TransitionNativeToVM transition(thread);
  Zone* const zone = thread->zone();

  const auto& root_lib =
      Library::CheckedHandle(zone, Api::UnwrapHandle(api_lib));
  EXPECT(!root_lib.IsNull());

  const auto& class_d = Class::Handle(zone, GetClass(root_lib, "D"));
  ASSERT(!class_d.IsNull());
  {
    SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
    ClassFinalizer::FinalizeClass(class_d);
  }
  const auto& object_d =
      Instance::CheckedHandle(zone, Invoke(root_lib, "createClosureD"));
  ASSERT(!object_d.IsNull());
  auto& type_closure_d_int =
      AbstractType::Handle(zone, object_d.GetType(Heap::kNew));

  const auto& tav_null = Object::null_type_arguments();

  TTSTestState state(thread, type_closure_d_int);

  auto& class_c = Class::Handle(zone);
  auto& object_c = Object::Handle(zone);
  bool became_hash_cache = false;
  for (intptr_t i = 0; i < num_classes; ++i) {
    auto const class_name = OS::SCreate(zone, "C%" Pd "", i);
    class_c = GetClass(root_lib, class_name);
    ASSERT(!class_c.IsNull());
    {
      SafepointWriteRwLocker ml(thread,
                                thread->isolate_group()->program_lock());
      ClassFinalizer::FinalizeClass(class_c);
    }
    auto const function_name = OS::SCreate(zone, "createClosureC%" Pd "", i);
    object_c = Invoke(root_lib, function_name);

    TTSTestCase base_case = {object_c, tav_null, tav_null,
                             /*should_specialize=*/false};
    if (i == 0) {
      state.InvokeEagerlySpecializedStub(FalseNegative(base_case));
      // We should get a linear cache the first time.
      EXPECT(!state.last_stc().IsHash());
    } else if (i >= FLAG_max_subtype_cache_entries) {
      // We don't need to verify that the STC is unchanged across calls when we
      // no longer have room in the cache, as
      // TTSTestState::ReportUnexpectedSTCChanges already checks this.
      state.InvokeExistingStub(STCMiss(base_case));
    } else if (state.last_stc().IsHash()) {
      state.InvokeExistingStub(STCMiss(base_case));
      // We should never change from hash back to linear.
      EXPECT(state.last_stc().IsHash());
    } else {  // current cache is linear.
      state.InvokeExistingStub(FalseNegative(base_case));
      if (state.last_stc().IsHash()) {
        became_hash_cache = true;
      }
    }
  }

  // Ensure we're actually testing hash caches at some point.
  EXPECT(became_hash_cache);
}

// A smaller version of the following test case, just to ensure some coverage
// on slower builds.
TEST_CASE(TTS_STC_SomeAsserts) {
  SubtypeTestCacheHashTest(thread,
                           2 * SubtypeTestCache::kMaxLinearCacheEntries);
}

// Too slow in debug mode. Also avoid the sanitizers and simulators for similar
// reasons. Any core issues will likely be found by TTS_STC_SomeAsserts.
#if !defined(DEBUG) && !defined(USING_MEMORY_SANITIZER) &&                     \
    !defined(USING_THREAD_SANITIZER) && !defined(USING_LEAK_SANITIZER) &&      \
    !defined(USING_UNDEFINED_BEHAVIOR_SANITIZER) && !defined(USING_SIMULATOR)
TEST_CASE(TTS_STC_ManyAsserts) {
  const intptr_t kNumClasses = 5000;
  static_assert(kNumClasses > SubtypeTestCache::kMaxLinearCacheEntries,
                "too few classes to trigger change to a hash-based cache");
  SubtypeTestCacheHashTest(thread, kNumClasses);
}
#endif

}  // namespace dart

#endif  // !defined(TARGET_ARCH_IA32)

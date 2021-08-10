// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <functional>

#include "platform/assert.h"

#include "vm/class_finalizer.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il_test_helper.h"
#include "vm/flags.h"
#include "vm/lockers.h"
#include "vm/symbols.h"
#include "vm/type_testing_stubs.h"
#include "vm/unit_test.h"

#if defined(TARGET_ARCH_ARM64) || defined(TARGET_ARCH_ARM) ||                  \
    defined(TARGET_ARCH_X64)

namespace dart {

// FLAG_trace_type_checks is only a non-constant in DEBUG mode, so we only
// allow tracing of type testing stub tests there.
#if defined(DEBUG)
DEFINE_FLAG(bool,
            trace_type_testing_stub_tests,
            false,
            "Trace type checks performed in type testing stub tests");
#else
const bool FLAG_trace_type_testing_stub_tests = false;
#endif

class TraceStubInvocationScope : public ValueObject {
 public:
  TraceStubInvocationScope() : old_flag_value_(FLAG_trace_type_checks) {
    if (FLAG_trace_type_testing_stub_tests) {
#if defined(DEBUG)
      FLAG_trace_type_checks = true;
#endif
    }
  }
  ~TraceStubInvocationScope() {
    if (FLAG_trace_type_testing_stub_tests) {
#if defined(DEBUG)
      FLAG_trace_type_checks = old_flag_value_;
#endif
    }
  }

 private:
  const bool old_flag_value_;
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
  *tav = tav->Canonicalize(Thread::Current(), nullptr);
}

struct TTSTestCase : public ValueObject {
  const Instance& instance;
  const TypeArguments& instantiator_tav;
  const TypeArguments& function_tav;
  // Whether the result of the test should be a type error.
  const bool should_fail;
  // Whether a non-default stub will result from specialization.
  const bool should_specialize;
  // Whether the test should not be caught by the TTS, but instead cached
  // in the TTS. If should_specialize is false, then the test case is cached
  // in the TTS after any invocation, otherwise only on invocations after
  // specializations.
  const bool should_be_false_negative;
  // Whether the test should cause specialization of a stub that is already
  // specialized.
  const bool should_respecialize;

  TTSTestCase(const Object& obj,
              const TypeArguments& i_tav,
              const TypeArguments& f_tav,
              bool should_specialize = true,
              bool should_fail = false,
              bool should_be_false_negative = false,
              bool should_respecialize = false)
      : instance(Instance::Cast(obj)),
        instantiator_tav(i_tav),
        function_tav(f_tav),
        should_fail(should_fail),
        should_specialize(should_specialize),
        should_be_false_negative(should_be_false_negative),
        should_respecialize(should_respecialize) {
    // Failure is only compatible with should_specialize (for checking
    // eager specialization a la AOT mode).
    ASSERT(!should_fail || (!should_be_false_negative && !should_respecialize));
    // Respecialization can only happen for test cases that would specialize
    // and which won't end up cached in the TTS.
    ASSERT(!should_respecialize ||
           should_specialize && !should_be_false_negative);
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
    return instance.GetTypeArguments() != other.instance.GetTypeArguments();
  }

  bool HasSTCEntry(const SubtypeTestCache& cache,
                   const AbstractType& dst_type,
                   Bool* out_result = nullptr,
                   intptr_t* out_index = nullptr) const {
    if (cache.IsNull()) return false;
    SafepointMutexLocker ml(
        IsolateGroup::Current()->subtype_test_cache_mutex());
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
      instance_type_arguments = instance.GetTypeArguments();
    }
    return cache.HasCheck(id_smi, dst_type, instance_type_arguments,
                          instantiator_tav, function_tav,
                          Object::null_type_arguments(),
                          Object::null_type_arguments(), out_index, out_result);
  }
};

// Inherits should_specialize from original.
static TTSTestCase Failure(const TTSTestCase& original) {
  return TTSTestCase(original.instance, original.instantiator_tav,
                     original.function_tav, original.should_specialize,
                     /*should_fail=*/true,
                     /*should_be_false_negative=*/false,
                     /*should_respecialize=*/false);
}

// Inherits should_specialize from original.
static TTSTestCase FalseNegative(const TTSTestCase& original) {
  return TTSTestCase(original.instance, original.instantiator_tav,
                     original.function_tav, original.should_specialize,
                     /*should_fail=*/false,
                     /*should_be_false_negative=*/true,
                     /*should_respecialize=*/false);
}

static TTSTestCase Respecialization(const TTSTestCase& original) {
  return TTSTestCase(original.instance, original.instantiator_tav,
                     original.function_tav, /*should_specialize=*/true,
                     /*should_fail=*/false,
                     /*should_be_false_negative=*/false,
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
    THR_Print("Creating test state for type %s\n", type.ToCString());
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
    previous_tts_stub_ =
        TypeTestingStubGenerator::SpecializeStubFor(thread_, last_tested_type_);
    EXPECT_EQ(test_case.should_specialize,
              previous_tts_stub_.ptr() != default_stub.ptr());
    last_tested_type_.SetTypeTestingStub(previous_tts_stub_);
    PrintInvocationHeader(test_case);
    InvokeStubHelper(test_case);
    // Treat it as a failure if the stub respecializes, since we're attempting
    // to simulate AOT mode.
    EXPECT(previous_tts_stub_.ptr() == new_tts_stub_.ptr());
    ReportUnexpectedSTCChanges(test_case);
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
    PrintInvocationHeader(test_case);
    last_tested_type_.SetTypeTestingStub(specializing_stub);
    InvokeStubHelper(test_case,
                     /*is_lazy_specialization=*/test_case.should_specialize);
    if (test_case.should_fail) {
      // We only respecialize on successful checks.
      EXPECT(new_tts_stub_.ptr() == specializing_stub.ptr());
    } else if (test_case.should_specialize) {
      // Specializing test cases should never result in a default TTS.
      EXPECT(new_tts_stub_.ptr() != default_stub.ptr());
    } else {
      // Non-specializing test cases should result in a default TTS.
      EXPECT(new_tts_stub_.ptr() == default_stub.ptr());
    }
    ReportUnexpectedSTCChanges(
        test_case, /*is_lazy_specialization=*/test_case.should_specialize);
  }

  void InvokeExistingStub(const TTSTestCase& test_case) {
    last_tested_type_ = TypeToTest(test_case);
    PrintInvocationHeader(test_case);
    InvokeStubHelper(test_case);
    // Only respecialization should result in a new stub.
    EXPECT_EQ(test_case.should_respecialize,
              previous_tts_stub_.ptr() != new_tts_stub_.ptr());
    ReportUnexpectedSTCChanges(test_case);
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

  void PrintInvocationHeader(const TTSTestCase& test_case) {
    LogBlock lb;
    const auto& tts = Code::Handle(zone(), last_tested_type_.type_test_stub());
    auto* const stub_name = StubCode::NameOfStub(tts.EntryPoint());
    THR_Print("Testing %s stub for type %s\n",
              stub_name == nullptr ? "optimized" : stub_name,
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
    compiler::ObjectPoolBuilder pool_builder;
    const auto& invoke_tts = Code::Handle(
        zone,
        StubCode::Generate("InvokeTTS", &pool_builder, &GenerateInvokeTTSStub));
    const auto& pool =
        ObjectPool::Handle(zone, ObjectPool::NewFromBuilder(pool_builder));
    invoke_tts.set_object_pool(pool.ptr());
    invoke_tts.set_owner(function);
    invoke_tts.set_exception_handlers(
        ExceptionHandlers::Handle(zone, ExceptionHandlers::New(0)));
    EXPECT_EQ(2, pool.Length());
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
    {
      TraceStubInvocationScope scope;
      last_result_ = DartEntry::InvokeCode(
          tts_invoker_, tts_invoker_.EntryPoint(), arguments_descriptor_,
          last_arguments_, thread_);
    }
    new_tts_stub_ = last_tested_type_.type_test_stub();
    last_stc_ = current_stc();
    EXPECT_EQ(test_case.should_fail, !last_result_.IsNull());
    if (test_case.should_fail) {
      EXPECT(last_result_.IsError());
      EXPECT(last_result_.IsUnhandledException());
      const auto& error =
          Instance::Handle(UnhandledException::Cast(last_result_).exception());
      EXPECT(strstr(error.ToCString(), "_TypeError"));
    } else {
      EXPECT(new_tts_stub_.ptr() != StubCode::LazySpecializeTypeTest().ptr());
      ReportModifiedRegisters(modified_abi_regs());
      // If we shouldn't go to the runtime, report any unexpected changes in
      // non-ABI registers.
      if (!is_lazy_specialization && !test_case.should_respecialize &&
          (!test_case.should_be_false_negative ||
           test_case.HasSTCEntry(previous_stc_, type_))) {
        ReportModifiedRegisters(modified_rest_regs());
      }
    }
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

  void ReportUnexpectedSTCChanges(const TTSTestCase& test_case,
                                  bool is_lazy_specialization = false) {
    ASSERT(!test_case.should_be_false_negative ||
           !test_case.should_respecialize);
    const bool had_stc_entry = test_case.HasSTCEntry(previous_stc_, type_);
    const bool should_update_stc =
        !is_lazy_specialization && test_case.should_be_false_negative;
    if (should_update_stc && !had_stc_entry) {
      // We should have changed the STC to include the new entry.
      EXPECT(previous_stc_.IsNull() && !last_stc_.IsNull() ||
             previous_stc_.cache() != last_stc_.cache());
      // We only should have added one check.
      EXPECT_EQ(previous_stc_.IsNull() ? 1 : previous_stc_.NumberOfChecks() + 1,
                last_stc_.NumberOfChecks());
      if (!previous_stc_.IsNull()) {
        // Make sure all the checks in the previous STC are still there.
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
        for (intptr_t i = 0; i < previous_stc_.NumberOfChecks(); i++) {
          previous_stc_.GetCheck(0, &cid_or_sig, &type, &instance_type_args,
                                 &instantiator_type_args, &function_type_args,
                                 &instance_parent_type_args,
                                 &instance_delayed_type_args, &old_result);
          intptr_t new_index;
          if (!last_stc_.HasCheck(
                  cid_or_sig, type, instance_type_args, instantiator_type_args,
                  function_type_args, instance_parent_type_args,
                  instance_delayed_type_args, &new_index, &new_result)) {
            dart::Expect(__FILE__, __LINE__)
                .Fail("New STC is missing check in old STC");
          }
          if (old_result.value() != new_result.value()) {
            dart::Expect(__FILE__, __LINE__)
                .Fail("New STC has different result from old STC");
          }
        }
      }
    } else {
      // Whatever STC existed before, if any, should be unchanged.
      EXPECT(previous_stc_.IsNull() && last_stc_.IsNull() ||
             previous_stc_.cache() == last_stc_.cache());
    }

    // False negatives should always be an STC hit when not lazily
    // (re)specializing. Note that we test the original type, _not_
    // last_tested_type_.
    const bool has_stc_entry = test_case.HasSTCEntry(last_stc_, type_);
    if ((!should_update_stc && has_stc_entry) ||
        (should_update_stc && !has_stc_entry)) {
      TextBuffer buffer(128);
      buffer.Printf("%s entry for %s, got:\n",
                    should_update_stc ? "Expected" : "Did not expect",
                    type_.ToCString());
      for (intptr_t i = 0; i < last_stc_.NumberOfChecks(); i++) {
        last_stc_.WriteCurrentEntryToBuffer(zone(), &buffer, i);
        buffer.AddString("\n");
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

// Tests three situations in turn with the same test case:
// 1) Install the lazy specialization stub for JIT and test.
// 2) Test again without installing a stub, so using the stub resulting from 1.
// 3) Install an eagerly specialized stub, similar to AOT mode but keeping any
//    STC created by the earlier steps, and test.
static void RunTTSTest(const AbstractType& dst_type,
                       const TTSTestCase& test_case) {
  TTSTestState state(Thread::Current(), dst_type);
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

  // We do not generate TTS for uninstantiated types if we would need to use
  // subtype range checks for the class of the interface type.
  //
  //   obj as I<dynamic, T>
  //
  auto& type_dynamic_t =
      AbstractType::Handle(Type::New(class_i, tav_dynamic_t));
  FinalizeAndCanonicalize(&type_dynamic_t);
  RunTTSTest(type_dynamic_t, FalseNegative({obj_i, tav_object, tav_null,
                                            /*should_specialize=*/false}));
  RunTTSTest(type_dynamic_t, Failure({obj_i2, tav_object, tav_null,
                                      /*should_specialize=*/false}));
  RunTTSTest(type_dynamic_t, Failure({obj_base_int, tav_object, tav_null,
                                      /*should_specialize=*/false}));
  RunTTSTest(type_dynamic_t, Failure({obj_a, tav_object, tav_null,
                                      /*should_specialize=*/false}));
  RunTTSTest(type_dynamic_t, Failure({obj_a1, tav_object, tav_null,
                                      /*should_specialize=*/false}));
  RunTTSTest(type_dynamic_t, FalseNegative({obj_a2, tav_object, tav_null,
                                            /*should_specialize=*/false}));
  RunTTSTest(type_dynamic_t, Failure({obj_b, tav_object, tav_null,
                                      /*should_specialize=*/false}));
  RunTTSTest(type_dynamic_t, Failure({obj_b1, tav_object, tav_null,
                                      /*should_specialize=*/false}));
  RunTTSTest(type_dynamic_t, FalseNegative({obj_b2, tav_object, tav_null,
                                            /*should_specialize=*/false}));

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

  // We do not generate TTS for uninstantiated types if we would need to use
  // subtype range checks for the class of the interface type.
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
  RunTTSTest(
      type_i_dynamic_string,
      FalseNegative({obj_i, tav_null, tav_null, /*should_specialize=*/false}));
  RunTTSTest(type_i_dynamic_string, Failure({obj_base_int, tav_null, tav_null,
                                             /*should_specialize=*/false}));

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
  const auto& root_library = Library::Handle(Library::CoreLibrary());
  const auto& smi_class = Class::Handle(GetClass(root_library, "_Smi"));
  ClassFinalizer::FinalizeTypesInClass(smi_class);

  const auto& dst_type = AbstractType::Handle(smi_class.RareType());
  const auto& tav_null = TypeArguments::Handle(TypeArguments::null());

  THR_Print("\nTesting that instance of _Smi is a subtype of _Smi\n");
  RunTTSTest(dst_type, {Smi::Handle(Smi::New(0)), tav_null, tav_null});
}

ISOLATE_UNIT_TEST_CASE(TTS_Partial) {
  const char* kScript =
      R"(
      class B<T> {}
      F<A>() {}
      createB() => B<int>();
)";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& class_b = Class::Handle(GetClass(root_library, "B"));
  const auto& fun_f = Function::Handle(GetFunction(root_library, "F"));
  const auto& obj_b = Object::Handle(Invoke(root_library, "createB"));

  const auto& tav_null = Object::null_type_arguments();
  auto& tav_int = TypeArguments::Handle(TypeArguments::New(1));
  tav_int.SetTypeAt(0, Type::Handle(Type::IntType()));
  CanonicalizeTAV(&tav_int);
  auto& tav_object = TypeArguments::Handle(TypeArguments::New(1));
  tav_object.SetTypeAt(0, Type::Handle(Type::ObjectType()));
  CanonicalizeTAV(&tav_object);
  auto& tav_num = TypeArguments::Handle(TypeArguments::New(1));
  tav_num.SetTypeAt(0, Type::Handle(Type::Number()));
  CanonicalizeTAV(&tav_num);

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
  auto& type_b2_a = AbstractType::Handle(Type::New(class_b, tav_a));
  FinalizeAndCanonicalize(&type_b2_a);
  TTSTestState state(thread, type_b2_a);

  TTSTestCase positive_test_case{obj_b, tav_null, tav_int};
  TTSTestCase first_false_negative_test_case =
      FalseNegative({obj_b, tav_null, tav_object});
  TTSTestCase second_false_negative_test_case =
      FalseNegative({obj_b, tav_null, tav_num});
  // No test case should possibly hit the same STC entry as another.
  ASSERT(!first_false_negative_test_case.HasSameSTCEntry(positive_test_case));
  ASSERT(!second_false_negative_test_case.HasSameSTCEntry(positive_test_case));
  ASSERT(!second_false_negative_test_case.HasSameSTCEntry(
      first_false_negative_test_case));
  // The type with the tested stub must be the same in all test cases.
  ASSERT(state.TypeToTest(positive_test_case) ==
         state.TypeToTest(first_false_negative_test_case));
  ASSERT(state.TypeToTest(positive_test_case) ==
         state.TypeToTest(second_false_negative_test_case));

  // First, test that the positive test case is handled by the TTS.
  state.InvokeLazilySpecializedStub(positive_test_case);
  state.InvokeExistingStub(positive_test_case);

  // Now restart, using the false negative test cases.
  state.ClearCache();

  state.InvokeLazilySpecializedStub(first_false_negative_test_case);
  state.InvokeExistingStub(first_false_negative_test_case);
  state.InvokeEagerlySpecializedStub(first_false_negative_test_case);

  state.InvokeExistingStub(positive_test_case);
  state.InvokeExistingStub(second_false_negative_test_case);
  state.InvokeExistingStub(first_false_negative_test_case);
  state.InvokeExistingStub(positive_test_case);
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
  EXPECT(state.last_stc().IsNull() && stc_cache.IsNull() ||
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
  EXPECT(state.last_stc().IsNull() && stc_cache.IsNull() ||
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
  )";

static const char* kReloadedScript =
    R"(
          class A<T> {}
          class A2<T> extends A<T> {}

          createAInt() => A<int>();
          createAString() => A<String>();
          createA2Int() => A2<int>();
          createA2String() => A2<String>();
  )";

ISOLATE_UNIT_TEST_CASE(TTS_Reload) {
  auto& root_library = Library::Handle(LoadTestScript(kLoadedScript));
  const auto& class_a = Class::Handle(GetClass(root_library, "A"));
  ClassFinalizer::FinalizeTypesInClass(class_a);

  const auto& aint = Object::Handle(Invoke(root_library, "createAInt"));
  const auto& astring = Object::Handle(Invoke(root_library, "createAString"));

  const auto& tav_null = Object::null_type_arguments();
  const auto& tav_int =
      TypeArguments::Handle(Instance::Cast(aint).GetTypeArguments());
  auto& tav_num = TypeArguments::Handle(TypeArguments::New(1));
  tav_num.SetTypeAt(0, Type::Handle(Type::Number()));
  CanonicalizeTAV(&tav_num);

  auto& type_a_int = Type::Handle(Type::New(class_a, tav_int));
  FinalizeAndCanonicalize(&type_a_int);

  TTSTestState state(thread, type_a_int);
  state.InvokeLazilySpecializedStub({aint, tav_null, tav_null});
  state.InvokeExistingStub(Failure({astring, tav_null, tav_null}));

  root_library = ReloadTestScript(kReloadedScript);
  const auto& a2int = Object::Handle(Invoke(root_library, "createA2Int"));
  const auto& a2string = Object::Handle(Invoke(root_library, "createA2String"));

  // Reloading resets all type testing stubs to the (possibly lazy specializing)
  // default stub for that type.
  EXPECT(type_a_int.type_test_stub() ==
         TypeTestingStubGenerator::DefaultCodeForType(type_a_int));
  // Reloading either removes or resets the type teseting cache.
  EXPECT(state.current_stc() == SubtypeTestCache::null() ||
         (state.current_stc() == state.last_stc().ptr() &&
          state.last_stc().NumberOfChecks() == 0));

  state.InvokeExistingStub(Respecialization({aint, tav_null, tav_null}));
  state.InvokeExistingStub(Failure({astring, tav_null, tav_null}));
  state.InvokeExistingStub({a2int, tav_null, tav_null});
  state.InvokeExistingStub(Failure({a2string, tav_null, tav_null}));
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

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM64) ||  defined(TARGET_ARCH_ARM) ||          \
        // defined(TARGET_ARCH_X64)

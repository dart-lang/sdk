// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <functional>

#include "platform/assert.h"

#include "vm/class_finalizer.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il_test_helper.h"
#include "vm/symbols.h"
#include "vm/type_testing_stubs.h"
#include "vm/unit_test.h"

#if defined(TARGET_ARCH_ARM64) || defined(TARGET_ARCH_ARM) ||                  \
    defined(TARGET_ARCH_X64)

namespace dart {

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

static void RunTTSTest(
    const Object& instance,
    const AbstractType& dst_type,
    const TypeArguments& instantiator_tav,
    const TypeArguments& function_tav,
    std::function<void(const Object& result, const SubtypeTestCache& stc)> lazy,
    std::function<void(const Object& result,
                       const SubtypeTestCache& stc,
                       const Smi& abi_regs_modified,
                       const Smi& rest_regs_modified)> nonlazy) {
  ASSERT(instantiator_tav.IsNull() || instantiator_tav.IsCanonical());
  ASSERT(function_tav.IsNull() || function_tav.IsCanonical());
  auto thread = Thread::Current();

  // Build a stub which will do calling conversion to call TTS stubs.
  const auto& klass =
      Class::Handle(thread->isolate()->class_table()->At(kInstanceCid));
  const auto& symbol = String::Handle(
      Symbols::New(thread, OS::SCreate(thread->zone(), "TTSTest")));
  const auto& function = Function::Handle(
      Function::New(symbol, FunctionLayout::kRegularFunction, false, false,
                    false, false, false, klass, TokenPosition::kNoSource));
  compiler::ObjectPoolBuilder pool_builder;
  const auto& invoke_tts = Code::Handle(
      StubCode::Generate("InvokeTTS", &pool_builder, &GenerateInvokeTTSStub));
  const auto& pool =
      ObjectPool::Handle(ObjectPool::NewFromBuilder(pool_builder));
  invoke_tts.set_object_pool(pool.raw());
  invoke_tts.set_owner(function);
  invoke_tts.set_exception_handlers(
      ExceptionHandlers::Handle(ExceptionHandlers::New(0)));

  EXPECT_EQ(2, pool.Length());
  const intptr_t kSubtypeTestCacheIndex = 0;

  const auto& arguments_descriptor =
      Array::Handle(ArgumentsDescriptor::NewBoxed(0, 6));
  const auto& arguments = Array::Handle(Array::New(6));
  const auto& abi_regs_modified_box = Array::Handle(Array::New(1));
  const auto& rest_regs_modified_box = Array::Handle(Array::New(1));
  arguments.SetAt(0, abi_regs_modified_box);
  arguments.SetAt(1, rest_regs_modified_box);
  arguments.SetAt(2, instance);
  arguments.SetAt(3, instantiator_tav);
  arguments.SetAt(4, function_tav);
  arguments.SetAt(5, dst_type);

  // Ensure we have a) uninitialized TTS b) no/empty SubtypeTestCache.
  auto& instantiated_dst_type = AbstractType::Handle(dst_type.raw());
  if (dst_type.IsTypeParameter()) {
    instantiated_dst_type = TypeParameter::Cast(dst_type).GetFromTypeArguments(
        instantiator_tav, function_tav);
  }
  instantiated_dst_type.SetTypeTestingStub(StubCode::LazySpecializeTypeTest());
  EXPECT(instantiated_dst_type.type_test_stub() ==
         StubCode::LazySpecializeTypeTest().raw());
  EXPECT(pool.ObjectAt(kSubtypeTestCacheIndex) == Object::null());

  auto& result = Object::Handle();
  auto& result2 = Object::Handle();
  auto& abi_regs_modified = Smi::Handle();
  auto& rest_regs_modified = Smi::Handle();
  auto& tts = Code::Handle();
  auto& tts2 = Code::Handle();
  auto& stc = SubtypeTestCache::Handle();
  auto& stc2 = SubtypeTestCache::Handle();

  // First invocation will a) specialize the TTS b) may create SubtypeTestCache
  result = DartEntry::InvokeCode(invoke_tts, arguments_descriptor, arguments,
                                 thread);
  stc ^= pool.ObjectAt(kSubtypeTestCacheIndex);
  tts = instantiated_dst_type.type_test_stub();
  if (!result.IsError()) {
    EXPECT(tts.raw() != StubCode::LazySpecializeTypeTest().raw());
  }
  lazy(result, stc);

  // Second invocation will a) keep TTS b) keep optional SubtypeTestCache
  result2 = DartEntry::InvokeCode(invoke_tts, arguments_descriptor, arguments,
                                  thread);
  stc2 ^= pool.ObjectAt(kSubtypeTestCacheIndex);
  tts2 = instantiated_dst_type.type_test_stub();
  abi_regs_modified ^= abi_regs_modified_box.At(0);
  rest_regs_modified ^= rest_regs_modified_box.At(0);
  EXPECT(result2.IsError() || !abi_regs_modified.IsNull());
  EXPECT(tts2.raw() == tts.raw());
  EXPECT(stc2.raw() == stc.raw());
  nonlazy(result2, stc2, abi_regs_modified, rest_regs_modified);

  // Third invocation will a) explicitly install TTS beforehand b) keep optional
  // SubtypeTestCache
  // (This is to simulate AOT where we don't use lazy specialization but
  // precompile the TTS)
  TypeTestingStubGenerator::SpecializeStubFor(thread, instantiated_dst_type);
  tts = instantiated_dst_type.type_test_stub();

  result2 = DartEntry::InvokeCode(invoke_tts, arguments_descriptor, arguments,
                                  thread);
  stc2 ^= pool.ObjectAt(kSubtypeTestCacheIndex);
  tts2 = instantiated_dst_type.type_test_stub();
  abi_regs_modified ^= abi_regs_modified_box.At(0);
  rest_regs_modified ^= rest_regs_modified_box.At(0);
  EXPECT(result2.IsError() || !abi_regs_modified.IsNull());
  EXPECT(tts2.raw() == tts.raw());
  EXPECT(stc2.raw() == stc.raw());
  nonlazy(result2, stc2, abi_regs_modified, rest_regs_modified);
}

static void ReportModifiedRegisters(const Smi& modified_registers) {
  const intptr_t reg_mask = Smi::Cast(modified_registers).Value();
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
    if (((1 << i) & reg_mask) != 0) {
      const Register reg = static_cast<Register>(i);
      dart::Expect(__FILE__, __LINE__)
          .Fail("%s was modified", RegisterNames::RegisterName(reg));
    }
  }
}

static void CommonTTSHandledChecks(const Object& result,
                                   const SubtypeTestCache& stc) {
  // Ensure the type test succeeded.
  EXPECT(result.IsNull());
  // Ensure we didn't fall back to the subtype test cache.
  EXPECT(stc.IsNull());
}

static void ExpectLazilyHandledViaTTS(const Object& result,
                                      const SubtypeTestCache& stc) {
  THR_Print("Testing lazy handled via TTS\n");
  CommonTTSHandledChecks(result, stc);
}

static void ExpectHandledViaTTS(const Object& result,
                                const SubtypeTestCache& stc,
                                const Smi& abi_regs_modified,
                                const Smi& rest_regs_modified) {
  THR_Print("Testing non-lazy handled via TTS\n");
  CommonTTSHandledChecks(result, stc);
  // Ensure the TTS abi registers were preserved.
  ReportModifiedRegisters(abi_regs_modified);
  // Ensure the non-TTS abi registers were preserved.
  ReportModifiedRegisters(rest_regs_modified);
}

static void CommonSTCHandledChecks(const Object& result,
                                   const SubtypeTestCache& stc) {
  // Ensure the type test succeeded.
  EXPECT(result.IsNull());
  // Ensure we did fall back to the subtype test cache.
  EXPECT(!stc.IsNull());
  // Ensure the test is marked as succeeding in the STC.
  EXPECT_EQ(1, stc.NumberOfChecks());
  SubtypeTestCacheTable entries(Array::Handle(stc.cache()));
  EXPECT(entries[0].Get<SubtypeTestCache::kTestResult>() ==
         Object::bool_true().raw());
}

static void ExpectLazilyHandledViaSTC(const Object& result,
                                      const SubtypeTestCache& stc) {
  THR_Print("Testing lazy handled via STC\n");
  CommonSTCHandledChecks(result, stc);
}

static void ExpectHandledViaSTC(const Object& result,
                                const SubtypeTestCache& stc,
                                const Smi& abi_regs_modified,
                                const Smi& rest_regs_modified) {
  THR_Print("Testing non-lazy handled via STC\n");
  CommonSTCHandledChecks(result, stc);
  // Ensure the TTS/STC abi registers were preserved.
  ReportModifiedRegisters(abi_regs_modified);
  // Ensure the non-TTS abi registers were preserved.
  ReportModifiedRegisters(rest_regs_modified);
}

static void CommonTTSFailureChecks(const Object& result,
                                   const SubtypeTestCache& stc) {
  // Ensure we have not updated STC (which we shouldn't do in case the type test
  // fails, i.e. an exception is thrown).
  EXPECT(stc.IsNull());
  // Ensure we get a proper exception for the type test.
  EXPECT(result.IsUnhandledException());
  const auto& error =
      Instance::Handle(UnhandledException::Cast(result).exception());
  EXPECT(strstr(error.ToCString(), "_TypeError"));
}

static void ExpectLazilyFailedViaTTS(const Object& result,
                                     const SubtypeTestCache& stc) {
  THR_Print("Testing lazy failure via TTS\n");
  CommonTTSFailureChecks(result, stc);
}

static void ExpectFailedViaTTS(const Object& result,
                               const SubtypeTestCache& stc,
                               const Smi& abi_regs_modified,
                               const Smi& rest_regs_modified) {
  THR_Print("Testing nonlazy failure via TTS\n");
  CommonTTSFailureChecks(result, stc);
  // Registers only need to be preserved on success.
}

static void CommonSTCFailureChecks(const Object& result,
                                   const SubtypeTestCache& stc) {
  // Ensure we have not updated STC (which we shouldn't do in case the type test
  // fails, i.e. an exception is thrown).
  EXPECT(stc.IsNull());
  // Ensure we get a proper exception for the type test.
  EXPECT(result.IsUnhandledException());
  const auto& error =
      Instance::Handle(UnhandledException::Cast(result).exception());
  EXPECT(strstr(error.ToCString(), "_TypeError"));
}

static void ExpectLazilyFailedViaSTC(const Object& result,
                                     const SubtypeTestCache& stc) {
  THR_Print("Testing lazy failure via STC\n");
  CommonSTCFailureChecks(result, stc);
}

static void ExpectFailedViaSTC(const Object& result,
                               const SubtypeTestCache& stc,
                               const Smi& abi_regs_modified,
                               const Smi& rest_regs_modified) {
  THR_Print("Testing non-lazy failure via STC\n");
  CommonSTCFailureChecks(result, stc);
  // Registers only need to be preserved on success.
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
  const auto& obj_baseint =
      Object::Handle(Invoke(root_library, "createBaseInt"));
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
      1, TypeParameter::Handle(GetClassTypeParameter(class_base, "T")));
  CanonicalizeTAV(&tav_dynamic_t);

  // We will generate specialized TTS for instantiated interface types
  // where there are no type arguments or the type arguments are top
  // types.
  //
  //   obj as A                  // Subclass ranges
  //   obj as Base<Object>       // Subclass ranges with top-type tav
  //   obj as I2                 // Subtype ranges
  //   obj as I<Object, dynamic> // Subtype ranges with top-type tav
  //

  // <...> as A
  const auto& type_a = AbstractType::Handle(class_a.RareType());
  RunTTSTest(obj_i, type_a, tav_null, tav_null, ExpectLazilyFailedViaTTS,
             ExpectFailedViaTTS);
  RunTTSTest(obj_i2, type_a, tav_null, tav_null, ExpectLazilyFailedViaTTS,
             ExpectFailedViaTTS);
  RunTTSTest(obj_baseint, type_a, tav_null, tav_null, ExpectLazilyFailedViaTTS,
             ExpectFailedViaTTS);
  RunTTSTest(obj_a, type_a, tav_null, tav_null, ExpectLazilyHandledViaTTS,
             ExpectHandledViaTTS);
  RunTTSTest(obj_a1, type_a, tav_null, tav_null, ExpectLazilyHandledViaTTS,
             ExpectHandledViaTTS);
  RunTTSTest(obj_a2, type_a, tav_null, tav_null, ExpectLazilyHandledViaTTS,
             ExpectHandledViaTTS);
  RunTTSTest(obj_b, type_a, tav_null, tav_null, ExpectLazilyFailedViaTTS,
             ExpectFailedViaTTS);
  RunTTSTest(obj_b1, type_a, tav_null, tav_null, ExpectLazilyFailedViaTTS,
             ExpectFailedViaTTS);
  RunTTSTest(obj_b2, type_a, tav_null, tav_null, ExpectLazilyFailedViaTTS,
             ExpectFailedViaTTS);

  // <...> as Base<Object>
  auto& type_base = AbstractType::Handle(
      Type::New(class_base, tav_object, TokenPosition::kNoSource));
  FinalizeAndCanonicalize(&type_base);
  RunTTSTest(obj_i, type_base, tav_null, tav_null, ExpectLazilyFailedViaTTS,
             ExpectFailedViaTTS);
  RunTTSTest(obj_i2, type_base, tav_null, tav_null, ExpectLazilyFailedViaTTS,
             ExpectFailedViaTTS);
  RunTTSTest(obj_baseint, type_base, tav_null, tav_null,
             ExpectLazilyHandledViaTTS, ExpectHandledViaTTS);
  RunTTSTest(obj_a, type_base, tav_null, tav_null, ExpectLazilyHandledViaTTS,
             ExpectHandledViaTTS);
  RunTTSTest(obj_a1, type_base, tav_null, tav_null, ExpectLazilyHandledViaTTS,
             ExpectHandledViaTTS);
  RunTTSTest(obj_a2, type_base, tav_null, tav_null, ExpectLazilyHandledViaTTS,
             ExpectHandledViaTTS);
  RunTTSTest(obj_b, type_base, tav_null, tav_null, ExpectLazilyHandledViaTTS,
             ExpectHandledViaTTS);
  RunTTSTest(obj_b1, type_base, tav_null, tav_null, ExpectLazilyHandledViaTTS,
             ExpectHandledViaTTS);
  RunTTSTest(obj_b2, type_base, tav_null, tav_null, ExpectLazilyHandledViaTTS,
             ExpectHandledViaTTS);

  // <...> as I2
  const auto& type_i2 = AbstractType::Handle(class_i2.RareType());
  RunTTSTest(obj_i, type_i2, tav_null, tav_null, ExpectLazilyFailedViaTTS,
             ExpectFailedViaTTS);
  RunTTSTest(obj_i2, type_i2, tav_null, tav_null, ExpectLazilyHandledViaTTS,
             ExpectHandledViaTTS);
  RunTTSTest(obj_baseint, type_i2, tav_null, tav_null, ExpectLazilyFailedViaTTS,
             ExpectFailedViaTTS);
  RunTTSTest(obj_a, type_i2, tav_null, tav_null, ExpectLazilyFailedViaTTS,
             ExpectFailedViaTTS);
  RunTTSTest(obj_a1, type_i2, tav_null, tav_null, ExpectLazilyHandledViaTTS,
             ExpectHandledViaTTS);
  RunTTSTest(obj_a2, type_i2, tav_null, tav_null, ExpectLazilyFailedViaTTS,
             ExpectFailedViaTTS);
  RunTTSTest(obj_b, type_i2, tav_null, tav_null, ExpectLazilyFailedViaTTS,
             ExpectFailedViaTTS);
  RunTTSTest(obj_b1, type_i2, tav_null, tav_null, ExpectLazilyHandledViaTTS,
             ExpectHandledViaTTS);
  RunTTSTest(obj_b2, type_i2, tav_null, tav_null, ExpectLazilyFailedViaTTS,
             ExpectFailedViaTTS);

  // <...> as I<Object, dynamic>
  auto& type_i_object_dynamic = AbstractType::Handle(
      Type::New(class_i, tav_object_dynamic, TokenPosition::kNoSource));
  FinalizeAndCanonicalize(&type_i_object_dynamic);
  RunTTSTest(obj_i, type_i_object_dynamic, tav_null, tav_null,
             ExpectLazilyHandledViaTTS, ExpectHandledViaTTS);
  RunTTSTest(obj_i2, type_i_object_dynamic, tav_null, tav_null,
             ExpectLazilyFailedViaTTS, ExpectFailedViaTTS);
  RunTTSTest(obj_baseint, type_i_object_dynamic, tav_null, tav_null,
             ExpectLazilyFailedViaTTS, ExpectFailedViaTTS);
  RunTTSTest(obj_a, type_i_object_dynamic, tav_null, tav_null,
             ExpectLazilyFailedViaTTS, ExpectFailedViaTTS);
  RunTTSTest(obj_a1, type_i_object_dynamic, tav_null, tav_null,
             ExpectLazilyFailedViaTTS, ExpectFailedViaTTS);
  RunTTSTest(obj_a2, type_i_object_dynamic, tav_null, tav_null,
             ExpectLazilyHandledViaTTS, ExpectHandledViaTTS);
  RunTTSTest(obj_b, type_i_object_dynamic, tav_null, tav_null,
             ExpectLazilyFailedViaTTS, ExpectFailedViaTTS);
  RunTTSTest(obj_b1, type_i_object_dynamic, tav_null, tav_null,
             ExpectLazilyFailedViaTTS, ExpectFailedViaTTS);
  RunTTSTest(obj_b2, type_i_object_dynamic, tav_null, tav_null,
             ExpectLazilyHandledViaTTS, ExpectHandledViaTTS);

  // We do not generate TTS for uninstantiated types if we would need to use
  // subtype range checks for the class of the interface type.
  //
  //   obj as I<dynamic, T>
  //
  auto& type_dynamic_t = AbstractType::Handle(
      Type::New(class_i, tav_dynamic_t, TokenPosition::kNoSource));
  FinalizeAndCanonicalize(&type_dynamic_t);
  RunTTSTest(obj_i, type_dynamic_t, tav_object, tav_null,
             ExpectLazilyHandledViaSTC, ExpectHandledViaSTC);
  RunTTSTest(obj_i2, type_dynamic_t, tav_object, tav_null,
             ExpectLazilyFailedViaSTC, ExpectFailedViaSTC);
  RunTTSTest(obj_baseint, type_dynamic_t, tav_object, tav_null,
             ExpectLazilyFailedViaSTC, ExpectFailedViaSTC);
  RunTTSTest(obj_a, type_dynamic_t, tav_object, tav_null,
             ExpectLazilyFailedViaSTC, ExpectFailedViaSTC);
  RunTTSTest(obj_a1, type_dynamic_t, tav_object, tav_null,
             ExpectLazilyFailedViaSTC, ExpectFailedViaSTC);
  RunTTSTest(obj_a2, type_dynamic_t, tav_object, tav_null,
             ExpectLazilyHandledViaSTC, ExpectHandledViaSTC);
  RunTTSTest(obj_b, type_dynamic_t, tav_object, tav_null,
             ExpectLazilyFailedViaSTC, ExpectFailedViaSTC);
  RunTTSTest(obj_b1, type_dynamic_t, tav_object, tav_null,
             ExpectLazilyFailedViaSTC, ExpectFailedViaSTC);
  RunTTSTest(obj_b2, type_dynamic_t, tav_object, tav_null,
             ExpectLazilyHandledViaSTC, ExpectHandledViaSTC);

  // obj as Object (with null safety)
  Isolate* isolate = Isolate::Current();
  if (isolate->null_safety()) {
    auto& type_non_nullable_object =
        Type::Handle(isolate->object_store()->non_nullable_object_type());
    RunTTSTest(obj_a, type_non_nullable_object, tav_null, tav_null,
               ExpectLazilyHandledViaTTS, ExpectHandledViaTTS);
    RunTTSTest(Object::null_object(), type_non_nullable_object, tav_null,
               tav_null, ExpectLazilyFailedViaTTS, ExpectFailedViaTTS);
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
  const auto& obj_baseint =
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

  auto& type_i_object_dynamic = AbstractType::Handle(
      Type::New(class_i, tav_object_dynamic, TokenPosition::kNoSource));
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
  auto& type_base_i_object_dynamic = AbstractType::Handle(
      Type::New(class_base, tav_iod, TokenPosition::kNoSource));
  FinalizeAndCanonicalize(&type_base_i_object_dynamic);
  RunTTSTest(obj_baseb2int, type_base_i_object_dynamic, tav_null, tav_null,
             ExpectLazilyHandledViaTTS, ExpectHandledViaTTS);
  RunTTSTest(obj_baseistringdouble, type_base_i_object_dynamic, tav_null,
             tav_null, ExpectLazilyHandledViaTTS, ExpectHandledViaTTS);
  RunTTSTest(obj_a, type_base_i_object_dynamic, tav_null, tav_null,
             ExpectLazilyFailedViaTTS, ExpectFailedViaTTS);
  RunTTSTest(obj_a1, type_base_i_object_dynamic, tav_null, tav_null,
             ExpectLazilyFailedViaTTS, ExpectFailedViaTTS);
  RunTTSTest(obj_a2, type_base_i_object_dynamic, tav_null, tav_null,
             ExpectLazilyFailedViaTTS, ExpectFailedViaTTS);
  RunTTSTest(obj_b, type_base_i_object_dynamic, tav_null, tav_null,
             ExpectLazilyFailedViaTTS, ExpectFailedViaTTS);
  RunTTSTest(obj_b1, type_base_i_object_dynamic, tav_null, tav_null,
             ExpectLazilyFailedViaTTS, ExpectFailedViaTTS);
  RunTTSTest(obj_b2, type_base_i_object_dynamic, tav_null, tav_null,
             ExpectLazilyFailedViaTTS, ExpectFailedViaTTS);

  // <...> as Base<T>  with T instantiantiator type parameter (T == int)
  const auto& tav_baset = TypeArguments::Handle(TypeArguments::New(1));
  tav_baset.SetTypeAt(
      0, TypeParameter::Handle(GetClassTypeParameter(class_base, "T")));
  auto& type_base_t = AbstractType::Handle(
      Type::New(class_base, tav_baset, TokenPosition::kNoSource));
  FinalizeAndCanonicalize(&type_base_t);
  RunTTSTest(obj_baseint, type_base_t, tav_int, tav_null,
             ExpectLazilyHandledViaTTS, ExpectHandledViaTTS);
  RunTTSTest(obj_baseistringdouble, type_base_t, tav_int, tav_null,
             ExpectLazilyFailedViaTTS, ExpectFailedViaTTS);

  // <...> as Base<B>  with B function type parameter
  const auto& tav_baseb = TypeArguments::Handle(TypeArguments::New(1));
  tav_baseb.SetTypeAt(
      0, TypeParameter::Handle(GetFunctionTypeParameter(fun_generic, "B")));
  auto& type_base_b = AbstractType::Handle(
      Type::New(class_base, tav_baseb, TokenPosition::kNoSource));
  FinalizeAndCanonicalize(&type_base_b);
  // With B == int
  RunTTSTest(obj_baseint, type_base_b, tav_null, tav_dynamic_int,
             ExpectLazilyHandledViaTTS, ExpectHandledViaTTS);
  RunTTSTest(obj_baseistringdouble, type_base_b, tav_null, tav_dynamic_int,
             ExpectLazilyFailedViaTTS, ExpectFailedViaTTS);
  // With B == dynamic (null vector)
  RunTTSTest(obj_baseint, type_base_b, tav_null, tav_null,
             ExpectLazilyHandledViaTTS, ExpectHandledViaTTS);
  RunTTSTest(obj_i2, type_base_b, tav_null, tav_null, ExpectLazilyFailedViaTTS,
             ExpectFailedViaTTS);

  // We do not generate TTS for uninstantiated types if we would need to use
  // subtype range checks for the class of the interface type.
  //
  //   obj as I<dynamic, String>       // I is generic & implemented.
  //   obj as Base<A2<T>>              // A2<T> is not instantiated.
  //   obj as Base<A2<A1>>             // A2<A1> is not a rare type.
  //

  //   <...> as I<dynamic, String>
  RELEASE_ASSERT(class_i.is_implemented());
  auto& type_i_dynamic_string = Type::Handle(
      Type::New(class_i, tav_dynamic_string, TokenPosition::kNoSource));
  type_i_dynamic_string = type_i_dynamic_string.ToNullability(
      Nullability::kNonNullable, Heap::kNew);
  FinalizeAndCanonicalize(&type_i_dynamic_string);
  RunTTSTest(obj_i, type_i_dynamic_string, tav_null, tav_null,
             ExpectLazilyHandledViaSTC, ExpectHandledViaSTC);
  RunTTSTest(obj_baseint, type_i_dynamic_string, tav_null, tav_null,
             ExpectLazilyFailedViaSTC, ExpectFailedViaSTC);

  //   <...> as Base<A2<T>>
  const auto& tav_t = TypeArguments::Handle(TypeArguments::New(1));
  tav_t.SetTypeAt(
      0, TypeParameter::Handle(GetClassTypeParameter(class_base, "T")));
  auto& type_a2_t =
      Type::Handle(Type::New(class_a2, tav_t, TokenPosition::kNoSource));
  type_a2_t = type_a2_t.ToNullability(Nullability::kLegacy, Heap::kNew);
  FinalizeAndCanonicalize(&type_a2_t);
  const auto& tav_a2_t = TypeArguments::Handle(TypeArguments::New(1));
  tav_a2_t.SetTypeAt(0, type_a2_t);
  auto& type_base_a2_t =
      Type::Handle(Type::New(class_base, tav_a2_t, TokenPosition::kNoSource));
  type_base_a2_t =
      type_base_a2_t.ToNullability(Nullability::kNonNullable, Heap::kNew);
  FinalizeAndCanonicalize(&type_base_a2_t);
  RunTTSTest(obj_basea2int, type_base_a2_t, tav_null, tav_null,
             ExpectLazilyHandledViaSTC, ExpectHandledViaSTC);
  RunTTSTest(obj_baseint, type_base_a2_t, tav_null, tav_null,
             ExpectLazilyFailedViaSTC, ExpectFailedViaSTC);

  //   <...> as Base<A2<A1>>
  const auto& tav_a1 = TypeArguments::Handle(TypeArguments::New(1));
  tav_a1.SetTypeAt(0, type_a1);
  auto& type_a2_a1 =
      Type::Handle(Type::New(class_a2, tav_a1, TokenPosition::kNoSource));
  type_a2_a1 = type_a2_a1.ToNullability(Nullability::kLegacy, Heap::kNew);
  FinalizeAndCanonicalize(&type_a2_a1);
  const auto& tav_a2_a1 = TypeArguments::Handle(TypeArguments::New(1));
  tav_a2_a1.SetTypeAt(0, type_a2_a1);
  auto& type_base_a2_a1 =
      Type::Handle(Type::New(class_base, tav_a2_a1, TokenPosition::kNoSource));
  type_base_a2_a1 =
      type_base_a2_a1.ToNullability(Nullability::kNonNullable, Heap::kNew);
  FinalizeAndCanonicalize(&type_base_a2_a1);
  RunTTSTest(obj_basea2a1, type_base_a2_a1, tav_null, tav_null,
             ExpectLazilyHandledViaSTC, ExpectHandledViaSTC);
  RunTTSTest(obj_basea2int, type_base_a2_a1, tav_null, tav_null,
             ExpectLazilyFailedViaSTC, ExpectFailedViaSTC);
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
                    TypeParameter::Handle(GetClassTypeParameter(class_b, "T")));
  auto& dst_type =
      Type::Handle(Type::New(class_b, dst_tav, TokenPosition::kNoSource));
  FinalizeAndCanonicalize(&dst_type);
  const auto& cint_tav =
      TypeArguments::Handle(Instance::Cast(acint).GetTypeArguments());
  const auto& function_tav = TypeArguments::Handle();

  // a as B<T> -- a==B<C<int>, T==<C<int>>
  RunTTSTest(bcint, dst_type, cint_tav, function_tav, ExpectLazilyHandledViaTTS,
             ExpectHandledViaTTS);

  // a as B<T> -- a==B<C<num>, T==<C<int>>
  RunTTSTest(bcnum, dst_type, cint_tav, function_tav, ExpectLazilyFailedViaTTS,
             ExpectFailedViaTTS);
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
      TypeParameter::Handle(GetClassTypeParameter(class_a, "T"));
  const auto& dst_type_h =
      TypeParameter::Handle(GetFunctionTypeParameter(fun_generic, "H"));

  const auto& aint = Object::Handle(Invoke(root_library, "createAInt"));
  const auto& astring = Object::Handle(Invoke(root_library, "createAString"));

  const auto& int_tav =
      TypeArguments::Handle(Instance::Cast(aint).GetTypeArguments());
  const auto& string_tav =
      TypeArguments::Handle(Instance::Cast(astring).GetTypeArguments());

  const auto& int_instance = Integer::Handle(Integer::New(1));
  const auto& string_instance = String::Handle(String::New("foo"));

  THR_Print("Testing int instance, class parameter instantiated to int\n");
  RunTTSTest(int_instance, dst_type_t, int_tav, string_tav,
             ExpectLazilyHandledViaTTS, ExpectHandledViaTTS);
  THR_Print("\nTesting string instance, class parameter instantiated to int\n");
  RunTTSTest(string_instance, dst_type_t, int_tav, string_tav,
             ExpectLazilyFailedViaTTS, ExpectFailedViaTTS);

  THR_Print(
      "\nTesting string instance, function parameter instantiated to string\n");
  RunTTSTest(string_instance, dst_type_h, int_tav, string_tav,
             ExpectLazilyHandledViaTTS, ExpectHandledViaTTS);
  RunTTSTest(int_instance, dst_type_h, int_tav, string_tav,
             ExpectLazilyFailedViaTTS, ExpectFailedViaTTS);
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM64) ||  defined(TARGET_ARCH_ARM) ||          \
        // defined(TARGET_ARCH_X64)

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM64.
#if defined(TARGET_ARCH_ARM64)

#include "vm/compiler/backend/flow_graph_compiler.h"

#include "vm/compiler/api/type_check_mode.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/deopt_instructions.h"
#include "vm/dispatch_table.h"
#include "vm/instructions.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool, trap_on_deoptimization, false, "Trap on deoptimization.");
DECLARE_FLAG(bool, enable_simd_inline);
DEFINE_FLAG(bool, unbox_mints, true, "Optimize 64-bit integer arithmetic.");

void FlowGraphCompiler::ArchSpecificInitialization() {
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    auto object_store = isolate()->object_store();

    const auto& stub =
        Code::ZoneHandle(object_store->write_barrier_wrappers_stub());
    if (CanPcRelativeCall(stub)) {
      assembler_->generate_invoke_write_barrier_wrapper_ = [&](Register reg) {
        const intptr_t offset_into_target =
            Thread::WriteBarrierWrappersOffsetForRegister(reg);
        assembler_->GenerateUnRelocatedPcRelativeCall(offset_into_target);
        AddPcRelativeCallStubTarget(stub);
      };
    }

    const auto& array_stub =
        Code::ZoneHandle(object_store->array_write_barrier_stub());
    if (CanPcRelativeCall(stub)) {
      assembler_->generate_invoke_array_write_barrier_ = [&]() {
        assembler_->GenerateUnRelocatedPcRelativeCall();
        AddPcRelativeCallStubTarget(array_stub);
      };
    }
  }
}

FlowGraphCompiler::~FlowGraphCompiler() {
  // BlockInfos are zone-allocated, so their destructors are not called.
  // Verify the labels explicitly here.
  for (int i = 0; i < block_info_.length(); ++i) {
    ASSERT(!block_info_[i]->jump_label()->IsLinked());
  }
}

bool FlowGraphCompiler::SupportsUnboxedDoubles() {
  return true;
}

bool FlowGraphCompiler::SupportsUnboxedInt64() {
  return FLAG_unbox_mints;
}

bool FlowGraphCompiler::SupportsUnboxedSimd128() {
  return FLAG_enable_simd_inline;
}

bool FlowGraphCompiler::CanConvertInt64ToDouble() {
  return true;
}

bool FlowGraphCompiler::SupportsHardwareDivision() {
  return true;
}

void FlowGraphCompiler::EnterIntrinsicMode() {
  ASSERT(!intrinsic_mode());
  intrinsic_mode_ = true;
  ASSERT(!assembler()->constant_pool_allowed());
}

void FlowGraphCompiler::ExitIntrinsicMode() {
  ASSERT(intrinsic_mode());
  intrinsic_mode_ = false;
}

TypedDataPtr CompilerDeoptInfo::CreateDeoptInfo(FlowGraphCompiler* compiler,
                                                DeoptInfoBuilder* builder,
                                                const Array& deopt_table) {
  if (deopt_env_ == NULL) {
    ++builder->current_info_number_;
    return TypedData::null();
  }

  intptr_t stack_height = compiler->StackSize();
  AllocateIncomingParametersRecursive(deopt_env_, &stack_height);

  intptr_t slot_ix = 0;
  Environment* current = deopt_env_;

  // Emit all kMaterializeObject instructions describing objects to be
  // materialized on the deoptimization as a prefix to the deoptimization info.
  EmitMaterializations(deopt_env_, builder);

  // The real frame starts here.
  builder->MarkFrameStart();

  Zone* zone = compiler->zone();

  builder->AddPp(current->function(), slot_ix++);
  builder->AddPcMarker(Function::ZoneHandle(zone), slot_ix++);
  builder->AddCallerFp(slot_ix++);
  builder->AddReturnAddress(current->function(), deopt_id(), slot_ix++);

  // Emit all values that are needed for materialization as a part of the
  // expression stack for the bottom-most frame. This guarantees that GC
  // will be able to find them during materialization.
  slot_ix = builder->EmitMaterializationArguments(slot_ix);

  // For the innermost environment, set outgoing arguments and the locals.
  for (intptr_t i = current->Length() - 1;
       i >= current->fixed_parameter_count(); i--) {
    builder->AddCopy(current->ValueAt(i), current->LocationAt(i), slot_ix++);
  }

  Environment* previous = current;
  current = current->outer();
  while (current != NULL) {
    builder->AddPp(current->function(), slot_ix++);
    builder->AddPcMarker(previous->function(), slot_ix++);
    builder->AddCallerFp(slot_ix++);

    // For any outer environment the deopt id is that of the call instruction
    // which is recorded in the outer environment.
    builder->AddReturnAddress(current->function(),
                              DeoptId::ToDeoptAfter(current->deopt_id()),
                              slot_ix++);

    // The values of outgoing arguments can be changed from the inlined call so
    // we must read them from the previous environment.
    for (intptr_t i = previous->fixed_parameter_count() - 1; i >= 0; i--) {
      builder->AddCopy(previous->ValueAt(i), previous->LocationAt(i),
                       slot_ix++);
    }

    // Set the locals, note that outgoing arguments are not in the environment.
    for (intptr_t i = current->Length() - 1;
         i >= current->fixed_parameter_count(); i--) {
      builder->AddCopy(current->ValueAt(i), current->LocationAt(i), slot_ix++);
    }

    // Iterate on the outer environment.
    previous = current;
    current = current->outer();
  }
  // The previous pointer is now the outermost environment.
  ASSERT(previous != NULL);

  // Add slots for the outermost environment.
  builder->AddCallerPp(slot_ix++);
  builder->AddPcMarker(previous->function(), slot_ix++);
  builder->AddCallerFp(slot_ix++);
  builder->AddCallerPc(slot_ix++);

  // For the outermost environment, set the incoming arguments.
  for (intptr_t i = previous->fixed_parameter_count() - 1; i >= 0; i--) {
    builder->AddCopy(previous->ValueAt(i), previous->LocationAt(i), slot_ix++);
  }

  return builder->CreateDeoptInfo(deopt_table);
}

void CompilerDeoptInfoWithStub::GenerateCode(FlowGraphCompiler* compiler,
                                             intptr_t stub_ix) {
  // Calls do not need stubs, they share a deoptimization trampoline.
  ASSERT(reason() != ICData::kDeoptAtCall);
  compiler::Assembler* assembler = compiler->assembler();
#define __ assembler->
  __ Comment("%s", Name());
  __ Bind(entry_label());
  if (FLAG_trap_on_deoptimization) {
    __ brk(0);
  }

  ASSERT(deopt_env() != NULL);
  __ ldr(LR, compiler::Address(THR, Thread::deoptimize_entry_offset()));
  __ blr(LR);
  set_pc_offset(assembler->CodeSize());
#undef __
}

#define __ assembler()->

// Fall through if bool_register contains null.
void FlowGraphCompiler::GenerateBoolToJump(Register bool_register,
                                           compiler::Label* is_true,
                                           compiler::Label* is_false) {
  compiler::Label fall_through;
  __ CompareObject(bool_register, Object::null_object());
  __ b(&fall_through, EQ);
  BranchLabels labels = {is_true, is_false, &fall_through};
  Condition true_condition =
      EmitBoolTest(bool_register, labels, /*invert=*/false);
  ASSERT(true_condition == kInvalidCondition);
  __ Bind(&fall_through);
}

// R0: instance (must be preserved).
// R2: instantiator type arguments (if used).
// R1: function type arguments (if used).
SubtypeTestCachePtr FlowGraphCompiler::GenerateCallSubtypeTestStub(
    TypeTestStubKind test_kind,
    Register instance_reg,
    Register instantiator_type_arguments_reg,
    Register function_type_arguments_reg,
    Register temp_reg,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  ASSERT(instance_reg == R0);
  ASSERT(temp_reg == kNoRegister);  // Unused on ARM64.
  const SubtypeTestCache& type_test_cache =
      SubtypeTestCache::ZoneHandle(zone(), SubtypeTestCache::New());
  __ LoadUniqueObject(R3, type_test_cache);
  if (test_kind == kTestTypeOneArg) {
    ASSERT(instantiator_type_arguments_reg == kNoRegister);
    ASSERT(function_type_arguments_reg == kNoRegister);
    __ BranchLink(StubCode::Subtype1TestCache());
  } else if (test_kind == kTestTypeTwoArgs) {
    ASSERT(instantiator_type_arguments_reg == kNoRegister);
    ASSERT(function_type_arguments_reg == kNoRegister);
    __ BranchLink(StubCode::Subtype2TestCache());
  } else if (test_kind == kTestTypeFourArgs) {
    ASSERT(instantiator_type_arguments_reg ==
           TypeTestABI::kInstantiatorTypeArgumentsReg);
    ASSERT(function_type_arguments_reg ==
           TypeTestABI::kFunctionTypeArgumentsReg);
    __ BranchLink(StubCode::Subtype4TestCache());
  } else if (test_kind == kTestTypeSixArgs) {
    ASSERT(instantiator_type_arguments_reg ==
           TypeTestABI::kInstantiatorTypeArgumentsReg);
    ASSERT(function_type_arguments_reg ==
           TypeTestABI::kFunctionTypeArgumentsReg);
    __ BranchLink(StubCode::Subtype6TestCache());
  } else {
    UNREACHABLE();
  }
  // Result is in R1: null -> not found, otherwise Bool::True or Bool::False.
  GenerateBoolToJump(R1, is_instance_lbl, is_not_instance_lbl);
  return type_test_cache.raw();
}

// Jumps to labels 'is_instance' or 'is_not_instance' respectively, if
// type test is conclusive, otherwise fallthrough if a type test could not
// be completed.
// R0: instance being type checked (preserved).
// Clobbers R1, R2.
SubtypeTestCachePtr
FlowGraphCompiler::GenerateInstantiatedTypeWithArgumentsTest(
    TokenPosition token_pos,
    const AbstractType& type,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  __ Comment("InstantiatedTypeWithArgumentsTest");
  ASSERT(type.IsInstantiated());
  ASSERT(!type.IsFunctionType());
  const Class& type_class = Class::ZoneHandle(zone(), type.type_class());
  ASSERT(type_class.NumTypeArguments() > 0);
  const Type& smi_type = Type::Handle(zone(), Type::SmiType());
  const bool smi_is_ok = smi_type.IsSubtypeOf(type, Heap::kOld);
  // Fast case for type = FutureOr<int/num/top-type>.
  __ BranchIfSmi(TypeTestABI::kInstanceReg,
                 smi_is_ok ? is_instance_lbl : is_not_instance_lbl);

  const intptr_t num_type_args = type_class.NumTypeArguments();
  const intptr_t num_type_params = type_class.NumTypeParameters();
  const intptr_t from_index = num_type_args - num_type_params;
  const TypeArguments& type_arguments =
      TypeArguments::ZoneHandle(zone(), type.arguments());
  const bool is_raw_type = type_arguments.IsNull() ||
                           type_arguments.IsRaw(from_index, num_type_params);
  if (is_raw_type) {
    const Register kClassIdReg = R2;
    // dynamic type argument, check only classes.
    __ LoadClassId(kClassIdReg, TypeTestABI::kInstanceReg);
    __ CompareImmediate(kClassIdReg, type_class.id());
    __ b(is_instance_lbl, EQ);
    // List is a very common case.
    if (IsListClass(type_class)) {
      GenerateListTypeCheck(kClassIdReg, is_instance_lbl);
    }
    return GenerateSubtype1TestCacheLookup(
        token_pos, type_class, is_instance_lbl, is_not_instance_lbl);
  }
  // If one type argument only, check if type argument is a top type.
  if (type_arguments.Length() == 1) {
    const AbstractType& tp_argument =
        AbstractType::ZoneHandle(zone(), type_arguments.TypeAt(0));
    if (tp_argument.IsTopTypeForSubtyping()) {
      // Instance class test only necessary.
      return GenerateSubtype1TestCacheLookup(
          token_pos, type_class, is_instance_lbl, is_not_instance_lbl);
    }
  }
  // Regular subtype test cache involving instance's type arguments.
  const Register kInstantiatorTypeArgumentsReg = kNoRegister;
  const Register kFunctionTypeArgumentsReg = kNoRegister;
  const Register kTempReg = kNoRegister;
  // R0: instance (must be preserved).
  return GenerateCallSubtypeTestStub(
      kTestTypeTwoArgs, TypeTestABI::kInstanceReg,
      kInstantiatorTypeArgumentsReg, kFunctionTypeArgumentsReg, kTempReg,
      is_instance_lbl, is_not_instance_lbl);
}

void FlowGraphCompiler::CheckClassIds(Register class_id_reg,
                                      const GrowableArray<intptr_t>& class_ids,
                                      compiler::Label* is_equal_lbl,
                                      compiler::Label* is_not_equal_lbl) {
  for (intptr_t i = 0; i < class_ids.length(); i++) {
    __ CompareImmediate(class_id_reg, class_ids[i]);
    __ b(is_equal_lbl, EQ);
  }
  __ b(is_not_equal_lbl);
}

// Testing against an instantiated type with no arguments, without
// SubtypeTestCache.
// R0: instance being type checked (preserved).
// Clobbers R2, R3.
// Returns true if there is a fallthrough.
bool FlowGraphCompiler::GenerateInstantiatedTypeNoArgumentsTest(
    TokenPosition token_pos,
    const AbstractType& type,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  __ Comment("InstantiatedTypeNoArgumentsTest");
  ASSERT(type.IsInstantiated());
  ASSERT(!type.IsFunctionType());
  const Class& type_class = Class::Handle(zone(), type.type_class());
  ASSERT(type_class.NumTypeArguments() == 0);

  // If instance is Smi, check directly.
  const Class& smi_class = Class::Handle(zone(), Smi::Class());
  if (Class::IsSubtypeOf(smi_class, Object::null_type_arguments(),
                         Nullability::kNonNullable, type, Heap::kOld)) {
    // Fast case for type = int/num/top-type.
    __ BranchIfSmi(TypeTestABI::kInstanceReg, is_instance_lbl);
  } else {
    __ BranchIfSmi(TypeTestABI::kInstanceReg, is_not_instance_lbl);
  }
  const Register kClassIdReg = R2;
  __ LoadClassId(kClassIdReg, TypeTestABI::kInstanceReg);
  // Bool interface can be implemented only by core class Bool.
  if (type.IsBoolType()) {
    __ CompareImmediate(kClassIdReg, kBoolCid);
    __ b(is_instance_lbl, EQ);
    __ b(is_not_instance_lbl);
    return false;
  }
  // Custom checking for numbers (Smi, Mint and Double).
  // Note that instance is not Smi (checked above).
  if (type.IsNumberType() || type.IsIntType() || type.IsDoubleType()) {
    GenerateNumberTypeCheck(kClassIdReg, type, is_instance_lbl,
                            is_not_instance_lbl);
    return false;
  }
  if (type.IsStringType()) {
    GenerateStringTypeCheck(kClassIdReg, is_instance_lbl, is_not_instance_lbl);
    return false;
  }
  if (type.IsDartFunctionType()) {
    // Check if instance is a closure.
    __ CompareImmediate(kClassIdReg, kClosureCid);
    __ b(is_instance_lbl, EQ);
    return true;  // Fall through
  }

  // Fast case for cid-range based checks.
  // Warning: This code destroys the contents of [kClassIdReg].
  if (GenerateSubtypeRangeCheck(kClassIdReg, type_class, is_instance_lbl)) {
    return false;
  }

  // Otherwise fallthrough, result non-conclusive.
  return true;
}

// Uses SubtypeTestCache to store instance class and result.
// R0: instance to test.
// Clobbers R1-R5.
// Immediate class test already done.
// TODO(srdjan): Implement a quicker subtype check, as type test
// arrays can grow too high, but they may be useful when optimizing
// code (type-feedback).
SubtypeTestCachePtr FlowGraphCompiler::GenerateSubtype1TestCacheLookup(
    TokenPosition token_pos,
    const Class& type_class,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  __ Comment("Subtype1TestCacheLookup");
#if defined(DEBUG)
  compiler::Label ok;
  __ BranchIfNotSmi(TypeTestABI::kInstanceReg, &ok);
  __ Breakpoint();
  __ Bind(&ok);
#endif
  __ LoadClassId(TMP, TypeTestABI::kInstanceReg);
  __ LoadClassById(R1, TMP);
  // R1: instance class.
  // Check immediate superclass equality. If type_class is Object, then testing
  // supertype may yield a wrong result for Null in NNBD strong mode (because
  // Null also extends Object).
  if (!type_class.IsObjectClass() || !Isolate::Current()->null_safety()) {
    __ LoadFieldFromOffset(R2, R1, Class::super_type_offset());
    __ LoadFieldFromOffset(R2, R2, Type::type_class_id_offset());
    __ CompareImmediate(R2, Smi::RawValue(type_class.id()));
    __ b(is_instance_lbl, EQ);
  }

  const Register kInstantiatorTypeArgumentsReg = kNoRegister;
  const Register kFunctionTypeArgumentsReg = kNoRegister;
  const Register kTempReg = kNoRegister;
  return GenerateCallSubtypeTestStub(kTestTypeOneArg, TypeTestABI::kInstanceReg,
                                     kInstantiatorTypeArgumentsReg,
                                     kFunctionTypeArgumentsReg, kTempReg,
                                     is_instance_lbl, is_not_instance_lbl);
}

// Generates inlined check if 'type' is a type parameter or type itself
// R0: instance (preserved).
SubtypeTestCachePtr FlowGraphCompiler::GenerateUninstantiatedTypeTest(
    TokenPosition token_pos,
    const AbstractType& type,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  __ Comment("UninstantiatedTypeTest");
  const Register kTempReg = kNoRegister;
  ASSERT(!type.IsInstantiated());
  ASSERT(!type.IsFunctionType());
  // Skip check if destination is a dynamic type.
  if (type.IsTypeParameter()) {
    const TypeParameter& type_param = TypeParameter::Cast(type);

    // Get instantiator type args (high) and function type args (low).
    __ ldp(TypeTestABI::kFunctionTypeArgumentsReg,
           TypeTestABI::kInstantiatorTypeArgumentsReg,
           compiler::Address(SP, 0 * kWordSize, compiler::Address::PairOffset));
    const Register kTypeArgumentsReg =
        type_param.IsClassTypeParameter()
            ? TypeTestABI::kInstantiatorTypeArgumentsReg
            : TypeTestABI::kFunctionTypeArgumentsReg;
    // Check if type arguments are null, i.e. equivalent to vector of dynamic.
    __ CompareObject(kTypeArgumentsReg, Object::null_object());
    __ b(is_instance_lbl, EQ);
    __ LoadFieldFromOffset(R3, kTypeArgumentsReg,
                           TypeArguments::type_at_offset(type_param.index()));
    // R3: concrete type of type.
    // Check if type argument is dynamic, Object?, or void.
    __ CompareObject(R3, Object::dynamic_type());
    __ b(is_instance_lbl, EQ);
    __ CompareObject(
        R3, Type::ZoneHandle(
                zone(), isolate()->object_store()->nullable_object_type()));
    __ b(is_instance_lbl, EQ);
    __ CompareObject(R3, Object::void_type());
    __ b(is_instance_lbl, EQ);

    // For Smi check quickly against int and num interfaces.
    compiler::Label not_smi;
    __ BranchIfNotSmi(R0, &not_smi);
    __ CompareObject(R3, Type::ZoneHandle(zone(), Type::IntType()));
    __ b(is_instance_lbl, EQ);
    __ CompareObject(R3, Type::ZoneHandle(zone(), Type::Number()));
    __ b(is_instance_lbl, EQ);
    // Smi can be handled by type test cache.
    __ Bind(&not_smi);

    const auto test_kind = GetTypeTestStubKindForTypeParameter(type_param);
    const SubtypeTestCache& type_test_cache = SubtypeTestCache::ZoneHandle(
        zone(), GenerateCallSubtypeTestStub(
                    test_kind, TypeTestABI::kInstanceReg,
                    TypeTestABI::kInstantiatorTypeArgumentsReg,
                    TypeTestABI::kFunctionTypeArgumentsReg, kTempReg,
                    is_instance_lbl, is_not_instance_lbl));
    return type_test_cache.raw();
  }
  if (type.IsType()) {
    // Smi is FutureOr<T>, when T is a top type or int or num.
    if (!type.IsFutureOrType()) {
      __ BranchIfSmi(TypeTestABI::kInstanceReg, is_not_instance_lbl);
    }
    __ ldp(TypeTestABI::kFunctionTypeArgumentsReg,
           TypeTestABI::kInstantiatorTypeArgumentsReg,
           compiler::Address(SP, 0 * kWordSize, compiler::Address::PairOffset));
    // Uninstantiated type class is known at compile time, but the type
    // arguments are determined at runtime by the instantiator.
    return GenerateCallSubtypeTestStub(
        kTestTypeFourArgs, TypeTestABI::kInstanceReg,
        TypeTestABI::kInstantiatorTypeArgumentsReg,
        TypeTestABI::kFunctionTypeArgumentsReg, kTempReg, is_instance_lbl,
        is_not_instance_lbl);
  }
  return SubtypeTestCache::null();
}

// Generates function type check.
//
// See [GenerateUninstantiatedTypeTest] for calling convention.
SubtypeTestCachePtr FlowGraphCompiler::GenerateFunctionTypeTest(
    TokenPosition token_pos,
    const AbstractType& type,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  __ BranchIfSmi(TypeTestABI::kInstanceReg, is_not_instance_lbl);
  __ ldp(TypeTestABI::kFunctionTypeArgumentsReg,
         TypeTestABI::kInstantiatorTypeArgumentsReg,
         compiler::Address(SP, 0 * kWordSize, compiler::Address::PairOffset));
  // Uninstantiated type class is known at compile time, but the type
  // arguments are determined at runtime by the instantiator(s).
  const Register kTempReg = kNoRegister;
  return GenerateCallSubtypeTestStub(
      kTestTypeSixArgs, TypeTestABI::kInstanceReg,
      TypeTestABI::kInstantiatorTypeArgumentsReg,
      TypeTestABI::kFunctionTypeArgumentsReg, kTempReg, is_instance_lbl,
      is_not_instance_lbl);
}

// Inputs:
// - R0: instance being type checked (preserved).
// - R2: optional instantiator type arguments (preserved).
// - R1: optional function type arguments (preserved).
// Clobbers R3, R4, R8, R9.
// Returns:
// - preserved instance in R0, optional instantiator type arguments in R2, and
//   optional function type arguments in R1.
// Note that this inlined code must be followed by the runtime_call code, as it
// may fall through to it. Otherwise, this inline code will jump to the label
// is_instance or to the label is_not_instance.
SubtypeTestCachePtr FlowGraphCompiler::GenerateInlineInstanceof(
    TokenPosition token_pos,
    const AbstractType& type,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  __ Comment("InlineInstanceof");

  if (type.IsFunctionType()) {
    return GenerateFunctionTypeTest(token_pos, type, is_instance_lbl,
                                    is_not_instance_lbl);
  }

  if (type.IsInstantiated()) {
    const Class& type_class = Class::ZoneHandle(zone(), type.type_class());
    // A class equality check is only applicable with a dst type (not a
    // function type) of a non-parameterized class or with a raw dst type of
    // a parameterized class.
    if (type_class.NumTypeArguments() > 0) {
      return GenerateInstantiatedTypeWithArgumentsTest(
          token_pos, type, is_instance_lbl, is_not_instance_lbl);
      // Fall through to runtime call.
    }
    const bool has_fall_through = GenerateInstantiatedTypeNoArgumentsTest(
        token_pos, type, is_instance_lbl, is_not_instance_lbl);
    if (has_fall_through) {
      // If test non-conclusive so far, try the inlined type-test cache.
      // 'type' is known at compile time.
      return GenerateSubtype1TestCacheLookup(
          token_pos, type_class, is_instance_lbl, is_not_instance_lbl);
    } else {
      return SubtypeTestCache::null();
    }
  }
  return GenerateUninstantiatedTypeTest(token_pos, type, is_instance_lbl,
                                        is_not_instance_lbl);
}

// If instanceof type test cannot be performed successfully at compile time and
// therefore eliminated, optimize it by adding inlined tests for:
// - Null -> see comment below.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs:
// - R0: object.
// - R2: instantiator type arguments or raw_null.
// - R1: function type arguments or raw_null.
// Returns:
// - true or false in R0.
void FlowGraphCompiler::GenerateInstanceOf(TokenPosition token_pos,
                                           intptr_t deopt_id,
                                           const AbstractType& type,
                                           LocationSummary* locs) {
  ASSERT(type.IsFinalized());
  ASSERT(!type.IsTopTypeForInstanceOf());  // Already checked.
  __ PushPair(TypeTestABI::kFunctionTypeArgumentsReg,
              TypeTestABI::kInstantiatorTypeArgumentsReg);

  compiler::Label is_instance, is_not_instance;
  // 'null' is an instance of Null, Object*, Never*, void, and dynamic.
  // In addition, 'null' is an instance of any nullable type.
  // It is also an instance of FutureOr<T> if it is an instance of T.
  const AbstractType& unwrapped_type =
      AbstractType::Handle(type.UnwrapFutureOr());
  if (!unwrapped_type.IsTypeParameter() || unwrapped_type.IsNullable()) {
    // Only nullable type parameter remains nullable after instantiation.
    // See NullIsInstanceOf().
    __ CompareObject(TypeTestABI::kInstanceReg, Object::null_object());
    __ b((unwrapped_type.IsNullable() ||
          (unwrapped_type.IsLegacy() && unwrapped_type.IsNeverType()))
             ? &is_instance
             : &is_not_instance,
         EQ);
  }

  // Generate inline instanceof test.
  SubtypeTestCache& test_cache = SubtypeTestCache::ZoneHandle(zone());
  test_cache =
      GenerateInlineInstanceof(token_pos, type, &is_instance, &is_not_instance);

  // test_cache is null if there is no fall-through.
  compiler::Label done;
  if (!test_cache.IsNull()) {
    // Generate runtime call.
    __ ldp(TypeTestABI::kFunctionTypeArgumentsReg,
           TypeTestABI::kInstantiatorTypeArgumentsReg,
           compiler::Address(SP, 0 * kWordSize, compiler::Address::PairOffset));
    __ LoadUniqueObject(TypeTestABI::kDstTypeReg, type);
    __ LoadUniqueObject(TypeTestABI::kSubtypeTestCacheReg, test_cache);
    GenerateStubCall(token_pos, StubCode::InstanceOf(),
                     /*kind=*/PcDescriptorsLayout::kOther, locs, deopt_id);
    __ b(&done);
  }
  __ Bind(&is_not_instance);
  __ LoadObject(R0, Bool::Get(false));
  __ b(&done);

  __ Bind(&is_instance);
  __ LoadObject(R0, Bool::Get(true));
  __ Bind(&done);
  // Remove instantiator type arguments and function type arguments.
  __ Drop(2);
}

// Optimize assignable type check by adding inlined tests for:
// - NULL -> return NULL.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs:
// - R0: instance being type checked.
// - R8: destination type (if non-constant).
// - R2: instantiator type arguments or raw_null.
// - R1: function type arguments or raw_null.
// Returns:
// - object in R0 for successful assignable check (or throws TypeError).
// Performance notes: positive checks must be quick, negative checks can be slow
// as they throw an exception.
void FlowGraphCompiler::GenerateAssertAssignable(CompileType* receiver_type,
                                                 TokenPosition token_pos,
                                                 intptr_t deopt_id,
                                                 const String& dst_name,
                                                 LocationSummary* locs) {
  ASSERT(!TokenPosition(token_pos).IsClassifying());
  ASSERT(CheckAssertAssignableTypeTestingABILocations(*locs));

  if (locs->in(1).IsConstant()) {
    const auto& dst_type = AbstractType::Cast(locs->in(1).constant());
    ASSERT(dst_type.IsFinalized());

    if (dst_type.IsTopTypeForSubtyping()) return;  // No code needed.

    GenerateAssertAssignableViaTypeTestingStub(receiver_type, token_pos,
                                               deopt_id, dst_name, locs);
    return;
  } else {
    // TODO(dartbug.com/40813): Handle setting up the non-constant case.
    UNREACHABLE();
  }
}

void FlowGraphCompiler::GenerateAssertAssignableViaTypeTestingStub(
    CompileType* receiver_type,
    TokenPosition token_pos,
    intptr_t deopt_id,
    const String& dst_name,
    LocationSummary* locs) {
  ASSERT(CheckAssertAssignableTypeTestingABILocations(*locs));
  // We must have a constant dst_type for generating a call to the stub.
  ASSERT(locs->in(1).IsConstant());
  const auto& dst_type = AbstractType::Cast(locs->in(1).constant());

  // If the dst_type is instantiated we know the target TTS stub at
  // compile-time and can therefore use a pc-relative call.
  const bool use_pc_relative_call =
      dst_type.IsInstantiated() && CanPcRelativeCall(dst_type);

  const Register kRegToCall =
      use_pc_relative_call
          ? kNoRegister
          : (dst_type.IsTypeParameter() ? R9 : TypeTestABI::kDstTypeReg);
  const Register kScratchReg = R4;

  compiler::Label done;

  GenerateAssertAssignableViaTypeTestingStub(receiver_type, dst_type, dst_name,
                                             kRegToCall, kScratchReg, &done);

  // We use 2 consecutive entries in the pool for the subtype cache and the
  // destination name.  The second entry, namely [dst_name] seems to be unused,
  // but it will be used by the code throwing a TypeError if the type test fails
  // (see runtime/vm/runtime_entry.cc:TypeCheck).  It will use pattern matching
  // on the call site to find out at which pool index the destination name is
  // located.
  const intptr_t sub_type_cache_index = __ object_pool_builder().AddObject(
      Object::null_object(), ObjectPool::Patchability::kPatchable);
  const intptr_t sub_type_cache_offset =
      ObjectPool::element_offset(sub_type_cache_index);
  const intptr_t dst_name_index = __ object_pool_builder().AddObject(
      dst_name, ObjectPool::Patchability::kPatchable);
  ASSERT((sub_type_cache_index + 1) == dst_name_index);
  ASSERT(__ constant_pool_allowed());

  if (use_pc_relative_call) {
    __ LoadWordFromPoolOffset(TypeTestABI::kSubtypeTestCacheReg,
                              sub_type_cache_offset);
    __ GenerateUnRelocatedPcRelativeCall();
    AddPcRelativeTTSCallTypeTarget(dst_type);
  } else {
    __ LoadField(
        R9, compiler::FieldAddress(
                kRegToCall, AbstractType::type_test_stub_entry_point_offset()));
    __ LoadWordFromPoolOffset(TypeTestABI::kSubtypeTestCacheReg,
                              sub_type_cache_offset);
    __ blr(R9);
  }
  EmitCallsiteMetadata(token_pos, deopt_id, PcDescriptorsLayout::kOther, locs);
  __ Bind(&done);
}

void FlowGraphCompiler::EmitInstructionEpilogue(Instruction* instr) {
  if (is_optimizing()) {
    return;
  }
  Definition* defn = instr->AsDefinition();
  if ((defn != NULL) && defn->HasTemp()) {
    __ Push(defn->locs()->out(0).reg());
  }
}

void FlowGraphCompiler::GenerateMethodExtractorIntrinsic(
    const Function& extracted_method,
    intptr_t type_arguments_field_offset) {
  // No frame has been setup here.
  ASSERT(!__ constant_pool_allowed());
  ASSERT(extracted_method.IsZoneHandle());

  const Code& build_method_extractor = Code::ZoneHandle(
      isolate()->object_store()->build_method_extractor_code());

  const intptr_t stub_index = __ object_pool_builder().AddObject(
      build_method_extractor, ObjectPool::Patchability::kNotPatchable);
  const intptr_t function_index = __ object_pool_builder().AddObject(
      extracted_method, ObjectPool::Patchability::kNotPatchable);

  // We use a custom pool register to preserve caller PP.
  Register kPoolReg = R0;

  // R1 = extracted function
  // R4 = offset of type argument vector (or 0 if class is not generic)
  intptr_t pp_offset = 0;
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    // PP is not tagged on arm64.
    kPoolReg = PP;
    pp_offset = kHeapObjectTag;
  } else {
    __ LoadFieldFromOffset(kPoolReg, CODE_REG, Code::object_pool_offset());
  }
  __ LoadImmediate(R4, type_arguments_field_offset);
  __ LoadFieldFromOffset(
      R1, kPoolReg, ObjectPool::element_offset(function_index) + pp_offset);
  __ LoadFieldFromOffset(CODE_REG, kPoolReg,
                         ObjectPool::element_offset(stub_index) + pp_offset);
  __ LoadFieldFromOffset(R0, CODE_REG,
                         Code::entry_point_offset(Code::EntryKind::kUnchecked));
  __ br(R0);
}

void FlowGraphCompiler::EmitFrameEntry() {
  const Function& function = parsed_function().function();
  if (CanOptimizeFunction() && function.IsOptimizable() &&
      (!is_optimizing() || may_reoptimize())) {
    __ Comment("Invocation Count Check");
    const Register function_reg = R6;
    __ ldr(function_reg,
           compiler::FieldAddress(CODE_REG, Code::owner_offset()));

    __ LoadFieldFromOffset(R7, function_reg, Function::usage_counter_offset(),
                           kWord);
    // Reoptimization of an optimized function is triggered by counting in
    // IC stubs, but not at the entry of the function.
    if (!is_optimizing()) {
      __ add(R7, R7, compiler::Operand(1));
      __ StoreFieldToOffset(R7, function_reg, Function::usage_counter_offset(),
                            kWord);
    }
    __ CompareImmediate(R7, GetOptimizationThreshold());
    ASSERT(function_reg == R6);
    compiler::Label dont_optimize;
    __ b(&dont_optimize, LT);
    __ ldr(TMP, compiler::Address(THR, Thread::optimize_entry_offset()));
    __ br(TMP);
    __ Bind(&dont_optimize);
  }
  __ Comment("Enter frame");
  if (flow_graph().IsCompiledForOsr()) {
    const intptr_t extra_slots = ExtraStackSlotsOnOsrEntry();
    ASSERT(extra_slots >= 0);
    __ EnterOsrFrame(extra_slots * kWordSize);
  } else {
    ASSERT(StackSize() >= 0);
    __ EnterDartFrame(StackSize() * kWordSize);
  }
}

void FlowGraphCompiler::EmitPrologue() {
  EmitFrameEntry();
  ASSERT(assembler()->constant_pool_allowed());

  // In unoptimized code, initialize (non-argument) stack allocated slots.
  if (!is_optimizing()) {
    const int num_locals = parsed_function().num_stack_locals();

    intptr_t args_desc_slot = -1;
    if (parsed_function().has_arg_desc_var()) {
      args_desc_slot = compiler::target::frame_layout.FrameSlotForVariable(
          parsed_function().arg_desc_var());
    }

    __ Comment("Initialize spill slots");
    if (num_locals > 1 || (num_locals == 1 && args_desc_slot == -1)) {
      __ LoadObject(R0, Object::null_object());
    }
    for (intptr_t i = 0; i < num_locals; ++i) {
      const intptr_t slot_index =
          compiler::target::frame_layout.FrameSlotForVariableIndex(-i);
      Register value_reg = slot_index == args_desc_slot ? ARGS_DESC_REG : R0;
      __ StoreToOffset(value_reg, FP, slot_index * kWordSize);
    }
  }

  EndCodeSourceRange(TokenPosition::kDartCodePrologue);
}

// Input parameters:
//   LR: return address.
//   SP: address of last argument.
//   FP: caller's frame pointer.
//   PP: caller's pool pointer.
//   R4: arguments descriptor array.
void FlowGraphCompiler::CompileGraph() {
  InitCompiler();

  // For JIT we have multiple entrypoints functionality which moved the frame
  // setup into the [TargetEntryInstr] (which will set the constant pool
  // allowed bit to true).  Despite this we still have to set the
  // constant pool allowed bit to true here as well, because we can generate
  // code for [CatchEntryInstr]s, which need the pool.
  __ set_constant_pool_allowed(true);

  VisitBlocks();

#if defined(DEBUG)
  __ brk(0);
#endif

  if (!skip_body_compilation()) {
    ASSERT(assembler()->constant_pool_allowed());
    GenerateDeferredCode();
  }

  for (intptr_t i = 0; i < indirect_gotos_.length(); ++i) {
    indirect_gotos_[i]->ComputeOffsetTable(this);
  }
}

void FlowGraphCompiler::EmitCallToStub(const Code& stub) {
  ASSERT(!stub.IsNull());
  if (CanPcRelativeCall(stub)) {
    __ GenerateUnRelocatedPcRelativeCall();
    AddPcRelativeCallStubTarget(stub);
  } else {
    __ BranchLink(stub);
    AddStubCallTarget(stub);
  }
}

void FlowGraphCompiler::EmitTailCallToStub(const Code& stub) {
  ASSERT(!stub.IsNull());
  if (CanPcRelativeCall(stub)) {
    __ LeaveDartFrame();
    __ GenerateUnRelocatedPcRelativeTailCall();
    AddPcRelativeTailCallStubTarget(stub);
#if defined(DEBUG)
    __ Breakpoint();
#endif
  } else {
    __ LoadObject(CODE_REG, stub);
    __ LeaveDartFrame();
    __ ldr(TMP, compiler::FieldAddress(
                    CODE_REG, compiler::target::Code::entry_point_offset()));
    __ br(TMP);
    AddStubCallTarget(stub);
  }
}

void FlowGraphCompiler::GeneratePatchableCall(TokenPosition token_pos,
                                              const Code& stub,
                                              PcDescriptorsLayout::Kind kind,
                                              LocationSummary* locs) {
  __ BranchLinkPatchable(stub);
  EmitCallsiteMetadata(token_pos, DeoptId::kNone, kind, locs);
}

void FlowGraphCompiler::GenerateDartCall(intptr_t deopt_id,
                                         TokenPosition token_pos,
                                         const Code& stub,
                                         PcDescriptorsLayout::Kind kind,
                                         LocationSummary* locs,
                                         Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  __ BranchLinkPatchable(stub, entry_kind);
  EmitCallsiteMetadata(token_pos, deopt_id, kind, locs);
}

void FlowGraphCompiler::GenerateStaticDartCall(intptr_t deopt_id,
                                               TokenPosition token_pos,
                                               PcDescriptorsLayout::Kind kind,
                                               LocationSummary* locs,
                                               const Function& target,
                                               Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  if (CanPcRelativeCall(target)) {
    __ GenerateUnRelocatedPcRelativeCall();
    AddPcRelativeCallTarget(target, entry_kind);
    EmitCallsiteMetadata(token_pos, deopt_id, kind, locs);
  } else {
    // Call sites to the same target can share object pool entries. These
    // call sites are never patched for breakpoints: the function is deoptimized
    // and the unoptimized code with IC calls for static calls is patched
    // instead.
    ASSERT(is_optimizing());
    const auto& stub = StubCode::CallStaticFunction();
    __ BranchLinkWithEquivalence(stub, target, entry_kind);
    EmitCallsiteMetadata(token_pos, deopt_id, kind, locs);
    AddStaticCallTarget(target, entry_kind);
  }
}

void FlowGraphCompiler::GenerateRuntimeCall(TokenPosition token_pos,
                                            intptr_t deopt_id,
                                            const RuntimeEntry& entry,
                                            intptr_t argument_count,
                                            LocationSummary* locs) {
  __ CallRuntime(entry, argument_count);
  EmitCallsiteMetadata(token_pos, deopt_id, PcDescriptorsLayout::kOther, locs);
}

void FlowGraphCompiler::EmitEdgeCounter(intptr_t edge_id) {
  // We do not check for overflow when incrementing the edge counter.  The
  // function should normally be optimized long before the counter can
  // overflow; and though we do not reset the counters when we optimize or
  // deoptimize, there is a bound on the number of
  // optimization/deoptimization cycles we will attempt.
  ASSERT(!edge_counters_array_.IsNull());
  ASSERT(assembler_->constant_pool_allowed());
  __ Comment("Edge counter");
  __ LoadObject(R0, edge_counters_array_);
  __ LoadFieldFromOffset(TMP, R0, Array::element_offset(edge_id));
  __ add(TMP, TMP, compiler::Operand(Smi::RawValue(1)));
  __ StoreFieldToOffset(TMP, R0, Array::element_offset(edge_id));
}

void FlowGraphCompiler::EmitOptimizedInstanceCall(const Code& stub,
                                                  const ICData& ic_data,
                                                  intptr_t deopt_id,
                                                  TokenPosition token_pos,
                                                  LocationSummary* locs,
                                                  Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  ASSERT(Array::Handle(zone(), ic_data.arguments_descriptor()).Length() > 0);
  // Each ICData propagated from unoptimized to optimized code contains the
  // function that corresponds to the Dart function of that IC call. Due
  // to inlining in optimized code, that function may not correspond to the
  // top-level function (parsed_function().function()) which could be
  // reoptimized and which counter needs to be incremented.
  // Pass the function explicitly, it is used in IC stub.

  __ LoadObject(R6, parsed_function().function());
  __ LoadFromOffset(R0, SP, (ic_data.SizeWithoutTypeArgs() - 1) * kWordSize);
  __ LoadUniqueObject(R5, ic_data);
  GenerateDartCall(deopt_id, token_pos, stub, PcDescriptorsLayout::kIcCall,
                   locs, entry_kind);
  __ Drop(ic_data.SizeWithTypeArgs());
}

void FlowGraphCompiler::EmitInstanceCallJIT(const Code& stub,
                                            const ICData& ic_data,
                                            intptr_t deopt_id,
                                            TokenPosition token_pos,
                                            LocationSummary* locs,
                                            Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  ASSERT(entry_kind == Code::EntryKind::kNormal ||
         entry_kind == Code::EntryKind::kUnchecked);
  ASSERT(Array::Handle(zone(), ic_data.arguments_descriptor()).Length() > 0);
  __ LoadFromOffset(R0, SP, (ic_data.SizeWithoutTypeArgs() - 1) * kWordSize);

  compiler::ObjectPoolBuilder& op = __ object_pool_builder();
  const intptr_t ic_data_index =
      op.AddObject(ic_data, ObjectPool::Patchability::kPatchable);
  const intptr_t stub_index =
      op.AddObject(stub, ObjectPool::Patchability::kPatchable);
  ASSERT((ic_data_index + 1) == stub_index);
  __ LoadDoubleWordFromPoolOffset(R5, CODE_REG,
                                  ObjectPool::element_offset(ic_data_index));
  const intptr_t entry_point_offset =
      entry_kind == Code::EntryKind::kNormal
          ? Code::entry_point_offset(Code::EntryKind::kMonomorphic)
          : Code::entry_point_offset(Code::EntryKind::kMonomorphicUnchecked);
  __ ldr(LR, compiler::FieldAddress(CODE_REG, entry_point_offset));
  __ blr(LR);
  EmitCallsiteMetadata(token_pos, deopt_id, PcDescriptorsLayout::kIcCall, locs);
  __ Drop(ic_data.SizeWithTypeArgs());
}

void FlowGraphCompiler::EmitMegamorphicInstanceCall(
    const String& name,
    const Array& arguments_descriptor,
    intptr_t deopt_id,
    TokenPosition token_pos,
    LocationSummary* locs,
    intptr_t try_index,
    intptr_t slow_path_argument_count) {
  ASSERT(CanCallDart());
  ASSERT(!arguments_descriptor.IsNull() && (arguments_descriptor.Length() > 0));
  const ArgumentsDescriptor args_desc(arguments_descriptor);
  const MegamorphicCache& cache = MegamorphicCache::ZoneHandle(
      zone(),
      MegamorphicCacheTable::Lookup(thread(), name, arguments_descriptor));

  __ Comment("MegamorphicCall");
  // Load receiver into R0.
  __ LoadFromOffset(R0, SP, (args_desc.Count() - 1) * kWordSize);

  // Use same code pattern as instance call so it can be parsed by code patcher.
  compiler::ObjectPoolBuilder& op = __ object_pool_builder();
  const intptr_t data_index =
      op.AddObject(cache, ObjectPool::Patchability::kPatchable);
  const intptr_t stub_index = op.AddObject(
      StubCode::MegamorphicCall(), ObjectPool::Patchability::kPatchable);
  ASSERT((data_index + 1) == stub_index);
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    // The AOT runtime will replace the slot in the object pool with the
    // entrypoint address - see clustered_snapshot.cc.
    __ LoadDoubleWordFromPoolOffset(R5, LR,
                                    ObjectPool::element_offset(data_index));
  } else {
    __ LoadDoubleWordFromPoolOffset(R5, CODE_REG,
                                    ObjectPool::element_offset(data_index));
    __ ldr(LR, compiler::FieldAddress(
                   CODE_REG,
                   Code::entry_point_offset(Code::EntryKind::kMonomorphic)));
  }
  __ blr(LR);

  RecordSafepoint(locs, slow_path_argument_count);
  const intptr_t deopt_id_after = DeoptId::ToDeoptAfter(deopt_id);
  if (FLAG_precompiled_mode) {
    // Megamorphic calls may occur in slow path stubs.
    // If valid use try_index argument.
    if (try_index == kInvalidTryIndex) {
      try_index = CurrentTryIndex();
    }
    AddDescriptor(PcDescriptorsLayout::kOther, assembler()->CodeSize(),
                  DeoptId::kNone, token_pos, try_index);
  } else if (is_optimizing()) {
    AddCurrentDescriptor(PcDescriptorsLayout::kOther, DeoptId::kNone,
                         token_pos);
    AddDeoptIndexAtCall(deopt_id_after);
  } else {
    AddCurrentDescriptor(PcDescriptorsLayout::kOther, DeoptId::kNone,
                         token_pos);
    // Add deoptimization continuation point after the call and before the
    // arguments are removed.
    AddCurrentDescriptor(PcDescriptorsLayout::kDeopt, deopt_id_after,
                         token_pos);
  }
  RecordCatchEntryMoves(pending_deoptimization_env_, try_index);
  __ Drop(args_desc.SizeWithTypeArgs());
}

void FlowGraphCompiler::EmitInstanceCallAOT(const ICData& ic_data,
                                            intptr_t deopt_id,
                                            TokenPosition token_pos,
                                            LocationSummary* locs,
                                            Code::EntryKind entry_kind,
                                            bool receiver_can_be_smi) {
  ASSERT(CanCallDart());
  ASSERT(ic_data.NumArgsTested() == 1);
  const Code& initial_stub = StubCode::SwitchableCallMiss();
  const char* switchable_call_mode = "smiable";
  if (!receiver_can_be_smi) {
    switchable_call_mode = "non-smi";
    ic_data.set_receiver_cannot_be_smi(true);
  }
  const UnlinkedCall& data =
      UnlinkedCall::ZoneHandle(zone(), ic_data.AsUnlinkedCall());

  compiler::ObjectPoolBuilder& op = __ object_pool_builder();

  __ Comment("InstanceCallAOT (%s)", switchable_call_mode);
  // Clear argument descriptor to keep gc happy when it gets pushed on to
  // the stack.
  __ LoadImmediate(R4, 0);
  __ LoadFromOffset(R0, SP, (ic_data.SizeWithoutTypeArgs() - 1) * kWordSize);

  const intptr_t data_index =
      op.AddObject(data, ObjectPool::Patchability::kPatchable);
  const intptr_t initial_stub_index =
      op.AddObject(initial_stub, ObjectPool::Patchability::kPatchable);
  ASSERT((data_index + 1) == initial_stub_index);

  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    // The AOT runtime will replace the slot in the object pool with the
    // entrypoint address - see clustered_snapshot.cc.
    __ LoadDoubleWordFromPoolOffset(R5, LR,
                                    ObjectPool::element_offset(data_index));
  } else {
    __ LoadDoubleWordFromPoolOffset(R5, CODE_REG,
                                    ObjectPool::element_offset(data_index));
    const intptr_t entry_point_offset =
        entry_kind == Code::EntryKind::kNormal
            ? compiler::target::Code::entry_point_offset(
                  Code::EntryKind::kMonomorphic)
            : compiler::target::Code::entry_point_offset(
                  Code::EntryKind::kMonomorphicUnchecked);
    __ ldr(LR, compiler::FieldAddress(CODE_REG, entry_point_offset));
  }
  __ blr(LR);

  EmitCallsiteMetadata(token_pos, DeoptId::kNone, PcDescriptorsLayout::kOther,
                       locs);
  __ Drop(ic_data.SizeWithTypeArgs());
}

void FlowGraphCompiler::EmitUnoptimizedStaticCall(intptr_t size_with_type_args,
                                                  intptr_t deopt_id,
                                                  TokenPosition token_pos,
                                                  LocationSummary* locs,
                                                  const ICData& ic_data,
                                                  Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  const Code& stub =
      StubCode::UnoptimizedStaticCallEntry(ic_data.NumArgsTested());
  __ LoadObject(R5, ic_data);
  GenerateDartCall(deopt_id, token_pos, stub,
                   PcDescriptorsLayout::kUnoptStaticCall, locs, entry_kind);
  __ Drop(size_with_type_args);
}

void FlowGraphCompiler::EmitOptimizedStaticCall(
    const Function& function,
    const Array& arguments_descriptor,
    intptr_t size_with_type_args,
    intptr_t deopt_id,
    TokenPosition token_pos,
    LocationSummary* locs,
    Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  ASSERT(!function.IsClosureFunction());
  if (function.HasOptionalParameters() || function.IsGeneric()) {
    __ LoadObject(R4, arguments_descriptor);
  } else {
    if (!(FLAG_precompiled_mode && FLAG_use_bare_instructions)) {
      __ LoadImmediate(R4, 0);  // GC safe smi zero because of stub.
    }
  }
  // Do not use the code from the function, but let the code be patched so that
  // we can record the outgoing edges to other code.
  GenerateStaticDartCall(deopt_id, token_pos, PcDescriptorsLayout::kOther, locs,
                         function, entry_kind);
  __ Drop(size_with_type_args);
}

void FlowGraphCompiler::EmitDispatchTableCall(
    Register cid_reg,
    int32_t selector_offset,
    const Array& arguments_descriptor) {
  ASSERT(CanCallDart());
  ASSERT(cid_reg != ARGS_DESC_REG);
  if (!arguments_descriptor.IsNull()) {
    __ LoadObject(ARGS_DESC_REG, arguments_descriptor);
  }
  const intptr_t offset = selector_offset - DispatchTable::OriginElement();
  __ AddImmediate(cid_reg, cid_reg, offset);
  __ ldr(LR, compiler::Address(DISPATCH_TABLE_REG, cid_reg, UXTX,
                               compiler::Address::Scaled));
  __ blr(LR);
}

Condition FlowGraphCompiler::EmitEqualityRegConstCompare(
    Register reg,
    const Object& obj,
    bool needs_number_check,
    TokenPosition token_pos,
    intptr_t deopt_id) {
  if (needs_number_check) {
    ASSERT(!obj.IsMint() && !obj.IsDouble());
    __ LoadObject(TMP, obj);
    __ PushPair(TMP, reg);
    if (is_optimizing()) {
      __ BranchLinkPatchable(StubCode::OptimizedIdenticalWithNumberCheck());
    } else {
      __ BranchLinkPatchable(StubCode::UnoptimizedIdenticalWithNumberCheck());
    }
    AddCurrentDescriptor(PcDescriptorsLayout::kRuntimeCall, deopt_id,
                         token_pos);
    // Stub returns result in flags (result of a cmp, we need Z computed).
    // Discard constant.
    // Restore 'reg'.
    __ PopPair(ZR, reg);
  } else {
    __ CompareObject(reg, obj);
  }
  return EQ;
}

Condition FlowGraphCompiler::EmitEqualityRegRegCompare(Register left,
                                                       Register right,
                                                       bool needs_number_check,
                                                       TokenPosition token_pos,
                                                       intptr_t deopt_id) {
  if (needs_number_check) {
    __ PushPair(right, left);
    if (is_optimizing()) {
      __ BranchLinkPatchable(StubCode::OptimizedIdenticalWithNumberCheck());
    } else {
      __ BranchLinkPatchable(StubCode::UnoptimizedIdenticalWithNumberCheck());
    }
    AddCurrentDescriptor(PcDescriptorsLayout::kRuntimeCall, deopt_id,
                         token_pos);
    // Stub returns result in flags (result of a cmp, we need Z computed).
    __ PopPair(right, left);
  } else {
    __ CompareRegisters(left, right);
  }
  return EQ;
}

Condition FlowGraphCompiler::EmitBoolTest(Register value,
                                          BranchLabels labels,
                                          bool invert) {
  __ Comment("BoolTest");
  if (labels.true_label == nullptr || labels.false_label == nullptr) {
    __ tsti(value, compiler::Immediate(
                       compiler::target::ObjectAlignment::kBoolValueMask));
    return invert ? NE : EQ;
  }
  const intptr_t bool_bit =
      compiler::target::ObjectAlignment::kBoolValueBitPosition;
  if (labels.fall_through == labels.false_label) {
    if (invert) {
      __ tbnz(labels.true_label, value, bool_bit);
    } else {
      __ tbz(labels.true_label, value, bool_bit);
    }
  } else {
    if (invert) {
      __ tbz(labels.false_label, value, bool_bit);
    } else {
      __ tbnz(labels.false_label, value, bool_bit);
    }
    if (labels.fall_through != labels.true_label) {
      __ b(labels.true_label);
    }
  }
  return kInvalidCondition;
}

// This function must be in sync with FlowGraphCompiler::RecordSafepoint and
// FlowGraphCompiler::SlowPathEnvironmentFor.
void FlowGraphCompiler::SaveLiveRegisters(LocationSummary* locs) {
#if defined(DEBUG)
  locs->CheckWritableInputs();
  ClobberDeadTempRegisters(locs);
#endif
  // TODO(vegorov): consider saving only caller save (volatile) registers.
  __ PushRegisters(*locs->live_registers());
}

void FlowGraphCompiler::RestoreLiveRegisters(LocationSummary* locs) {
  __ PopRegisters(*locs->live_registers());
}

#if defined(DEBUG)
void FlowGraphCompiler::ClobberDeadTempRegisters(LocationSummary* locs) {
  // Clobber temporaries that have not been manually preserved.
  for (intptr_t i = 0; i < locs->temp_count(); ++i) {
    Location tmp = locs->temp(i);
    // TODO(zerny): clobber non-live temporary FPU registers.
    if (tmp.IsRegister() &&
        !locs->live_registers()->ContainsRegister(tmp.reg())) {
      __ movz(tmp.reg(), compiler::Immediate(0xf7), 0);
    }
  }
}
#endif

Register FlowGraphCompiler::EmitTestCidRegister() {
  return R2;
}

void FlowGraphCompiler::EmitTestAndCallLoadReceiver(
    intptr_t count_without_type_args,
    const Array& arguments_descriptor) {
  __ Comment("EmitTestAndCall");
  // Load receiver into R0.
  __ LoadFromOffset(R0, SP, (count_without_type_args - 1) * kWordSize);
  __ LoadObject(R4, arguments_descriptor);
}

void FlowGraphCompiler::EmitTestAndCallSmiBranch(compiler::Label* label,
                                                 bool if_smi) {
  if (if_smi) {
    __ BranchIfSmi(R0, label);
  } else {
    __ BranchIfNotSmi(R0, label);
  }
}

void FlowGraphCompiler::EmitTestAndCallLoadCid(Register class_id_reg) {
  ASSERT(class_id_reg != R0);
  __ LoadClassId(class_id_reg, R0);
}

#undef __
#define __ assembler->

int FlowGraphCompiler::EmitTestAndCallCheckCid(compiler::Assembler* assembler,
                                               compiler::Label* label,
                                               Register class_id_reg,
                                               const CidRangeValue& range,
                                               int bias,
                                               bool jump_on_miss) {
  const intptr_t cid_start = range.cid_start;
  if (range.IsSingleCid()) {
    __ AddImmediateSetFlags(class_id_reg, class_id_reg, bias - cid_start);
    __ BranchIf(jump_on_miss ? NOT_EQUAL : EQUAL, label);
    bias = cid_start;
  } else {
    __ AddImmediate(class_id_reg, bias - cid_start);
    bias = cid_start;
    __ CompareImmediate(class_id_reg, range.Extent());
    __ BranchIf(jump_on_miss ? UNSIGNED_GREATER : UNSIGNED_LESS_EQUAL, label);
  }
  return bias;
}

#undef __
#define __ assembler()->

void FlowGraphCompiler::EmitMove(Location destination,
                                 Location source,
                                 TemporaryRegisterAllocator* allocator) {
  if (destination.Equals(source)) return;

  if (source.IsRegister()) {
    if (destination.IsRegister()) {
      __ mov(destination.reg(), source.reg());
    } else {
      ASSERT(destination.IsStackSlot());
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      __ StoreToOffset(source.reg(), destination.base_reg(), dest_offset);
    }
  } else if (source.IsStackSlot()) {
    if (destination.IsRegister()) {
      const intptr_t source_offset = source.ToStackSlotOffset();
      __ LoadFromOffset(destination.reg(), source.base_reg(), source_offset);
    } else if (destination.IsFpuRegister()) {
      const intptr_t src_offset = source.ToStackSlotOffset();
      VRegister dst = destination.fpu_reg();
      __ LoadDFromOffset(dst, source.base_reg(), src_offset);
    } else {
      ASSERT(destination.IsStackSlot());
      const intptr_t source_offset = source.ToStackSlotOffset();
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      Register tmp = allocator->AllocateTemporary();
      __ LoadFromOffset(tmp, source.base_reg(), source_offset);
      __ StoreToOffset(tmp, destination.base_reg(), dest_offset);
      allocator->ReleaseTemporary();
    }
  } else if (source.IsFpuRegister()) {
    if (destination.IsFpuRegister()) {
      __ vmov(destination.fpu_reg(), source.fpu_reg());
    } else {
      if (destination.IsStackSlot() /*32-bit float*/ ||
          destination.IsDoubleStackSlot()) {
        const intptr_t dest_offset = destination.ToStackSlotOffset();
        VRegister src = source.fpu_reg();
        __ StoreDToOffset(src, destination.base_reg(), dest_offset);
      } else {
        ASSERT(destination.IsQuadStackSlot());
        const intptr_t dest_offset = destination.ToStackSlotOffset();
        __ StoreQToOffset(source.fpu_reg(), destination.base_reg(),
                          dest_offset);
      }
    }
  } else if (source.IsDoubleStackSlot()) {
    if (destination.IsFpuRegister()) {
      const intptr_t source_offset = source.ToStackSlotOffset();
      const VRegister dst = destination.fpu_reg();
      __ LoadDFromOffset(dst, source.base_reg(), source_offset);
    } else {
      ASSERT(destination.IsDoubleStackSlot() ||
             destination.IsStackSlot() /*32-bit float*/);
      const intptr_t source_offset = source.ToStackSlotOffset();
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      __ LoadDFromOffset(VTMP, source.base_reg(), source_offset);
      __ StoreDToOffset(VTMP, destination.base_reg(), dest_offset);
    }
  } else if (source.IsQuadStackSlot()) {
    if (destination.IsFpuRegister()) {
      const intptr_t source_offset = source.ToStackSlotOffset();
      __ LoadQFromOffset(destination.fpu_reg(), source.base_reg(),
                         source_offset);
    } else {
      ASSERT(destination.IsQuadStackSlot());
      const intptr_t source_offset = source.ToStackSlotOffset();
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      __ LoadQFromOffset(VTMP, source.base_reg(), source_offset);
      __ StoreQToOffset(VTMP, destination.base_reg(), dest_offset);
    }
  } else {
    ASSERT(source.IsConstant());
    if (destination.IsStackSlot()) {
      Register tmp = allocator->AllocateTemporary();
      source.constant_instruction()->EmitMoveToLocation(this, destination, tmp);
      allocator->ReleaseTemporary();
    } else {
      source.constant_instruction()->EmitMoveToLocation(this, destination);
    }
  }
}

static OperandSize BytesToOperandSize(intptr_t bytes) {
  switch (bytes) {
    case 8:
      return OperandSize::kDoubleWord;
    case 4:
      return OperandSize::kWord;
    case 2:
      return OperandSize::kHalfword;
    case 1:
      return OperandSize::kByte;
    default:
      UNIMPLEMENTED();
  }
}

void FlowGraphCompiler::EmitNativeMoveArchitecture(
    const compiler::ffi::NativeLocation& destination,
    const compiler::ffi::NativeLocation& source) {
  const auto& src_type = source.payload_type();
  const auto& dst_type = destination.payload_type();
  ASSERT(src_type.IsFloat() == dst_type.IsFloat());
  ASSERT(src_type.IsInt() == dst_type.IsInt());
  ASSERT(src_type.IsSigned() == dst_type.IsSigned());
  ASSERT(src_type.IsFundamental());
  ASSERT(dst_type.IsFundamental());
  const intptr_t src_size = src_type.SizeInBytes();
  const intptr_t dst_size = dst_type.SizeInBytes();
  const bool sign_or_zero_extend = dst_size > src_size;

  if (source.IsRegisters()) {
    const auto& src = source.AsRegisters();
    ASSERT(src.num_regs() == 1);
    const auto src_reg = src.reg_at(0);

    if (destination.IsRegisters()) {
      const auto& dst = destination.AsRegisters();
      ASSERT(dst.num_regs() == 1);
      const auto dst_reg = dst.reg_at(0);
      if (!sign_or_zero_extend) {
        switch (dst_size) {
          case 8:
            __ mov(dst_reg, src_reg);
            return;
          case 4:
            __ movw(dst_reg, src_reg);
            return;
          default:
            UNIMPLEMENTED();
        }
      } else {
        switch (src_type.AsFundamental().representation()) {
          case compiler::ffi::kInt8:  // Sign extend operand.
            __ sxtb(dst_reg, src_reg);
            return;
          case compiler::ffi::kInt16:
            __ sxth(dst_reg, src_reg);
            return;
          case compiler::ffi::kUint8:  // Zero extend operand.
            __ uxtb(dst_reg, src_reg);
            return;
          case compiler::ffi::kUint16:
            __ uxth(dst_reg, src_reg);
            return;
          default:
            // 32 to 64 bit is covered in IL by Representation conversions.
            UNIMPLEMENTED();
        }
      }

    } else if (destination.IsFpuRegisters()) {
      // Fpu Registers should only contain doubles and registers only ints.
      UNIMPLEMENTED();

    } else {
      ASSERT(destination.IsStack());
      const auto& dst = destination.AsStack();
      ASSERT(!sign_or_zero_extend);
      const OperandSize op_size = BytesToOperandSize(dst_size);
      __ StoreToOffset(src.reg_at(0), dst.base_register(),
                       dst.offset_in_bytes(), op_size);
    }

  } else if (source.IsFpuRegisters()) {
    const auto& src = source.AsFpuRegisters();
    // We have not implemented conversions here, use IL convert instructions.
    ASSERT(src_type.Equals(dst_type));

    if (destination.IsRegisters()) {
      // Fpu Registers should only contain doubles and registers only ints.
      UNIMPLEMENTED();

    } else if (destination.IsFpuRegisters()) {
      const auto& dst = destination.AsFpuRegisters();
      __ vmov(dst.fpu_reg(), src.fpu_reg());

    } else {
      ASSERT(destination.IsStack());
      ASSERT(src_type.IsFloat());
      const auto& dst = destination.AsStack();
      switch (dst_size) {
        case 8:
          __ StoreDToOffset(src.fpu_reg(), dst.base_register(),
                            dst.offset_in_bytes());
          return;
        case 4:
          __ StoreSToOffset(src.fpu_reg(), dst.base_register(),
                            dst.offset_in_bytes());
          return;
        default:
          UNREACHABLE();
      }
    }

  } else {
    ASSERT(source.IsStack());
    const auto& src = source.AsStack();
    if (destination.IsRegisters()) {
      const auto& dst = destination.AsRegisters();
      ASSERT(dst.num_regs() == 1);
      const auto dst_reg = dst.reg_at(0);
      ASSERT(!sign_or_zero_extend);
      const OperandSize op_size = BytesToOperandSize(dst_size);
      __ LoadFromOffset(dst_reg, src.base_register(), src.offset_in_bytes(),
                        op_size);

    } else if (destination.IsFpuRegisters()) {
      ASSERT(src_type.Equals(dst_type));
      ASSERT(src_type.IsFloat());
      const auto& dst = destination.AsFpuRegisters();
      switch (src_size) {
        case 8:
          __ LoadDFromOffset(dst.fpu_reg(), src.base_register(),
                             src.offset_in_bytes());
          return;
        case 4:
          __ LoadSFromOffset(dst.fpu_reg(), src.base_register(),
                             src.offset_in_bytes());
          return;
        default:
          UNIMPLEMENTED();
      }

    } else {
      ASSERT(destination.IsStack());
      UNREACHABLE();
    }
  }
}

void FlowGraphCompiler::LoadBSSEntry(BSS::Relocation relocation,
                                     Register dst,
                                     Register tmp) {
  compiler::Label skip_reloc;
  __ b(&skip_reloc);
  InsertBSSRelocation(relocation);
  __ Bind(&skip_reloc);

  __ adr(tmp, compiler::Immediate(-compiler::target::kWordSize));

  // tmp holds the address of the relocation.
  __ ldr(dst, compiler::Address(tmp));

  // dst holds the relocation itself: tmp - bss_start.
  // tmp = tmp + (bss_start - tmp) = bss_start
  __ add(tmp, tmp, compiler::Operand(dst));

  // tmp holds the start of the BSS section.
  // Load the "get-thread" routine: *bss_start.
  __ ldr(dst, compiler::Address(tmp));
}

#undef __
#define __ compiler_->assembler()->

void ParallelMoveResolver::EmitSwap(int index) {
  MoveOperands* move = moves_[index];
  const Location source = move->src();
  const Location destination = move->dest();

  if (source.IsRegister() && destination.IsRegister()) {
    ASSERT(source.reg() != TMP);
    ASSERT(destination.reg() != TMP);
    __ mov(TMP, source.reg());
    __ mov(source.reg(), destination.reg());
    __ mov(destination.reg(), TMP);
  } else if (source.IsRegister() && destination.IsStackSlot()) {
    Exchange(source.reg(), destination.base_reg(),
             destination.ToStackSlotOffset());
  } else if (source.IsStackSlot() && destination.IsRegister()) {
    Exchange(destination.reg(), source.base_reg(), source.ToStackSlotOffset());
  } else if (source.IsStackSlot() && destination.IsStackSlot()) {
    Exchange(source.base_reg(), source.ToStackSlotOffset(),
             destination.base_reg(), destination.ToStackSlotOffset());
  } else if (source.IsFpuRegister() && destination.IsFpuRegister()) {
    const VRegister dst = destination.fpu_reg();
    const VRegister src = source.fpu_reg();
    __ vmov(VTMP, src);
    __ vmov(src, dst);
    __ vmov(dst, VTMP);
  } else if (source.IsFpuRegister() || destination.IsFpuRegister()) {
    ASSERT(destination.IsDoubleStackSlot() || destination.IsQuadStackSlot() ||
           source.IsDoubleStackSlot() || source.IsQuadStackSlot());
    bool double_width =
        destination.IsDoubleStackSlot() || source.IsDoubleStackSlot();
    VRegister reg =
        source.IsFpuRegister() ? source.fpu_reg() : destination.fpu_reg();
    Register base_reg =
        source.IsFpuRegister() ? destination.base_reg() : source.base_reg();
    const intptr_t slot_offset = source.IsFpuRegister()
                                     ? destination.ToStackSlotOffset()
                                     : source.ToStackSlotOffset();

    if (double_width) {
      __ LoadDFromOffset(VTMP, base_reg, slot_offset);
      __ StoreDToOffset(reg, base_reg, slot_offset);
      __ fmovdd(reg, VTMP);
    } else {
      __ LoadQFromOffset(VTMP, base_reg, slot_offset);
      __ StoreQToOffset(reg, base_reg, slot_offset);
      __ vmov(reg, VTMP);
    }
  } else if (source.IsDoubleStackSlot() && destination.IsDoubleStackSlot()) {
    const intptr_t source_offset = source.ToStackSlotOffset();
    const intptr_t dest_offset = destination.ToStackSlotOffset();

    ScratchFpuRegisterScope ensure_scratch(this, kNoFpuRegister);
    VRegister scratch = ensure_scratch.reg();
    __ LoadDFromOffset(VTMP, source.base_reg(), source_offset);
    __ LoadDFromOffset(scratch, destination.base_reg(), dest_offset);
    __ StoreDToOffset(VTMP, destination.base_reg(), dest_offset);
    __ StoreDToOffset(scratch, source.base_reg(), source_offset);
  } else if (source.IsQuadStackSlot() && destination.IsQuadStackSlot()) {
    const intptr_t source_offset = source.ToStackSlotOffset();
    const intptr_t dest_offset = destination.ToStackSlotOffset();

    ScratchFpuRegisterScope ensure_scratch(this, kNoFpuRegister);
    VRegister scratch = ensure_scratch.reg();
    __ LoadQFromOffset(VTMP, source.base_reg(), source_offset);
    __ LoadQFromOffset(scratch, destination.base_reg(), dest_offset);
    __ StoreQToOffset(VTMP, destination.base_reg(), dest_offset);
    __ StoreQToOffset(scratch, source.base_reg(), source_offset);
  } else {
    UNREACHABLE();
  }

  // The swap of source and destination has executed a move from source to
  // destination.
  move->Eliminate();

  // Any unperformed (including pending) move with a source of either
  // this move's source or destination needs to have their source
  // changed to reflect the state of affairs after the swap.
  for (int i = 0; i < moves_.length(); ++i) {
    const MoveOperands& other_move = *moves_[i];
    if (other_move.Blocks(source)) {
      moves_[i]->set_src(destination);
    } else if (other_move.Blocks(destination)) {
      moves_[i]->set_src(source);
    }
  }
}

void ParallelMoveResolver::MoveMemoryToMemory(const compiler::Address& dst,
                                              const compiler::Address& src) {
  UNREACHABLE();
}

// Do not call or implement this function. Instead, use the form below that
// uses an offset from the frame pointer instead of an Address.
void ParallelMoveResolver::Exchange(Register reg,
                                    const compiler::Address& mem) {
  UNREACHABLE();
}

// Do not call or implement this function. Instead, use the form below that
// uses offsets from the frame pointer instead of Addresses.
void ParallelMoveResolver::Exchange(const compiler::Address& mem1,
                                    const compiler::Address& mem2) {
  UNREACHABLE();
}

void ParallelMoveResolver::Exchange(Register reg,
                                    Register base_reg,
                                    intptr_t stack_offset) {
  ScratchRegisterScope tmp(this, reg);
  __ mov(tmp.reg(), reg);
  __ LoadFromOffset(reg, base_reg, stack_offset);
  __ StoreToOffset(tmp.reg(), base_reg, stack_offset);
}

void ParallelMoveResolver::Exchange(Register base_reg1,
                                    intptr_t stack_offset1,
                                    Register base_reg2,
                                    intptr_t stack_offset2) {
  ScratchRegisterScope tmp1(this, kNoRegister);
  ScratchRegisterScope tmp2(this, tmp1.reg());
  __ LoadFromOffset(tmp1.reg(), base_reg1, stack_offset1);
  __ LoadFromOffset(tmp2.reg(), base_reg2, stack_offset2);
  __ StoreToOffset(tmp1.reg(), base_reg2, stack_offset2);
  __ StoreToOffset(tmp2.reg(), base_reg1, stack_offset1);
}

void ParallelMoveResolver::SpillScratch(Register reg) {
  __ Push(reg);
}

void ParallelMoveResolver::RestoreScratch(Register reg) {
  __ Pop(reg);
}

void ParallelMoveResolver::SpillFpuScratch(FpuRegister reg) {
  __ PushDouble(reg);
}

void ParallelMoveResolver::RestoreFpuScratch(FpuRegister reg) {
  __ PopDouble(reg);
}

#undef __

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM64)

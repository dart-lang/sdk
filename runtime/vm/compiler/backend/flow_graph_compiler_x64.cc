// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/compiler/backend/flow_graph_compiler.h"

#include "vm/compiler/api/type_check_mode.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/ffi/native_location.h"
#include "vm/compiler/jit/compiler.h"
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
DEFINE_FLAG(bool, unbox_mints, true, "Optimize 64-bit integer arithmetic.");
DECLARE_FLAG(bool, enable_simd_inline);

void FlowGraphCompiler::ArchSpecificInitialization() {
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    auto object_store = isolate()->object_store();

    const auto& stub =
        Code::ZoneHandle(object_store->write_barrier_wrappers_stub());
    if (!stub.InVMIsolateHeap()) {
      assembler_->generate_invoke_write_barrier_wrapper_ = [&](Register reg) {
        const intptr_t offset_into_target =
            Thread::WriteBarrierWrappersOffsetForRegister(reg);
        assembler_->GenerateUnRelocatedPcRelativeCall(offset_into_target);
        AddPcRelativeCallStubTarget(stub);
      };
    }

    const auto& array_stub =
        Code::ZoneHandle(object_store->array_write_barrier_stub());
    if (!array_stub.InVMIsolateHeap()) {
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
    ASSERT(!block_info_[i]->jump_label()->HasNear());
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

bool FlowGraphCompiler::SupportsHardwareDivision() {
  return true;
}

bool FlowGraphCompiler::CanConvertInt64ToDouble() {
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

  // Set slots for the outermost environment.
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
    __ int3();
  }

  ASSERT(deopt_env() != NULL);
  __ call(compiler::Address(THR, Thread::deoptimize_entry_offset()));
  set_pc_offset(assembler->CodeSize());
  __ int3();
#undef __
}

#define __ assembler()->

// Fall through if bool_register contains null.
void FlowGraphCompiler::GenerateBoolToJump(Register bool_register,
                                           compiler::Label* is_true,
                                           compiler::Label* is_false) {
  compiler::Label fall_through;
  __ CompareObject(bool_register, Object::null_object());
  __ j(EQUAL, &fall_through, compiler::Assembler::kNearJump);
  BranchLabels labels = {is_true, is_false, &fall_through};
  Condition true_condition =
      EmitBoolTest(bool_register, labels, /*invert=*/false);
  ASSERT(true_condition != kInvalidCondition);
  __ j(true_condition, is_true);
  __ jmp(is_false);
  __ Bind(&fall_through);
}

// Call stub to perform subtype test using a cache (see
// stub_code_x64.cc:GenerateSubtypeNTestCacheStub)
//
// Inputs:
//   - RAX : instance to test against.
//   - RDX : instantiator type arguments (if necessary).
//   - RCX : function type arguments (if necessary).
//
// Preserves RAX/RCX/RDX.
SubtypeTestCachePtr FlowGraphCompiler::GenerateCallSubtypeTestStub(
    TypeTestStubKind test_kind,
    Register instance_reg,
    Register instantiator_type_arguments_reg,
    Register function_type_arguments_reg,
    Register temp_reg,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  ASSERT(temp_reg == kNoRegister);
  const SubtypeTestCache& type_test_cache =
      SubtypeTestCache::ZoneHandle(zone(), SubtypeTestCache::New());
  __ LoadUniqueObject(R9, type_test_cache);
  if (test_kind == kTestTypeOneArg) {
    ASSERT(instantiator_type_arguments_reg == kNoRegister);
    ASSERT(function_type_arguments_reg == kNoRegister);
    __ Call(StubCode::Subtype1TestCache());
  } else if (test_kind == kTestTypeTwoArgs) {
    ASSERT(instantiator_type_arguments_reg == kNoRegister);
    ASSERT(function_type_arguments_reg == kNoRegister);
    __ Call(StubCode::Subtype2TestCache());
  } else if (test_kind == kTestTypeFourArgs) {
    ASSERT(instantiator_type_arguments_reg ==
           TypeTestABI::kInstantiatorTypeArgumentsReg);
    ASSERT(function_type_arguments_reg ==
           TypeTestABI::kFunctionTypeArgumentsReg);
    __ Call(StubCode::Subtype4TestCache());
  } else if (test_kind == kTestTypeSixArgs) {
    ASSERT(instantiator_type_arguments_reg ==
           TypeTestABI::kInstantiatorTypeArgumentsReg);
    ASSERT(function_type_arguments_reg ==
           TypeTestABI::kFunctionTypeArgumentsReg);
    __ Call(StubCode::Subtype6TestCache());
  } else {
    UNREACHABLE();
  }
  // Result is in R8: null -> not found, otherwise Bool::True or Bool::False.
  GenerateBoolToJump(R8, is_instance_lbl, is_not_instance_lbl);
  return type_test_cache.raw();
}

// Jumps to labels 'is_instance' or 'is_not_instance' respectively, if
// type test is conclusive, otherwise fallthrough if a type test could not
// be completed.
// RAX: instance (must survive).
// Clobbers R10.
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
  __ testq(TypeTestABI::kInstanceReg, compiler::Immediate(kSmiTagMask));
  if (smi_is_ok) {
    // Fast case for type = FutureOr<int/num/top-type>.
    __ j(ZERO, is_instance_lbl);
  } else {
    __ j(ZERO, is_not_instance_lbl);
  }

  const intptr_t num_type_args = type_class.NumTypeArguments();
  const intptr_t num_type_params = type_class.NumTypeParameters();
  const intptr_t from_index = num_type_args - num_type_params;
  const TypeArguments& type_arguments =
      TypeArguments::ZoneHandle(zone(), type.arguments());
  const bool is_raw_type = type_arguments.IsNull() ||
                           type_arguments.IsRaw(from_index, num_type_params);
  if (is_raw_type) {
    const Register kClassIdReg = R10;
    // dynamic type argument, check only classes.
    __ LoadClassId(kClassIdReg, TypeTestABI::kInstanceReg);
    __ cmpl(kClassIdReg, compiler::Immediate(type_class.id()));
    __ j(EQUAL, is_instance_lbl);
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
    __ cmpl(class_id_reg, compiler::Immediate(class_ids[i]));
    __ j(EQUAL, is_equal_lbl);
  }
  __ jmp(is_not_equal_lbl);
}

// Testing against an instantiated type with no arguments, without
// SubtypeTestCache
//
// Inputs:
//   - RAX : instance to test against
//
// Preserves RAX/RCX/RDX.
//
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

  __ testq(TypeTestABI::kInstanceReg, compiler::Immediate(kSmiTagMask));
  // If instance is Smi, check directly.
  const Class& smi_class = Class::Handle(zone(), Smi::Class());
  if (Class::IsSubtypeOf(smi_class, Object::null_type_arguments(),
                         Nullability::kNonNullable, type, Heap::kOld)) {
    // Fast case for type = int/num/top-type.
    __ j(ZERO, is_instance_lbl);
  } else {
    __ j(ZERO, is_not_instance_lbl);
  }
  const Register kClassIdReg = R10;
  __ LoadClassId(kClassIdReg, TypeTestABI::kInstanceReg);
  // Bool interface can be implemented only by core class Bool.
  if (type.IsBoolType()) {
    __ cmpl(kClassIdReg, compiler::Immediate(kBoolCid));
    __ j(EQUAL, is_instance_lbl);
    __ jmp(is_not_instance_lbl);
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
    __ cmpq(kClassIdReg, compiler::Immediate(kClosureCid));
    __ j(EQUAL, is_instance_lbl);
    return true;
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
// Immediate class test already done.
//
// Inputs:
//   RAX : instance to test against.
//
// Preserves RAX/RCX/RDX.
//
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
  __ LoadClassById(R10, TMP);
  // R10: instance class.
  // Check immediate superclass equality. If type_class is Object, then testing
  // supertype may yield a wrong result for Null in NNBD strong mode (because
  // Null also extends Object).
  if (!type_class.IsObjectClass() || !Isolate::Current()->null_safety()) {
    __ movq(R13, compiler::FieldAddress(R10, Class::super_type_offset()));
    __ movq(R13, compiler::FieldAddress(R13, Type::type_class_id_offset()));
    __ CompareImmediate(R13,
                        compiler::Immediate(Smi::RawValue(type_class.id())));
    __ j(EQUAL, is_instance_lbl);
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
//
// Inputs:
//   - RAX : instance to test against.
//   - RDX : instantiator type arguments (if necessary).
//   - RCX : function type arguments (if necessary).
//
// Preserves RAX/RCX/RDX.
SubtypeTestCachePtr FlowGraphCompiler::GenerateUninstantiatedTypeTest(
    TokenPosition token_pos,
    const AbstractType& type,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  const Register kTempReg = kNoRegister;
  __ Comment("UninstantiatedTypeTest");
  ASSERT(!type.IsInstantiated());
  ASSERT(!type.IsFunctionType());
  // Skip check if destination is a dynamic type.
  if (type.IsTypeParameter()) {
    const TypeParameter& type_param = TypeParameter::Cast(type);

    const Register kTypeArgumentsReg =
        type_param.IsClassTypeParameter()
            ? TypeTestABI::kInstantiatorTypeArgumentsReg
            : TypeTestABI::kFunctionTypeArgumentsReg;
    // Check if type arguments are null, i.e. equivalent to vector of dynamic.
    __ CompareObject(kTypeArgumentsReg, Object::null_object());
    __ j(EQUAL, is_instance_lbl);
    __ movq(RDI, compiler::FieldAddress(
                     kTypeArgumentsReg,
                     TypeArguments::type_at_offset(type_param.index())));
    // RDI: Concrete type of type.
    // Check if type argument is dynamic, Object?, or void.
    __ CompareObject(RDI, Object::dynamic_type());
    __ j(EQUAL, is_instance_lbl);
    __ CompareObject(
        RDI, Type::ZoneHandle(
                 zone(), isolate()->object_store()->nullable_object_type()));
    __ j(EQUAL, is_instance_lbl);
    __ CompareObject(RDI, Object::void_type());
    __ j(EQUAL, is_instance_lbl);

    // For Smi check quickly against int and num interfaces.
    compiler::Label not_smi;
    __ testq(RAX, compiler::Immediate(kSmiTagMask));  // Value is Smi?
    __ j(NOT_ZERO, &not_smi, compiler::Assembler::kNearJump);
    __ CompareObject(RDI, Type::ZoneHandle(zone(), Type::IntType()));
    __ j(EQUAL, is_instance_lbl);
    __ CompareObject(RDI, Type::ZoneHandle(zone(), Type::Number()));
    __ j(EQUAL, is_instance_lbl);
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
      __ testq(TypeTestABI::kInstanceReg,
               compiler::Immediate(kSmiTagMask));  // Is instance Smi?
      __ j(ZERO, is_not_instance_lbl);
    }
    // Uninstantiated type class is known at compile time, but the type
    // arguments are determined at runtime by the instantiator(s).
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
  const Register kTempReg = kNoRegister;
  __ Comment("FunctionTypeTest");

  __ testq(TypeTestABI::kInstanceReg, compiler::Immediate(kSmiTagMask));
  __ j(ZERO, is_not_instance_lbl);
  return GenerateCallSubtypeTestStub(
      kTestTypeSixArgs, TypeTestABI::kInstanceReg,
      TypeTestABI::kInstantiatorTypeArgumentsReg,
      TypeTestABI::kFunctionTypeArgumentsReg, kTempReg, is_instance_lbl,
      is_not_instance_lbl);
}

// Inputs:
//   - RAX : instance to test against.
//   - RDX : instantiator type arguments.
//   - RCX : function type arguments.
//
// Preserves RAX/RCX/RDX.
//
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
// - RAX: object.
// - RDX: instantiator type arguments or raw_null.
// - RCX: function type arguments or raw_null.
// Returns:
// - true or false in RAX.
void FlowGraphCompiler::GenerateInstanceOf(TokenPosition token_pos,
                                           intptr_t deopt_id,
                                           const AbstractType& type,
                                           LocationSummary* locs) {
  ASSERT(type.IsFinalized());
  ASSERT(!type.IsTopTypeForInstanceOf());  // Already checked.

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
    __ j(EQUAL, (unwrapped_type.IsNullable() ||
                 (unwrapped_type.IsLegacy() && unwrapped_type.IsNeverType()))
                    ? &is_instance
                    : &is_not_instance);
  }

  // Generate inline instanceof test.
  SubtypeTestCache& test_cache = SubtypeTestCache::ZoneHandle(zone());
  // The registers RAX, RCX, RDX are preserved across the call.
  test_cache =
      GenerateInlineInstanceof(token_pos, type, &is_instance, &is_not_instance);

  // test_cache is null if there is no fall-through.
  compiler::Label done;
  if (!test_cache.IsNull()) {
    // Generate Runtime call.
    __ LoadUniqueObject(TypeTestABI::kDstTypeReg, type);
    __ LoadUniqueObject(TypeTestABI::kSubtypeTestCacheReg, test_cache);
    GenerateStubCall(token_pos, StubCode::InstanceOf(),
                     /*kind=*/PcDescriptorsLayout::kOther, locs, deopt_id);
    __ jmp(&done, compiler::Assembler::kNearJump);
  }
  __ Bind(&is_not_instance);
  __ LoadObject(RAX, Bool::Get(false));
  __ jmp(&done, compiler::Assembler::kNearJump);

  __ Bind(&is_instance);
  __ LoadObject(RAX, Bool::Get(true));
  __ Bind(&done);
}

// Optimize assignable type check by adding inlined tests for:
// - NULL -> return NULL.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs:
// - RAX: object.
// - RBX: destination type (if non-constant).
// - RDX: instantiator type arguments or raw_null.
// - RCX: function type arguments or raw_null.
// Returns:
// - object in RAX for successful assignable check (or throws TypeError).
// Performance notes: positive checks must be quick, negative checks can be slow
// as they throw an exception.
void FlowGraphCompiler::GenerateAssertAssignable(CompileType* receiver_type,
                                                 TokenPosition token_pos,
                                                 intptr_t deopt_id,
                                                 const String& dst_name,
                                                 LocationSummary* locs) {
  ASSERT(!token_pos.IsClassifying());
  ASSERT(CheckAssertAssignableTypeTestingABILocations(*locs));

  compiler::Label is_assignable, runtime_call;

  // Generate inline type check, linking to runtime call if not assignable.
  SubtypeTestCache& test_cache = SubtypeTestCache::ZoneHandle(zone());

  if (locs->in(1).IsConstant()) {
    const auto& dst_type = AbstractType::Cast(locs->in(1).constant());
    ASSERT(dst_type.IsFinalized());

    if (dst_type.IsTopTypeForSubtyping()) return;  // No code needed.

    if (ShouldUseTypeTestingStubFor(is_optimizing(), dst_type)) {
      GenerateAssertAssignableViaTypeTestingStub(receiver_type, token_pos,
                                                 deopt_id, dst_name, locs);
      return;
    }

    if (Instance::NullIsAssignableTo(dst_type)) {
      __ CompareObject(TypeTestABI::kInstanceReg, Object::null_object());
      __ j(EQUAL, &is_assignable);
    }

    // The registers RAX, RCX, RDX are preserved across the call.
    test_cache = GenerateInlineInstanceof(token_pos, dst_type, &is_assignable,
                                          &runtime_call);

  } else {
    // TODO(dartbug.com/40813): Handle setting up the non-constant case.
    UNREACHABLE();
  }

  __ Bind(&runtime_call);
  __ PushObject(Object::null_object());  // Make room for the result.
  __ pushq(TypeTestABI::kInstanceReg);   // Push the source object.
  // Push the destination type.
  if (locs->in(1).IsConstant()) {
    __ PushObject(locs->in(1).constant());
  } else {
    // TODO(dartbug.com/40813): Handle setting up the non-constant case.
    UNREACHABLE();
  }
  __ pushq(TypeTestABI::kInstantiatorTypeArgumentsReg);
  __ pushq(TypeTestABI::kFunctionTypeArgumentsReg);
  __ PushObject(dst_name);  // Push the name of the destination.
  __ LoadUniqueObject(RAX, test_cache);
  __ pushq(RAX);
  __ PushImmediate(compiler::Immediate(Smi::RawValue(kTypeCheckFromInline)));
  GenerateRuntimeCall(token_pos, deopt_id, kTypeCheckRuntimeEntry, 7, locs);
  // Pop the parameters supplied to the runtime entry. The result of the
  // type check runtime call is the checked value.
  __ Drop(7);
  __ popq(TypeTestABI::kInstanceReg);
  __ Bind(&is_assignable);
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
  const bool use_pc_relative_call = dst_type.IsInstantiated() &&
                                    FLAG_precompiled_mode &&
                                    FLAG_use_bare_instructions;
  const Register kScratchReg =
      dst_type.IsTypeParameter() ? RSI : TypeTestABI::kDstTypeReg;

  const Register kRegToCall = use_pc_relative_call ? kNoRegister : kScratchReg;

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
      Object::null_object(), compiler::ObjectPoolBuilderEntry::kPatchable);
  const intptr_t sub_type_cache_offset =
      ObjectPool::element_offset(sub_type_cache_index) - kHeapObjectTag;
  const intptr_t dst_name_index = __ object_pool_builder().AddObject(
      dst_name, compiler::ObjectPoolBuilderEntry::kPatchable);
  ASSERT((sub_type_cache_index + 1) == dst_name_index);
  ASSERT(__ constant_pool_allowed());

  __ movq(TypeTestABI::kSubtypeTestCacheReg,
          compiler::Address(PP, sub_type_cache_offset));
  if (use_pc_relative_call) {
    __ GenerateUnRelocatedPcRelativeCall();
    AddPcRelativeTTSCallTypeTarget(dst_type);
  } else {
    __ call(compiler::FieldAddress(
        kRegToCall, AbstractType::type_test_stub_entry_point_offset()));
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
    Location value = defn->locs()->out(0);
    if (value.IsRegister()) {
      __ pushq(value.reg());
    } else if (value.IsConstant()) {
      __ PushObject(value.constant());
    } else {
      ASSERT(value.IsStackSlot());
      __ pushq(LocationToStackSlotAddress(value));
    }
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
  ASSERT(!build_method_extractor.IsNull());

  const intptr_t stub_index = __ object_pool_builder().AddObject(
      build_method_extractor, compiler::ObjectPoolBuilderEntry::kNotPatchable);
  const intptr_t function_index = __ object_pool_builder().AddObject(
      extracted_method, compiler::ObjectPoolBuilderEntry::kNotPatchable);

  // We use a custom pool register to preserve caller PP.
  Register kPoolReg = RAX;

  // RBX = extracted function
  // RDX = offset of type argument vector (or 0 if class is not generic)
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    kPoolReg = PP;
  } else {
    __ movq(kPoolReg,
            compiler::FieldAddress(CODE_REG, Code::object_pool_offset()));
  }
  __ movq(RDX, compiler::Immediate(type_arguments_field_offset));
  __ movq(RBX, compiler::FieldAddress(
                   kPoolReg, ObjectPool::element_offset(function_index)));
  __ movq(CODE_REG, compiler::FieldAddress(
                        kPoolReg, ObjectPool::element_offset(stub_index)));
  __ jmp(compiler::FieldAddress(
      CODE_REG, Code::entry_point_offset(Code::EntryKind::kUnchecked)));
}

void FlowGraphCompiler::GenerateGetterIntrinsic(intptr_t offset) {
  // TOS: return address.
  // +1 : receiver.
  // Sequence node has one return node, its input is load field node.
  __ Comment("Intrinsic Getter");
  __ movq(RAX, compiler::Address(RSP, 1 * kWordSize));
  __ movq(RAX, compiler::FieldAddress(RAX, offset));
  __ ret();
}

// NOTE: If the entry code shape changes, ReturnAddressLocator in profiler.cc
// needs to be updated to match.
void FlowGraphCompiler::EmitFrameEntry() {
  if (flow_graph().IsCompiledForOsr()) {
    const intptr_t extra_slots = ExtraStackSlotsOnOsrEntry();
    ASSERT(extra_slots >= 0);
    __ EnterOsrFrame(extra_slots * kWordSize);
  } else {
    const Function& function = parsed_function().function();
    if (CanOptimizeFunction() && function.IsOptimizable() &&
        (!is_optimizing() || may_reoptimize())) {
      __ Comment("Invocation Count Check");
      const Register function_reg = RDI;
      __ movq(function_reg,
              compiler::FieldAddress(CODE_REG, Code::owner_offset()));

      // Reoptimization of an optimized function is triggered by counting in
      // IC stubs, but not at the entry of the function.
      if (!is_optimizing()) {
        __ incl(compiler::FieldAddress(function_reg,
                                       Function::usage_counter_offset()));
      }
      __ cmpl(compiler::FieldAddress(function_reg,
                                     Function::usage_counter_offset()),
              compiler::Immediate(GetOptimizationThreshold()));
      ASSERT(function_reg == RDI);
      compiler::Label dont_optimize;
      __ j(LESS, &dont_optimize, compiler::Assembler::kNearJump);
      __ jmp(compiler::Address(THR, Thread::optimize_entry_offset()));
      __ Bind(&dont_optimize);
    }
    ASSERT(StackSize() >= 0);
    __ Comment("Enter frame");
    __ EnterDartFrame(StackSize() * kWordSize);
  }
}

void FlowGraphCompiler::EmitPrologue() {
  BeginCodeSourceRange();

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
      __ LoadObject(RAX, Object::null_object());
    }
    for (intptr_t i = 0; i < num_locals; ++i) {
      const intptr_t slot_index =
          compiler::target::frame_layout.FrameSlotForVariableIndex(-i);
      Register value_reg = slot_index == args_desc_slot ? ARGS_DESC_REG : RAX;
      __ movq(compiler::Address(RBP, slot_index * kWordSize), value_reg);
    }
  }

  EndCodeSourceRange(TokenPosition::kDartCodePrologue);
}

void FlowGraphCompiler::CompileGraph() {
  InitCompiler();

  // We have multiple entrypoints functionality which moved the frame
  // setup into the [FunctionEntryInstr] (which will set the constant pool
  // allowed bit to true).  Despite this we still have to set the
  // constant pool allowed bit to true here as well, because we can generate
  // code for [CatchEntryInstr]s, which need the pool.
  __ set_constant_pool_allowed(true);

  ASSERT(!block_order().is_empty());
  VisitBlocks();

#if defined(DEBUG)
  __ int3();
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
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions &&
      !stub.InVMIsolateHeap()) {
    __ GenerateUnRelocatedPcRelativeCall();
    AddPcRelativeCallStubTarget(stub);
  } else {
    __ Call(stub);
    AddStubCallTarget(stub);
  }
}

void FlowGraphCompiler::EmitTailCallToStub(const Code& stub) {
  ASSERT(!stub.IsNull());
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions &&
      !stub.InVMIsolateHeap()) {
    __ LeaveDartFrame();
    __ GenerateUnRelocatedPcRelativeTailCall();
    AddPcRelativeTailCallStubTarget(stub);
#if defined(DEBUG)
    __ Breakpoint();
#endif
  } else {
    __ LoadObject(CODE_REG, stub);
    __ LeaveDartFrame();
    __ jmp(compiler::FieldAddress(
        CODE_REG, compiler::target::Code::entry_point_offset()));
    AddStubCallTarget(stub);
  }
}

void FlowGraphCompiler::GeneratePatchableCall(TokenPosition token_pos,
                                              const Code& stub,
                                              PcDescriptorsLayout::Kind kind,
                                              LocationSummary* locs) {
  __ CallPatchable(stub);
  EmitCallsiteMetadata(token_pos, DeoptId::kNone, kind, locs);
}

void FlowGraphCompiler::GenerateDartCall(intptr_t deopt_id,
                                         TokenPosition token_pos,
                                         const Code& stub,
                                         PcDescriptorsLayout::Kind kind,
                                         LocationSummary* locs,
                                         Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  __ CallPatchable(stub, entry_kind);
  EmitCallsiteMetadata(token_pos, deopt_id, kind, locs);
}

void FlowGraphCompiler::GenerateStaticDartCall(intptr_t deopt_id,
                                               TokenPosition token_pos,
                                               PcDescriptorsLayout::Kind kind,
                                               LocationSummary* locs,
                                               const Function& target,
                                               Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  ASSERT(is_optimizing());
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ GenerateUnRelocatedPcRelativeCall();
    AddPcRelativeCallTarget(target, entry_kind);
    EmitCallsiteMetadata(token_pos, deopt_id, kind, locs);
  } else {
    // Call sites to the same target can share object pool entries. These
    // call sites are never patched for breakpoints: the function is deoptimized
    // and the unoptimized code with IC calls for static calls is patched
    // instead.
    const auto& stub_entry = StubCode::CallStaticFunction();
    __ CallWithEquivalence(stub_entry, target, entry_kind);
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

void FlowGraphCompiler::EmitUnoptimizedStaticCall(intptr_t size_with_type_args,
                                                  intptr_t deopt_id,
                                                  TokenPosition token_pos,
                                                  LocationSummary* locs,
                                                  const ICData& ic_data,
                                                  Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  const Code& stub =
      StubCode::UnoptimizedStaticCallEntry(ic_data.NumArgsTested());
  __ LoadObject(RBX, ic_data);
  GenerateDartCall(deopt_id, token_pos, stub,
                   PcDescriptorsLayout::kUnoptStaticCall, locs, entry_kind);
  __ Drop(size_with_type_args, RCX);
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
  __ LoadObject(RAX, edge_counters_array_);
  __ IncrementSmiField(
      compiler::FieldAddress(RAX, Array::element_offset(edge_id)), 1);
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
  __ LoadObject(RDI, parsed_function().function());
  // Load receiver into RDX.
  __ movq(RDX, compiler::Address(
                   RSP, (ic_data.SizeWithoutTypeArgs() - 1) * kWordSize));
  __ LoadUniqueObject(RBX, ic_data);
  GenerateDartCall(deopt_id, token_pos, stub, PcDescriptorsLayout::kIcCall,
                   locs, entry_kind);
  __ Drop(ic_data.SizeWithTypeArgs(), RCX);
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
  // Load receiver into RDX.
  __ movq(RDX, compiler::Address(
                   RSP, (ic_data.SizeWithoutTypeArgs() - 1) * kWordSize));
  __ LoadUniqueObject(RBX, ic_data);
  __ LoadUniqueObject(CODE_REG, stub);
  const intptr_t entry_point_offset =
      entry_kind == Code::EntryKind::kNormal
          ? Code::entry_point_offset(Code::EntryKind::kMonomorphic)
          : Code::entry_point_offset(Code::EntryKind::kMonomorphicUnchecked);
  __ call(compiler::FieldAddress(CODE_REG, entry_point_offset));
  EmitCallsiteMetadata(token_pos, deopt_id, PcDescriptorsLayout::kIcCall, locs);
  __ Drop(ic_data.SizeWithTypeArgs(), RCX);
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
  // Load receiver into RDX.
  __ movq(RDX, compiler::Address(RSP, (args_desc.Count() - 1) * kWordSize));

  // Use same code pattern as instance call so it can be parsed by code patcher.
  if (FLAG_precompiled_mode) {
    if (FLAG_use_bare_instructions) {
      // The AOT runtime will replace the slot in the object pool with the
      // entrypoint address - see clustered_snapshot.cc.
      __ LoadUniqueObject(RCX, StubCode::MegamorphicCall());
    } else {
      __ LoadUniqueObject(CODE_REG, StubCode::MegamorphicCall());
      __ movq(RCX, compiler::FieldAddress(CODE_REG,
                                          Code::entry_point_offset(
                                              Code::EntryKind::kMonomorphic)));
    }
    __ LoadUniqueObject(RBX, cache);
    __ call(RCX);
  } else {
    __ LoadUniqueObject(RBX, cache);
    __ LoadUniqueObject(CODE_REG, StubCode::MegamorphicCall());
    __ call(compiler::FieldAddress(
        CODE_REG, Code::entry_point_offset(Code::EntryKind::kMonomorphic)));
  }

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
  __ Drop(args_desc.SizeWithTypeArgs(), RCX);
}

void FlowGraphCompiler::EmitInstanceCallAOT(const ICData& ic_data,
                                            intptr_t deopt_id,
                                            TokenPosition token_pos,
                                            LocationSummary* locs,
                                            Code::EntryKind entry_kind,
                                            bool receiver_can_be_smi) {
  ASSERT(CanCallDart());
  ASSERT(entry_kind == Code::EntryKind::kNormal ||
         entry_kind == Code::EntryKind::kUnchecked);
  ASSERT(ic_data.NumArgsTested() == 1);
  const Code& initial_stub = StubCode::SwitchableCallMiss();
  const char* switchable_call_mode = "smiable";
  if (!receiver_can_be_smi) {
    switchable_call_mode = "non-smi";
    ic_data.set_receiver_cannot_be_smi(true);
  }
  const UnlinkedCall& data =
      UnlinkedCall::ZoneHandle(zone(), ic_data.AsUnlinkedCall());

  __ Comment("InstanceCallAOT (%s)", switchable_call_mode);
  __ movq(RDX, compiler::Address(
                   RSP, (ic_data.SizeWithoutTypeArgs() - 1) * kWordSize));
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    // The AOT runtime will replace the slot in the object pool with the
    // entrypoint address - see clustered_snapshot.cc.
    __ LoadUniqueObject(RCX, initial_stub);
  } else {
    const intptr_t entry_point_offset =
        entry_kind == Code::EntryKind::kNormal
            ? Code::entry_point_offset(Code::EntryKind::kMonomorphic)
            : Code::entry_point_offset(Code::EntryKind::kMonomorphicUnchecked);
    __ LoadUniqueObject(CODE_REG, initial_stub);
    __ movq(RCX, compiler::FieldAddress(CODE_REG, entry_point_offset));
  }
  __ LoadUniqueObject(RBX, data);
  __ call(RCX);

  EmitCallsiteMetadata(token_pos, deopt_id, PcDescriptorsLayout::kOther, locs);
  __ Drop(ic_data.SizeWithTypeArgs(), RCX);
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
    __ LoadObject(R10, arguments_descriptor);
  } else {
    if (!(FLAG_precompiled_mode && FLAG_use_bare_instructions)) {
      __ xorl(R10, R10);  // GC safe smi zero because of stub.
    }
  }
  // Do not use the code from the function, but let the code be patched so that
  // we can record the outgoing edges to other code.
  GenerateStaticDartCall(deopt_id, token_pos, PcDescriptorsLayout::kOther, locs,
                         function, entry_kind);
  __ Drop(size_with_type_args, RCX);
}

void FlowGraphCompiler::EmitDispatchTableCall(
    Register cid_reg,
    int32_t selector_offset,
    const Array& arguments_descriptor) {
  ASSERT(CanCallDart());
  const Register table_reg = RAX;
  ASSERT(cid_reg != table_reg);
  ASSERT(cid_reg != ARGS_DESC_REG);
  if (!arguments_descriptor.IsNull()) {
    __ LoadObject(ARGS_DESC_REG, arguments_descriptor);
  }
  const intptr_t offset = (selector_offset - DispatchTable::OriginElement()) *
                          compiler::target::kWordSize;
  __ LoadDispatchTable(table_reg);
  __ call(compiler::Address(table_reg, cid_reg, TIMES_8, offset));
}

Condition FlowGraphCompiler::EmitEqualityRegConstCompare(
    Register reg,
    const Object& obj,
    bool needs_number_check,
    TokenPosition token_pos,
    intptr_t deopt_id) {
  ASSERT(!needs_number_check || (!obj.IsMint() && !obj.IsDouble()));

  if (obj.IsSmi() && (Smi::Cast(obj).Value() == 0)) {
    ASSERT(!needs_number_check);
    __ testq(reg, reg);
    return EQUAL;
  }

  if (needs_number_check) {
    __ pushq(reg);
    __ PushObject(obj);
    if (is_optimizing()) {
      __ CallPatchable(StubCode::OptimizedIdenticalWithNumberCheck());
    } else {
      __ CallPatchable(StubCode::UnoptimizedIdenticalWithNumberCheck());
    }
    AddCurrentDescriptor(PcDescriptorsLayout::kRuntimeCall, deopt_id,
                         token_pos);
    // Stub returns result in flags (result of a cmpq, we need ZF computed).
    __ popq(reg);  // Discard constant.
    __ popq(reg);  // Restore 'reg'.
  } else {
    __ CompareObject(reg, obj);
  }
  return EQUAL;
}

Condition FlowGraphCompiler::EmitEqualityRegRegCompare(Register left,
                                                       Register right,
                                                       bool needs_number_check,
                                                       TokenPosition token_pos,
                                                       intptr_t deopt_id) {
  if (needs_number_check) {
    __ pushq(left);
    __ pushq(right);
    if (is_optimizing()) {
      __ CallPatchable(StubCode::OptimizedIdenticalWithNumberCheck());
    } else {
      __ CallPatchable(StubCode::UnoptimizedIdenticalWithNumberCheck());
    }
    AddCurrentDescriptor(PcDescriptorsLayout::kRuntimeCall, deopt_id,
                         token_pos);
    // Stub returns result in flags (result of a cmpq, we need ZF computed).
    __ popq(right);
    __ popq(left);
  } else {
    __ CompareRegisters(left, right);
  }
  return EQUAL;
}

Condition FlowGraphCompiler::EmitBoolTest(Register value,
                                          BranchLabels labels,
                                          bool invert) {
  __ Comment("BoolTest");
  __ testq(value, compiler::Immediate(
                      compiler::target::ObjectAlignment::kBoolValueMask));
  return invert ? NOT_EQUAL : EQUAL;
}

// This function must be in sync with FlowGraphCompiler::RecordSafepoint and
// FlowGraphCompiler::SlowPathEnvironmentFor.
void FlowGraphCompiler::SaveLiveRegisters(LocationSummary* locs) {
#if defined(DEBUG)
  locs->CheckWritableInputs();
  ClobberDeadTempRegisters(locs);
#endif

  // TODO(vegorov): avoid saving non-volatile registers.
  __ PushRegisters(locs->live_registers()->cpu_registers(),
                   locs->live_registers()->fpu_registers());
}

void FlowGraphCompiler::RestoreLiveRegisters(LocationSummary* locs) {
  __ PopRegisters(locs->live_registers()->cpu_registers(),
                  locs->live_registers()->fpu_registers());
}

#if defined(DEBUG)
void FlowGraphCompiler::ClobberDeadTempRegisters(LocationSummary* locs) {
  // Clobber temporaries that have not been manually preserved.
  for (intptr_t i = 0; i < locs->temp_count(); ++i) {
    Location tmp = locs->temp(i);
    // TODO(zerny): clobber non-live temporary FPU registers.
    if (tmp.IsRegister() &&
        !locs->live_registers()->ContainsRegister(tmp.reg())) {
      __ movq(tmp.reg(), compiler::Immediate(0xf7));
    }
  }
}
#endif

Register FlowGraphCompiler::EmitTestCidRegister() {
  return RDI;
}

void FlowGraphCompiler::EmitTestAndCallLoadReceiver(
    intptr_t count_without_type_args,
    const Array& arguments_descriptor) {
  __ Comment("EmitTestAndCall");
  // Load receiver into RAX.
  __ movq(RAX,
          compiler::Address(RSP, (count_without_type_args - 1) * kWordSize));
  __ LoadObject(R10, arguments_descriptor);
}

void FlowGraphCompiler::EmitTestAndCallSmiBranch(compiler::Label* label,
                                                 bool if_smi) {
  __ testq(RAX, compiler::Immediate(kSmiTagMask));
  // Jump if receiver is (not) Smi.
  __ j(if_smi ? ZERO : NOT_ZERO, label);
}

void FlowGraphCompiler::EmitTestAndCallLoadCid(Register class_id_reg) {
  ASSERT(class_id_reg != RAX);
  __ LoadClassId(class_id_reg, RAX);
}

#undef __
#define __ assembler->

int FlowGraphCompiler::EmitTestAndCallCheckCid(compiler::Assembler* assembler,
                                               compiler::Label* label,
                                               Register class_id_reg,
                                               const CidRangeValue& range,
                                               int bias,
                                               bool jump_on_miss) {
  // Note of WARNING: Due to smaller instruction encoding we use the 32-bit
  // instructions on x64, which means the compare instruction has to be
  // 32-bit (since the subtraction instruction is as well).
  intptr_t cid_start = range.cid_start;
  if (range.IsSingleCid()) {
    __ cmpl(class_id_reg, compiler::Immediate(cid_start - bias));
    __ BranchIf(jump_on_miss ? NOT_EQUAL : EQUAL, label);
  } else {
    __ addl(class_id_reg, compiler::Immediate(bias - cid_start));
    bias = cid_start;
    __ cmpl(class_id_reg, compiler::Immediate(range.Extent()));
    __ BranchIf(jump_on_miss ? UNSIGNED_GREATER : UNSIGNED_LESS_EQUAL, label);
  }
  return bias;
}

#undef __
#define __ assembler()->

void FlowGraphCompiler::EmitMove(Location destination,
                                 Location source,
                                 TemporaryRegisterAllocator* tmp) {
  if (destination.Equals(source)) return;

  if (source.IsRegister()) {
    if (destination.IsRegister()) {
      __ movq(destination.reg(), source.reg());
    } else {
      ASSERT(destination.IsStackSlot());
      __ movq(LocationToStackSlotAddress(destination), source.reg());
    }
  } else if (source.IsStackSlot()) {
    if (destination.IsRegister()) {
      __ movq(destination.reg(), LocationToStackSlotAddress(source));
    } else if (destination.IsFpuRegister()) {
      // 32-bit float
      __ movq(TMP, LocationToStackSlotAddress(source));
      __ movq(destination.fpu_reg(), TMP);
    } else {
      ASSERT(destination.IsStackSlot());
      __ MoveMemoryToMemory(LocationToStackSlotAddress(destination),
                            LocationToStackSlotAddress(source));
    }
  } else if (source.IsFpuRegister()) {
    if (destination.IsFpuRegister()) {
      // Optimization manual recommends using MOVAPS for register
      // to register moves.
      __ movaps(destination.fpu_reg(), source.fpu_reg());
    } else {
      if (destination.IsDoubleStackSlot()) {
        __ movsd(LocationToStackSlotAddress(destination), source.fpu_reg());
      } else {
        ASSERT(destination.IsQuadStackSlot());
        __ movups(LocationToStackSlotAddress(destination), source.fpu_reg());
      }
    }
  } else if (source.IsDoubleStackSlot()) {
    if (destination.IsFpuRegister()) {
      __ movsd(destination.fpu_reg(), LocationToStackSlotAddress(source));
    } else {
      ASSERT(destination.IsDoubleStackSlot() ||
             destination.IsStackSlot() /*32-bit float*/);
      __ movsd(FpuTMP, LocationToStackSlotAddress(source));
      __ movsd(LocationToStackSlotAddress(destination), FpuTMP);
    }
  } else if (source.IsQuadStackSlot()) {
    if (destination.IsFpuRegister()) {
      __ movups(destination.fpu_reg(), LocationToStackSlotAddress(source));
    } else {
      ASSERT(destination.IsQuadStackSlot());
      __ movups(FpuTMP, LocationToStackSlotAddress(source));
      __ movups(LocationToStackSlotAddress(destination), FpuTMP);
    }
  } else {
    ASSERT(!source.IsInvalid());
    ASSERT(source.IsConstant());
    if (destination.IsFpuRegister() || destination.IsDoubleStackSlot()) {
      Register scratch = tmp->AllocateTemporary();
      source.constant_instruction()->EmitMoveToLocation(this, destination,
                                                        scratch);
      tmp->ReleaseTemporary();
    } else {
      source.constant_instruction()->EmitMoveToLocation(this, destination);
    }
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
            __ movq(dst_reg, src_reg);
            return;
          case 4:
            __ movl(dst_reg, src_reg);
            return;
          default:
            UNIMPLEMENTED();
        }
      } else {
        switch (src_type.AsFundamental().representation()) {
          case compiler::ffi::kInt8:  // Sign extend operand.
            __ movsxb(dst_reg, src_reg);
            return;
          case compiler::ffi::kInt16:
            __ movsxw(dst_reg, src_reg);
            return;
          case compiler::ffi::kUint8:  // Zero extend operand.
            __ movzxb(dst_reg, src_reg);
            return;
          case compiler::ffi::kUint16:
            __ movzxw(dst_reg, src_reg);
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
      const auto dst_addr = NativeLocationToStackSlotAddress(dst);
      ASSERT(!sign_or_zero_extend);
      switch (dst_size) {
        case 8:
          __ movq(dst_addr, src_reg);
          return;
        case 4:
          __ movl(dst_addr, src_reg);
          return;
        case 2:
          __ movw(dst_addr, src_reg);
          return;
        case 1:
          __ movb(dst_addr, src_reg);
          return;
        default:
          UNREACHABLE();
      }
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
      // Optimization manual recommends using MOVAPS for register
      // to register moves.
      __ movaps(dst.fpu_reg(), src.fpu_reg());

    } else {
      ASSERT(destination.IsStack());
      ASSERT(src_type.IsFloat());
      const auto& dst = destination.AsStack();
      const auto dst_addr = NativeLocationToStackSlotAddress(dst);
      switch (dst_size) {
        case 8:
          __ movsd(dst_addr, src.fpu_reg());
          return;
        case 4:
          __ movss(dst_addr, src.fpu_reg());
          return;
        default:
          UNREACHABLE();
      }
    }

  } else {
    ASSERT(source.IsStack());
    const auto& src = source.AsStack();
    const auto src_addr = NativeLocationToStackSlotAddress(src);
    if (destination.IsRegisters()) {
      const auto& dst = destination.AsRegisters();
      ASSERT(dst.num_regs() == 1);
      const auto dst_reg = dst.reg_at(0);
      if (!sign_or_zero_extend) {
        switch (dst_size) {
          case 8:
            __ movq(dst_reg, src_addr);
            return;
          case 4:
            __ movl(dst_reg, src_addr);
            return;
          default:
            UNIMPLEMENTED();
        }
      } else {
        switch (src_type.AsFundamental().representation()) {
          case compiler::ffi::kInt8:  // Sign extend operand.
            __ movsxb(dst_reg, src_addr);
            return;
          case compiler::ffi::kInt16:
            __ movsxw(dst_reg, src_addr);
            return;
          case compiler::ffi::kUint8:  // Zero extend operand.
            __ movzxb(dst_reg, src_addr);
            return;
          case compiler::ffi::kUint16:
            __ movzxw(dst_reg, src_addr);
            return;
          default:
            // 32 to 64 bit is covered in IL by Representation conversions.
            UNIMPLEMENTED();
        }
      }

    } else if (destination.IsFpuRegisters()) {
      ASSERT(src_type.Equals(dst_type));
      ASSERT(src_type.IsFloat());
      const auto& dst = destination.AsFpuRegisters();
      switch (dst_size) {
        case 8:
          __ movsd(dst.fpu_reg(), src_addr);
          return;
        case 4:
          __ movss(dst.fpu_reg(), src_addr);
          return;
        default:
          UNREACHABLE();
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
  __ jmp(&skip_reloc);
  InsertBSSRelocation(relocation);
  const intptr_t reloc_end = __ CodeSize();
  __ Bind(&skip_reloc);

  const intptr_t kLeaqLength = 7;
  __ leaq(dst, compiler::Address::AddressRIPRelative(
                   -kLeaqLength - compiler::target::kWordSize));
  ASSERT((__ CodeSize() - reloc_end) == kLeaqLength);

  // dst holds the address of the relocation.
  __ movq(tmp, compiler::Address(dst, 0));

  // tmp holds the relocation itself: dst - bss_start.
  // dst = dst + (bss_start - dst) = bss_start
  __ addq(dst, tmp);

  // dst holds the start of the BSS section.
  // Load the routine.
  __ movq(dst, compiler::Address(dst, 0));
}

#undef __
#define __ compiler_->assembler()->

void ParallelMoveResolver::EmitSwap(int index) {
  MoveOperands* move = moves_[index];
  const Location source = move->src();
  const Location destination = move->dest();

  if (source.IsRegister() && destination.IsRegister()) {
    __ xchgq(destination.reg(), source.reg());
  } else if (source.IsRegister() && destination.IsStackSlot()) {
    Exchange(source.reg(), LocationToStackSlotAddress(destination));
  } else if (source.IsStackSlot() && destination.IsRegister()) {
    Exchange(destination.reg(), LocationToStackSlotAddress(source));
  } else if (source.IsStackSlot() && destination.IsStackSlot()) {
    Exchange(LocationToStackSlotAddress(destination),
             LocationToStackSlotAddress(source));
  } else if (source.IsFpuRegister() && destination.IsFpuRegister()) {
    __ movaps(FpuTMP, source.fpu_reg());
    __ movaps(source.fpu_reg(), destination.fpu_reg());
    __ movaps(destination.fpu_reg(), FpuTMP);
  } else if (source.IsFpuRegister() || destination.IsFpuRegister()) {
    ASSERT(destination.IsDoubleStackSlot() || destination.IsQuadStackSlot() ||
           source.IsDoubleStackSlot() || source.IsQuadStackSlot());
    bool double_width =
        destination.IsDoubleStackSlot() || source.IsDoubleStackSlot();
    XmmRegister reg =
        source.IsFpuRegister() ? source.fpu_reg() : destination.fpu_reg();
    compiler::Address slot_address =
        source.IsFpuRegister() ? LocationToStackSlotAddress(destination)
                               : LocationToStackSlotAddress(source);

    if (double_width) {
      __ movsd(FpuTMP, slot_address);
      __ movsd(slot_address, reg);
    } else {
      __ movups(FpuTMP, slot_address);
      __ movups(slot_address, reg);
    }
    __ movaps(reg, FpuTMP);
  } else if (source.IsDoubleStackSlot() && destination.IsDoubleStackSlot()) {
    const compiler::Address& source_slot_address =
        LocationToStackSlotAddress(source);
    const compiler::Address& destination_slot_address =
        LocationToStackSlotAddress(destination);

    ScratchFpuRegisterScope ensure_scratch(this, FpuTMP);
    __ movsd(FpuTMP, source_slot_address);
    __ movsd(ensure_scratch.reg(), destination_slot_address);
    __ movsd(destination_slot_address, FpuTMP);
    __ movsd(source_slot_address, ensure_scratch.reg());
  } else if (source.IsQuadStackSlot() && destination.IsQuadStackSlot()) {
    const compiler::Address& source_slot_address =
        LocationToStackSlotAddress(source);
    const compiler::Address& destination_slot_address =
        LocationToStackSlotAddress(destination);

    ScratchFpuRegisterScope ensure_scratch(this, FpuTMP);
    __ movups(FpuTMP, source_slot_address);
    __ movups(ensure_scratch.reg(), destination_slot_address);
    __ movups(destination_slot_address, FpuTMP);
    __ movups(source_slot_address, ensure_scratch.reg());
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
  __ MoveMemoryToMemory(dst, src);
}

void ParallelMoveResolver::Exchange(Register reg,
                                    const compiler::Address& mem) {
  __ Exchange(reg, mem);
}

void ParallelMoveResolver::Exchange(const compiler::Address& mem1,
                                    const compiler::Address& mem2) {
  __ Exchange(mem1, mem2);
}

void ParallelMoveResolver::Exchange(Register reg,
                                    Register base_reg,
                                    intptr_t stack_offset) {
  UNREACHABLE();
}

void ParallelMoveResolver::Exchange(Register base_reg1,
                                    intptr_t stack_offset1,
                                    Register base_reg2,
                                    intptr_t stack_offset2) {
  UNREACHABLE();
}

void ParallelMoveResolver::SpillScratch(Register reg) {
  __ pushq(reg);
}

void ParallelMoveResolver::RestoreScratch(Register reg) {
  __ popq(reg);
}

void ParallelMoveResolver::SpillFpuScratch(FpuRegister reg) {
  __ AddImmediate(RSP, compiler::Immediate(-kFpuRegisterSize));
  __ movups(compiler::Address(RSP, 0), reg);
}

void ParallelMoveResolver::RestoreFpuScratch(FpuRegister reg) {
  __ movups(reg, compiler::Address(RSP, 0));
  __ AddImmediate(RSP, compiler::Immediate(kFpuRegisterSize));
}

#undef __

}  // namespace dart

#endif  // defined(TARGET_ARCH_X64)

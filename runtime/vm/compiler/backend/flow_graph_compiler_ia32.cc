// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/compiler/backend/flow_graph_compiler.h"

#include "vm/code_patcher.h"
#include "vm/compiler/api/type_check_mode.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/frontend/flow_graph_builder.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/deopt_instructions.h"
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

void FlowGraphCompiler::ArchSpecificInitialization() {}

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

  builder->AddPcMarker(current->function(), slot_ix++);
  builder->AddCallerFp(slot_ix++);

  Environment* previous = current;
  current = current->outer();
  while (current != NULL) {
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

    builder->AddPcMarker(current->function(), slot_ix++);
    builder->AddCallerFp(slot_ix++);

    // Iterate on the outer environment.
    previous = current;
    current = current->outer();
  }
  // The previous pointer is now the outermost environment.
  ASSERT(previous != NULL);

  // For the outermost environment, set caller PC.
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
  __ pushl(CODE_REG);
  __ Call(StubCode::Deoptimize());
  set_pc_offset(assembler->CodeSize());
  __ int3();
#undef __
}

#define __ assembler()->

// Fall through if bool_register contains null.
void FlowGraphCompiler::GenerateBoolToJump(Register bool_register,
                                           compiler::Label* is_true,
                                           compiler::Label* is_false) {
  const compiler::Immediate& raw_null =
      compiler::Immediate(static_cast<intptr_t>(Object::null()));
  compiler::Label fall_through;
  __ cmpl(bool_register, raw_null);
  __ j(EQUAL, &fall_through, compiler::Assembler::kNearJump);
  BranchLabels labels = {is_true, is_false, &fall_through};
  Condition true_condition =
      EmitBoolTest(bool_register, labels, /*invert=*/false);
  ASSERT(true_condition != kInvalidCondition);
  __ j(true_condition, is_true);
  __ jmp(is_false);
  __ Bind(&fall_through);
}

// Clobbers ECX.
SubtypeTestCachePtr FlowGraphCompiler::GenerateCallSubtypeTestStub(
    TypeTestStubKind test_kind,
    Register instance_reg,
    Register instantiator_type_arguments_reg,
    Register function_type_arguments_reg,
    Register temp_reg,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  const SubtypeTestCache& type_test_cache =
      SubtypeTestCache::ZoneHandle(zone(), SubtypeTestCache::New());
  const compiler::Immediate& raw_null =
      compiler::Immediate(static_cast<intptr_t>(Object::null()));
  __ LoadObject(temp_reg, type_test_cache);
  __ pushl(temp_reg);      // Subtype test cache.
  __ pushl(instance_reg);  // Instance.
  if (test_kind == kTestTypeOneArg) {
    ASSERT(instantiator_type_arguments_reg == kNoRegister);
    ASSERT(function_type_arguments_reg == kNoRegister);
    __ pushl(raw_null);
    __ pushl(raw_null);
    __ Call(StubCode::Subtype1TestCache());
  } else if (test_kind == kTestTypeTwoArgs) {
    ASSERT(instantiator_type_arguments_reg == kNoRegister);
    ASSERT(function_type_arguments_reg == kNoRegister);
    __ pushl(raw_null);
    __ pushl(raw_null);
    __ Call(StubCode::Subtype2TestCache());
  } else if (test_kind == kTestTypeFourArgs) {
    __ pushl(instantiator_type_arguments_reg);
    __ pushl(function_type_arguments_reg);
    __ Call(StubCode::Subtype4TestCache());
  } else if (test_kind == kTestTypeSixArgs) {
    __ pushl(instantiator_type_arguments_reg);
    __ pushl(function_type_arguments_reg);
    __ Call(StubCode::Subtype6TestCache());
  } else {
    UNREACHABLE();
  }
  // Result is in ECX: null -> not found, otherwise Bool::True or Bool::False.
  ASSERT(instance_reg != ECX);
  ASSERT(temp_reg != ECX);
  __ Drop(2);
  __ popl(instance_reg);  // Restore receiver.
  __ popl(temp_reg);      // Discard.
  GenerateBoolToJump(ECX, is_instance_lbl, is_not_instance_lbl);
  return type_test_cache.raw();
}

// Jumps to labels 'is_instance' or 'is_not_instance' respectively, if
// type test is conclusive, otherwise fallthrough if a type test could not
// be completed.
// EAX: instance (must survive).
// Clobbers ECX, EDI.
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
  __ testl(TypeTestABI::kInstanceReg, compiler::Immediate(kSmiTagMask));
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
    const Register kClassIdReg = ECX;
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
  const Register kTempReg = EDI;
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
// SubtypeTestCache.
// EAX: instance to test against (preserved).
// Clobbers ECX, EDI.
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

  __ testl(TypeTestABI::kInstanceReg, compiler::Immediate(kSmiTagMask));
  // If instance is Smi, check directly.
  const Class& smi_class = Class::Handle(zone(), Smi::Class());
  if (Class::IsSubtypeOf(smi_class, Object::null_type_arguments(),
                         Nullability::kNonNullable, type, Heap::kOld)) {
    // Fast case for type = int/num/top-type.
    __ j(ZERO, is_instance_lbl);
  } else {
    __ j(ZERO, is_not_instance_lbl);
  }
  const Register kClassIdReg = ECX;
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
    __ cmpl(kClassIdReg, compiler::Immediate(kClosureCid));
    __ j(EQUAL, is_instance_lbl);
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
// EAX: instance to test.
// Clobbers EDI, ECX.
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
  __ LoadClassId(EDI, TypeTestABI::kInstanceReg);
  __ LoadClassById(ECX, EDI);
  // ECX: instance class.
  // Check immediate superclass equality. If type_class is Object, then testing
  // supertype may yield a wrong result for Null in NNBD strong mode (because
  // Null also extends Object).
  if (!type_class.IsObjectClass() || !Isolate::Current()->null_safety()) {
    __ movl(EDI, compiler::FieldAddress(ECX, Class::super_type_offset()));
    __ movl(EDI, compiler::FieldAddress(EDI, Type::type_class_id_offset()));
    __ cmpl(EDI, compiler::Immediate(Smi::RawValue(type_class.id())));
    __ j(EQUAL, is_instance_lbl);
  }

  const Register kInstantiatorTypeArgumentsReg = kNoRegister;
  const Register kFunctionTypeArgumentsReg = kNoRegister;
  const Register kTempReg = EDI;
  return GenerateCallSubtypeTestStub(kTestTypeOneArg, TypeTestABI::kInstanceReg,
                                     kInstantiatorTypeArgumentsReg,
                                     kFunctionTypeArgumentsReg, kTempReg,
                                     is_instance_lbl, is_not_instance_lbl);
}

// Generates inlined check if 'type' is a type parameter or type itself
// EAX: instance (preserved).
// Clobbers EDX, EDI, ECX.
SubtypeTestCachePtr FlowGraphCompiler::GenerateUninstantiatedTypeTest(
    TokenPosition token_pos,
    const AbstractType& type,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  __ Comment("UninstantiatedTypeTest");
  const Register kTempReg = EDI;
  ASSERT(!type.IsInstantiated());
  ASSERT(!type.IsFunctionType());
  // Skip check if destination is a dynamic type.
  const compiler::Immediate& raw_null =
      compiler::Immediate(static_cast<intptr_t>(Object::null()));
  if (type.IsTypeParameter()) {
    const TypeParameter& type_param = TypeParameter::Cast(type);

    __ movl(EDX, compiler::Address(
                     ESP, 1 * kWordSize));  // Get instantiator type args.
    __ movl(ECX,
            compiler::Address(ESP, 0 * kWordSize));  // Get function type args.
    // EDX: instantiator type arguments.
    // ECX: function type arguments.
    const Register kTypeArgumentsReg =
        type_param.IsClassTypeParameter()
            ? TypeTestABI::kInstantiatorTypeArgumentsReg
            : TypeTestABI::kFunctionTypeArgumentsReg;
    // Check if type arguments are null, i.e. equivalent to vector of dynamic.
    __ cmpl(kTypeArgumentsReg, raw_null);
    __ j(EQUAL, is_instance_lbl);
    __ movl(EDI, compiler::FieldAddress(
                     kTypeArgumentsReg,
                     TypeArguments::type_at_offset(type_param.index())));
    // EDI: concrete type of type.
    // Check if type argument is dynamic, Object?, or void.
    __ CompareObject(EDI, Object::dynamic_type());
    __ j(EQUAL, is_instance_lbl);
    __ CompareObject(
        EDI, Type::ZoneHandle(
                 zone(), isolate()->object_store()->nullable_object_type()));
    __ j(EQUAL, is_instance_lbl);
    __ CompareObject(EDI, Object::void_type());
    __ j(EQUAL, is_instance_lbl);

    // For Smi check quickly against int and num interfaces.
    compiler::Label not_smi;
    __ testl(EAX, compiler::Immediate(kSmiTagMask));  // Value is Smi?
    __ j(NOT_ZERO, &not_smi, compiler::Assembler::kNearJump);
    __ CompareObject(EDI, Type::ZoneHandle(zone(), Type::IntType()));
    __ j(EQUAL, is_instance_lbl);
    __ CompareObject(EDI, Type::ZoneHandle(zone(), Type::Number()));
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
      __ testl(TypeTestABI::kInstanceReg,
               compiler::Immediate(kSmiTagMask));  // Is instance Smi?
      __ j(ZERO, is_not_instance_lbl);
    }
    __ movl(TypeTestABI::kInstantiatorTypeArgumentsReg,
            compiler::Address(ESP, 1 * kWordSize));
    __ movl(TypeTestABI::kFunctionTypeArgumentsReg,
            compiler::Address(ESP, 0 * kWordSize));
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
  __ Comment("FunctionTypeTest");

  __ testl(TypeTestABI::kInstanceReg, compiler::Immediate(kSmiTagMask));
  __ j(ZERO, is_not_instance_lbl);
  // Uninstantiated type class is known at compile time, but the type
  // arguments are determined at runtime by the instantiator(s).
  const Register kTempReg = EDI;
  return GenerateCallSubtypeTestStub(
      kTestTypeSixArgs, TypeTestABI::kInstanceReg,
      TypeTestABI::kInstantiatorTypeArgumentsReg,
      TypeTestABI::kFunctionTypeArgumentsReg, kTempReg, is_instance_lbl,
      is_not_instance_lbl);
}

// Inputs:
// - EAX: instance to test against (preserved).
// - EDX: optional instantiator type arguments (preserved).
// - ECX: optional function type arguments (preserved).
// Clobbers EDI.
// Returns:
// - preserved instance in EAX, optional instantiator type arguments in EDX, and
//   optional function type arguments in RCX.
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
// - EAX: object.
// - EDX: instantiator type arguments or raw_null.
// - ECX: function type arguments or raw_null.
// Returns:
// - true or false in EAX.
void FlowGraphCompiler::GenerateInstanceOf(TokenPosition token_pos,
                                           intptr_t deopt_id,
                                           const AbstractType& type,
                                           LocationSummary* locs) {
  ASSERT(type.IsFinalized());
  ASSERT(!type.IsTopTypeForInstanceOf());  // Already checked.

  __ pushl(EDX);  // Store instantiator type arguments.
  __ pushl(ECX);  // Store function type arguments.

  const compiler::Immediate& raw_null =
      compiler::Immediate(static_cast<intptr_t>(Object::null()));
  compiler::Label is_instance, is_not_instance;
  // 'null' is an instance of Null, Object*, Never*, void, and dynamic.
  // In addition, 'null' is an instance of any nullable type.
  // It is also an instance of FutureOr<T> if it is an instance of T.
  const AbstractType& unwrapped_type =
      AbstractType::Handle(type.UnwrapFutureOr());
  if (!unwrapped_type.IsTypeParameter() || unwrapped_type.IsNullable()) {
    // Only nullable type parameter remains nullable after instantiation.
    // See NullIsInstanceOf().
    __ cmpl(EAX, raw_null);
    __ j(EQUAL, (unwrapped_type.IsNullable() ||
                 (unwrapped_type.IsLegacy() && unwrapped_type.IsNeverType()))
                    ? &is_instance
                    : &is_not_instance);
  }

  // Generate inline instanceof test.
  SubtypeTestCache& test_cache = SubtypeTestCache::ZoneHandle(zone());
  test_cache =
      GenerateInlineInstanceof(token_pos, type, &is_instance, &is_not_instance);

  // test_cache is null if there is no fall-through.
  compiler::Label done;
  if (!test_cache.IsNull()) {
    // Generate runtime call.
    __ movl(EDX, compiler::Address(
                     ESP, 1 * kWordSize));  // Get instantiator type args.
    __ movl(ECX,
            compiler::Address(ESP, 0 * kWordSize));  // Get function type args.
    __ PushObject(Object::null_object());  // Make room for the result.
    __ pushl(EAX);                         // Push the instance.
    __ PushObject(type);                   // Push the type.
    __ pushl(TypeTestABI::kInstantiatorTypeArgumentsReg);
    __ pushl(TypeTestABI::kFunctionTypeArgumentsReg);
    __ LoadObject(EAX, test_cache);
    __ pushl(EAX);
    GenerateRuntimeCall(token_pos, deopt_id, kInstanceofRuntimeEntry, 5, locs);
    // Pop the parameters supplied to the runtime entry. The result of the
    // instanceof runtime call will be left as the result of the operation.
    __ Drop(5);
    __ popl(EAX);
    __ jmp(&done, compiler::Assembler::kNearJump);
  }
  __ Bind(&is_not_instance);
  __ LoadObject(EAX, Bool::Get(false));
  __ jmp(&done, compiler::Assembler::kNearJump);

  __ Bind(&is_instance);
  __ LoadObject(EAX, Bool::Get(true));
  __ Bind(&done);
  __ popl(ECX);  // Remove pushed function type arguments.
  __ popl(EDX);  // Remove pushed instantiator type arguments.
}

// Optimize assignable type check by adding inlined tests for:
// - NULL -> return NULL.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs:
// - EAX: object.
// - EBX: destination type (if non-constant).
// - EDX: instantiator type arguments or raw_null.
// - ECX: function type arguments or raw_null.
// Returns:
// - object in EAX for successful assignable check (or throws TypeError).
// Performance notes: positive checks must be quick, negative checks can be slow
// as they throw an exception.
void FlowGraphCompiler::GenerateAssertAssignable(CompileType* receiver_type,
                                                 TokenPosition token_pos,
                                                 intptr_t deopt_id,
                                                 const String& dst_name,
                                                 LocationSummary* locs) {
  ASSERT(!token_pos.IsClassifying());
  ASSERT(CheckAssertAssignableTypeTestingABILocations(*locs));

  if (!locs->in(1).IsConstant()) {
    // TODO(dartbug.com/40813): Handle setting up the non-constant case.
    UNREACHABLE();
  }

  ASSERT(locs->in(1).constant().IsAbstractType());
  const auto& dst_type = AbstractType::Cast(locs->in(1).constant());
  ASSERT(dst_type.IsFinalized());

  if (dst_type.IsTopTypeForSubtyping()) return;  // No code needed.

  __ pushl(TypeTestABI::kInstantiatorTypeArgumentsReg);
  __ pushl(TypeTestABI::kFunctionTypeArgumentsReg);

  compiler::Label is_assignable, runtime_call;
  if (Instance::NullIsAssignableTo(dst_type)) {
    const compiler::Immediate& raw_null =
        compiler::Immediate(static_cast<intptr_t>(Object::null()));
    __ cmpl(TypeTestABI::kInstanceReg, raw_null);
    __ j(EQUAL, &is_assignable);
  }

  // Generate inline type check, linking to runtime call if not assignable.
  SubtypeTestCache& test_cache = SubtypeTestCache::ZoneHandle(zone());
  test_cache = GenerateInlineInstanceof(token_pos, dst_type, &is_assignable,
                                        &runtime_call);

  __ Bind(&runtime_call);
  __ movl(
      TypeTestABI::kInstantiatorTypeArgumentsReg,
      compiler::Address(ESP, 1 * kWordSize));  // Get instantiator type args.
  __ movl(TypeTestABI::kFunctionTypeArgumentsReg,
          compiler::Address(ESP, 0 * kWordSize));  // Get function type args.
  __ PushObject(Object::null_object());            // Make room for the result.
  __ pushl(TypeTestABI::kInstanceReg);             // Push the source object.
  if (locs->in(1).IsConstant()) {
    __ PushObject(locs->in(1).constant());  // Push the type of the destination.
  } else {
    // TODO(dartbug.com/40813): Handle setting up the non-constant case.
    UNREACHABLE();
  }
  __ pushl(TypeTestABI::kInstantiatorTypeArgumentsReg);
  __ pushl(TypeTestABI::kFunctionTypeArgumentsReg);
  __ PushObject(dst_name);  // Push the name of the destination.
  __ LoadObject(EAX, test_cache);
  __ pushl(EAX);
  __ PushObject(Smi::ZoneHandle(zone(), Smi::New(kTypeCheckFromInline)));
  GenerateRuntimeCall(token_pos, deopt_id, kTypeCheckRuntimeEntry, 7, locs);
  // Pop the parameters supplied to the runtime entry. The result of the
  // type check runtime call is the checked value.
  __ Drop(7);
  __ popl(TypeTestABI::kInstanceReg);

  __ Bind(&is_assignable);
  __ popl(TypeTestABI::kFunctionTypeArgumentsReg);
  __ popl(TypeTestABI::kInstantiatorTypeArgumentsReg);
}

void FlowGraphCompiler::EmitInstructionEpilogue(Instruction* instr) {
  if (is_optimizing()) {
    return;
  }
  Definition* defn = instr->AsDefinition();
  if ((defn != NULL) && defn->HasTemp()) {
    Location value = defn->locs()->out(0);
    if (value.IsRegister()) {
      __ pushl(value.reg());
    } else if (value.IsConstant()) {
      __ PushObject(value.constant());
    } else {
      ASSERT(value.IsStackSlot());
      __ pushl(LocationToStackSlotAddress(value));
    }
  }
}

void FlowGraphCompiler::GenerateGetterIntrinsic(intptr_t offset) {
  // TOS: return address.
  // +1 : receiver.
  // Sequence node has one return node, its input is load field node.
  __ Comment("Intrinsic Getter");
  __ movl(EAX, compiler::Address(ESP, 1 * kWordSize));
  __ movl(EAX, compiler::FieldAddress(EAX, offset));
  __ ret();
}

// NOTE: If the entry code shape changes, ReturnAddressLocator in profiler.cc
// needs to be updated to match.
void FlowGraphCompiler::EmitFrameEntry() {
  const Function& function = parsed_function().function();
  if (CanOptimizeFunction() && function.IsOptimizable() &&
      (!is_optimizing() || may_reoptimize())) {
    __ Comment("Invocation Count Check");
    const Register function_reg = EBX;
    __ LoadObject(function_reg, function);

    // Reoptimization of an optimized function is triggered by counting in
    // IC stubs, but not at the entry of the function.
    if (!is_optimizing()) {
      __ incl(compiler::FieldAddress(function_reg,
                                     Function::usage_counter_offset()));
    }
    __ cmpl(
        compiler::FieldAddress(function_reg, Function::usage_counter_offset()),
        compiler::Immediate(GetOptimizationThreshold()));
    ASSERT(function_reg == EBX);
    compiler::Label dont_optimize;
    __ j(LESS, &dont_optimize, compiler::Assembler::kNearJump);
    __ jmp(compiler::Address(THR, Thread::optimize_entry_offset()));
    __ Bind(&dont_optimize);
  }
  __ Comment("Enter frame");
  if (flow_graph().IsCompiledForOsr()) {
    intptr_t extra_slots = ExtraStackSlotsOnOsrEntry();
    ASSERT(extra_slots >= 0);
    __ EnterOsrFrame(extra_slots * kWordSize);
  } else {
    ASSERT(StackSize() >= 0);
    __ EnterDartFrame(StackSize() * kWordSize);
  }
}

void FlowGraphCompiler::EmitPrologue() {
  EmitFrameEntry();

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
      const compiler::Immediate& raw_null =
          compiler::Immediate(static_cast<intptr_t>(Object::null()));
      __ movl(EAX, raw_null);
    }
    for (intptr_t i = 0; i < num_locals; ++i) {
      const intptr_t slot_index =
          compiler::target::frame_layout.FrameSlotForVariableIndex(-i);
      Register value_reg = slot_index == args_desc_slot ? ARGS_DESC_REG : EAX;
      __ movl(compiler::Address(EBP, slot_index * kWordSize), value_reg);
    }
  }

  EndCodeSourceRange(TokenPosition::kDartCodePrologue);
}

void FlowGraphCompiler::CompileGraph() {
  InitCompiler();

  ASSERT(!block_order().is_empty());
  VisitBlocks();

  if (!skip_body_compilation()) {
#if defined(DEBUG)
    __ int3();
#endif
    GenerateDeferredCode();
  }

  for (intptr_t i = 0; i < indirect_gotos_.length(); ++i) {
    indirect_gotos_[i]->ComputeOffsetTable(this);
  }
}

void FlowGraphCompiler::EmitCallToStub(const Code& stub) {
  __ Call(stub);
  AddStubCallTarget(stub);
}

void FlowGraphCompiler::GenerateDartCall(intptr_t deopt_id,
                                         TokenPosition token_pos,
                                         const Code& stub,
                                         PcDescriptorsLayout::Kind kind,
                                         LocationSummary* locs,
                                         Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  __ Call(stub, /*moveable_target=*/false, entry_kind);
  EmitCallsiteMetadata(token_pos, deopt_id, kind, locs);
}

void FlowGraphCompiler::GenerateStaticDartCall(intptr_t deopt_id,
                                               TokenPosition token_pos,
                                               PcDescriptorsLayout::Kind kind,
                                               LocationSummary* locs,
                                               const Function& target,
                                               Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  const auto& stub = StubCode::CallStaticFunction();
  __ Call(stub, /*movable_target=*/true, entry_kind);
  EmitCallsiteMetadata(token_pos, deopt_id, kind, locs);
  AddStaticCallTarget(target, entry_kind);
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
  __ LoadObject(ECX, ic_data);
  GenerateDartCall(deopt_id, token_pos, stub,
                   PcDescriptorsLayout::kUnoptStaticCall, locs, entry_kind);
  __ Drop(size_with_type_args);
}

void FlowGraphCompiler::EmitEdgeCounter(intptr_t edge_id) {
  // We do not check for overflow when incrementing the edge counter.  The
  // function should normally be optimized long before the counter can
  // overflow; and though we do not reset the counters when we optimize or
  // deoptimize, there is a bound on the number of
  // optimization/deoptimization cycles we will attempt.
  ASSERT(!edge_counters_array_.IsNull());
  __ Comment("Edge counter");
  __ LoadObject(EAX, edge_counters_array_);
  __ IncrementSmiField(
      compiler::FieldAddress(EAX, Array::element_offset(edge_id)), 1);
}

void FlowGraphCompiler::EmitOptimizedInstanceCall(const Code& stub,
                                                  const ICData& ic_data,
                                                  intptr_t deopt_id,
                                                  TokenPosition token_pos,
                                                  LocationSummary* locs,
                                                  Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  ASSERT(Array::Handle(ic_data.arguments_descriptor()).Length() > 0);
  // Each ICData propagated from unoptimized to optimized code contains the
  // function that corresponds to the Dart function of that IC call. Due
  // to inlining in optimized code, that function may not correspond to the
  // top-level function (parsed_function().function()) which could be
  // reoptimized and which counter needs to be incremented.
  // Pass the function explicitly, it is used in IC stub.
  __ LoadObject(EAX, parsed_function().function());
  // Load receiver into EBX.
  __ movl(EBX, compiler::Address(
                   ESP, (ic_data.SizeWithoutTypeArgs() - 1) * kWordSize));
  __ LoadObject(ECX, ic_data);
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
  ASSERT(Array::Handle(ic_data.arguments_descriptor()).Length() > 0);
  // Load receiver into EBX.
  __ movl(EBX, compiler::Address(
                   ESP, (ic_data.SizeWithoutTypeArgs() - 1) * kWordSize));
  __ LoadObject(ECX, ic_data, true);
  __ LoadObject(CODE_REG, stub, true);
  const intptr_t entry_point_offset =
      entry_kind == Code::EntryKind::kNormal
          ? Code::entry_point_offset(Code::EntryKind::kMonomorphic)
          : Code::entry_point_offset(Code::EntryKind::kMonomorphicUnchecked);
  __ call(compiler::FieldAddress(CODE_REG, entry_point_offset));
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
  // Load receiver into EBX.
  __ movl(EBX, compiler::Address(ESP, (args_desc.Count() - 1) * kWordSize));
  __ LoadObject(ECX, cache, true);
  __ LoadObject(CODE_REG, StubCode::MegamorphicCall(), true);
  __ call(compiler::FieldAddress(
      CODE_REG, Code::entry_point_offset(Code::EntryKind::kMonomorphic)));

  AddCurrentDescriptor(PcDescriptorsLayout::kOther, DeoptId::kNone, token_pos);
  RecordSafepoint(locs, slow_path_argument_count);
  const intptr_t deopt_id_after = DeoptId::ToDeoptAfter(deopt_id);
  // Precompilation not implemented on ia32 platform.
  ASSERT(!FLAG_precompiled_mode);
  if (is_optimizing()) {
    AddDeoptIndexAtCall(deopt_id_after);
  } else {
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
  // Only generated with precompilation.
  UNREACHABLE();
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
  if (function.HasOptionalParameters() || function.IsGeneric()) {
    __ LoadObject(EDX, arguments_descriptor);
  } else {
    __ xorl(EDX, EDX);  // GC safe smi zero because of stub.
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
  // Only generated with precompilation.
  UNREACHABLE();
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
    __ testl(reg, reg);
    return EQUAL;
  }

  if (needs_number_check) {
    __ pushl(reg);
    __ PushObject(obj);
    if (is_optimizing()) {
      __ Call(StubCode::OptimizedIdenticalWithNumberCheck());
    } else {
      __ Call(StubCode::UnoptimizedIdenticalWithNumberCheck());
    }
    AddCurrentDescriptor(PcDescriptorsLayout::kRuntimeCall, deopt_id,
                         token_pos);
    // Stub returns result in flags (result of a cmpl, we need ZF computed).
    __ popl(reg);  // Discard constant.
    __ popl(reg);  // Restore 'reg'.
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
    __ pushl(left);
    __ pushl(right);
    if (is_optimizing()) {
      __ Call(StubCode::OptimizedIdenticalWithNumberCheck());
    } else {
      __ Call(StubCode::UnoptimizedIdenticalWithNumberCheck());
    }
    AddCurrentDescriptor(PcDescriptorsLayout::kRuntimeCall, deopt_id,
                         token_pos);
    // Stub returns result in flags (result of a cmpl, we need ZF computed).
    __ popl(right);
    __ popl(left);
  } else {
    __ cmpl(left, right);
  }
  return EQUAL;
}

Condition FlowGraphCompiler::EmitBoolTest(Register value,
                                          BranchLabels labels,
                                          bool invert) {
  __ Comment("BoolTest");
  __ testl(value, compiler::Immediate(
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

  // TODO(vegorov): consider saving only caller save (volatile) registers.
  const intptr_t xmm_regs_count = locs->live_registers()->FpuRegisterCount();
  if (xmm_regs_count > 0) {
    __ subl(ESP, compiler::Immediate(xmm_regs_count * kFpuRegisterSize));
    // Store XMM registers with the lowest register number at the lowest
    // address.
    intptr_t offset = 0;
    for (intptr_t i = 0; i < kNumberOfXmmRegisters; ++i) {
      XmmRegister xmm_reg = static_cast<XmmRegister>(i);
      if (locs->live_registers()->ContainsFpuRegister(xmm_reg)) {
        __ movups(compiler::Address(ESP, offset), xmm_reg);
        offset += kFpuRegisterSize;
      }
    }
    ASSERT(offset == (xmm_regs_count * kFpuRegisterSize));
  }

  // The order in which the registers are pushed must match the order
  // in which the registers are encoded in the safe point's stack map.
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; --i) {
    Register reg = static_cast<Register>(i);
    if (locs->live_registers()->ContainsRegister(reg)) {
      __ pushl(reg);
    }
  }
}

void FlowGraphCompiler::RestoreLiveRegisters(LocationSummary* locs) {
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
    Register reg = static_cast<Register>(i);
    if (locs->live_registers()->ContainsRegister(reg)) {
      __ popl(reg);
    }
  }

  const intptr_t xmm_regs_count = locs->live_registers()->FpuRegisterCount();
  if (xmm_regs_count > 0) {
    // XMM registers have the lowest register number at the lowest address.
    intptr_t offset = 0;
    for (intptr_t i = 0; i < kNumberOfXmmRegisters; ++i) {
      XmmRegister xmm_reg = static_cast<XmmRegister>(i);
      if (locs->live_registers()->ContainsFpuRegister(xmm_reg)) {
        __ movups(xmm_reg, compiler::Address(ESP, offset));
        offset += kFpuRegisterSize;
      }
    }
    ASSERT(offset == (xmm_regs_count * kFpuRegisterSize));
    __ addl(ESP, compiler::Immediate(offset));
  }
}

#if defined(DEBUG)
void FlowGraphCompiler::ClobberDeadTempRegisters(LocationSummary* locs) {
  // Clobber temporaries that have not been manually preserved.
  for (intptr_t i = 0; i < locs->temp_count(); ++i) {
    Location tmp = locs->temp(i);
    // TODO(zerny): clobber non-live temporary FPU registers.
    if (tmp.IsRegister() &&
        !locs->live_registers()->ContainsRegister(tmp.reg())) {
      __ movl(tmp.reg(), compiler::Immediate(0xf7));
    }
  }
}
#endif

Register FlowGraphCompiler::EmitTestCidRegister() {
  return EDI;
}

void FlowGraphCompiler::EmitTestAndCallLoadReceiver(
    intptr_t count_without_type_args,
    const Array& arguments_descriptor) {
  __ Comment("EmitTestAndCall");
  // Load receiver into EAX.
  __ movl(EAX,
          compiler::Address(ESP, (count_without_type_args - 1) * kWordSize));
  __ LoadObject(EDX, arguments_descriptor);
}

void FlowGraphCompiler::EmitTestAndCallSmiBranch(compiler::Label* label,
                                                 bool if_smi) {
  __ testl(EAX, compiler::Immediate(kSmiTagMask));
  // Jump if receiver is (not) Smi.
  __ j(if_smi ? ZERO : NOT_ZERO, label);
}

void FlowGraphCompiler::EmitTestAndCallLoadCid(Register class_id_reg) {
  ASSERT(class_id_reg != EAX);
  __ LoadClassId(class_id_reg, EAX);
}

#undef __
#define __ assembler->

int FlowGraphCompiler::EmitTestAndCallCheckCid(compiler::Assembler* assembler,
                                               compiler::Label* label,
                                               Register class_id_reg,
                                               const CidRangeValue& range,
                                               int bias,
                                               bool jump_on_miss) {
  intptr_t cid_start = range.cid_start;
  if (range.IsSingleCid()) {
    __ cmpl(class_id_reg, compiler::Immediate(cid_start - bias));
    __ j(jump_on_miss ? NOT_EQUAL : EQUAL, label);
  } else {
    __ addl(class_id_reg, compiler::Immediate(bias - cid_start));
    bias = cid_start;
    __ cmpl(class_id_reg, compiler::Immediate(range.Extent()));
    __ j(jump_on_miss ? ABOVE : BELOW_EQUAL, label);  // Unsigned higher.
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
      __ movl(destination.reg(), source.reg());
    } else {
      ASSERT(destination.IsStackSlot());
      __ movl(LocationToStackSlotAddress(destination), source.reg());
    }
  } else if (source.IsStackSlot()) {
    if (destination.IsRegister()) {
      __ movl(destination.reg(), LocationToStackSlotAddress(source));
    } else if (destination.IsFpuRegister()) {
      // 32-bit float
      __ movss(destination.fpu_reg(), LocationToStackSlotAddress(source));
    } else {
      ASSERT(destination.IsStackSlot());
      Register scratch = tmp->AllocateTemporary();
      __ MoveMemoryToMemory(LocationToStackSlotAddress(destination),
                            LocationToStackSlotAddress(source), scratch);
      tmp->ReleaseTemporary();
    }
  } else if (source.IsFpuRegister()) {
    if (destination.IsFpuRegister()) {
      // Optimization manual recommends using MOVAPS for register
      // to register moves.
      __ movaps(destination.fpu_reg(), source.fpu_reg());
    } else {
      if (destination.IsDoubleStackSlot()) {
        __ movsd(LocationToStackSlotAddress(destination), source.fpu_reg());
      } else if (destination.IsStackSlot()) {
        // 32-bit float
        __ movss(LocationToStackSlotAddress(destination), source.fpu_reg());
      } else {
        ASSERT(destination.IsQuadStackSlot());
        __ movups(LocationToStackSlotAddress(destination), source.fpu_reg());
      }
    }
  } else if (source.IsDoubleStackSlot()) {
    if (destination.IsFpuRegister()) {
      __ movsd(destination.fpu_reg(), LocationToStackSlotAddress(source));
    } else if (destination.IsStackSlot()) {
      // Source holds a 32-bit float, take only the lower 32-bits
      __ movss(FpuTMP, LocationToStackSlotAddress(source));
      __ movss(LocationToStackSlotAddress(destination), FpuTMP);
    } else {
      ASSERT(destination.IsDoubleStackSlot());
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
  } else if (source.IsPairLocation()) {
    ASSERT(destination.IsPairLocation());
    for (intptr_t i : {0, 1}) {
      EmitMove(destination.Component(i), source.Component(i), tmp);
    }
  } else {
    ASSERT(source.IsConstant());
    source.constant_instruction()->EmitMoveToLocation(this, destination);
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
    ASSERT(src_size <= 4);
    const auto src_reg = src.reg_at(0);

    if (destination.IsRegisters()) {
      const auto& dst = destination.AsRegisters();
      ASSERT(dst.num_regs() == 1);
      const auto dst_reg = dst.reg_at(0);
      if (!sign_or_zero_extend) {
        ASSERT(dst_size == 4);
        __ movl(dst_reg, src_reg);
      } else {
        switch (src_type.AsFundamental().representation()) {
          case compiler::ffi::kInt8:  // Sign extend operand.
            __ movsxb(dst_reg, ByteRegisterOf(src_reg));
            return;
          case compiler::ffi::kInt16:
            __ movsxw(dst_reg, src_reg);
            return;
          case compiler::ffi::kUint8:  // Zero extend operand.
            __ movzxb(dst_reg, ByteRegisterOf(src_reg));
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
      ASSERT(!sign_or_zero_extend);
      const auto& dst = destination.AsStack();
      const auto dst_addr = NativeLocationToStackSlotAddress(dst);
      switch (dst_size) {
        case 4:
          __ movl(dst_addr, src_reg);
          return;
        case 2:
          __ movw(dst_addr, src_reg);
          return;
        case 1:
          __ movb(dst_addr, ByteRegisterOf(src_reg));
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
      ASSERT(dst_size <= 4);
      const auto dst_reg = dst.reg_at(0);
      if (!sign_or_zero_extend) {
        ASSERT(dst_size == 4);
        __ movl(dst_reg, src_addr);
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

#undef __
#define __ compiler_->assembler()->

void ParallelMoveResolver::EmitSwap(int index) {
  MoveOperands* move = moves_[index];
  const Location source = move->src();
  const Location destination = move->dest();

  if (source.IsRegister() && destination.IsRegister()) {
    __ xchgl(destination.reg(), source.reg());
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
    const compiler::Address& slot_address =
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
  ScratchRegisterScope ensure_scratch(this, kNoRegister);
  __ MoveMemoryToMemory(dst, src, ensure_scratch.reg());
}

void ParallelMoveResolver::Exchange(Register reg,
                                    const compiler::Address& mem) {
  ScratchRegisterScope ensure_scratch(this, reg);
  __ movl(ensure_scratch.reg(), mem);
  __ movl(mem, reg);
  __ movl(reg, ensure_scratch.reg());
}

void ParallelMoveResolver::Exchange(const compiler::Address& mem1,
                                    const compiler::Address& mem2) {
  ScratchRegisterScope ensure_scratch1(this, kNoRegister);
  ScratchRegisterScope ensure_scratch2(this, ensure_scratch1.reg());
  __ movl(ensure_scratch1.reg(), mem1);
  __ movl(ensure_scratch2.reg(), mem2);
  __ movl(mem2, ensure_scratch1.reg());
  __ movl(mem1, ensure_scratch2.reg());
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
  __ pushl(reg);
}

void ParallelMoveResolver::RestoreScratch(Register reg) {
  __ popl(reg);
}

void ParallelMoveResolver::SpillFpuScratch(FpuRegister reg) {
  __ subl(ESP, compiler::Immediate(kFpuRegisterSize));
  __ movups(compiler::Address(ESP, 0), reg);
}

void ParallelMoveResolver::RestoreFpuScratch(FpuRegister reg) {
  __ movups(reg, compiler::Address(ESP, 0));
  __ addl(ESP, compiler::Immediate(kFpuRegisterSize));
}

#undef __

}  // namespace dart

#endif  // defined(TARGET_ARCH_IA32)

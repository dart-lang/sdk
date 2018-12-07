// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32) && !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/backend/flow_graph_compiler.h"

#include "vm/code_patcher.h"
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

RawTypedData* CompilerDeoptInfo::CreateDeoptInfo(FlowGraphCompiler* compiler,
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
  Assembler* assembler = compiler->assembler();
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
                                           Label* is_true,
                                           Label* is_false) {
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label fall_through;
  __ cmpl(bool_register, raw_null);
  __ j(EQUAL, &fall_through, Assembler::kNearJump);
  __ CompareObject(bool_register, Bool::True());
  __ j(EQUAL, is_true);
  __ jmp(is_false);
  __ Bind(&fall_through);
}

// Clobbers ECX.
RawSubtypeTestCache* FlowGraphCompiler::GenerateCallSubtypeTestStub(
    TypeTestStubKind test_kind,
    Register instance_reg,
    Register instantiator_type_arguments_reg,
    Register function_type_arguments_reg,
    Register temp_reg,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  const SubtypeTestCache& type_test_cache =
      SubtypeTestCache::ZoneHandle(zone(), SubtypeTestCache::New());
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
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
RawSubtypeTestCache*
FlowGraphCompiler::GenerateInstantiatedTypeWithArgumentsTest(
    TokenPosition token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  __ Comment("InstantiatedTypeWithArgumentsTest");
  ASSERT(type.IsInstantiated());
  ASSERT(!type.IsFunctionType());
  const Class& type_class = Class::ZoneHandle(zone(), type.type_class());
  ASSERT(type_class.NumTypeArguments() > 0);
  const Register kInstanceReg = EAX;
  Error& bound_error = Error::Handle(zone());
  const Type& smi_type = Type::Handle(zone(), Type::SmiType());
  const bool smi_is_ok =
      smi_type.IsSubtypeOf(type, &bound_error, NULL, Heap::kOld);
  // Malformed type should have been handled at graph construction time.
  ASSERT(smi_is_ok || bound_error.IsNull());
  __ testl(kInstanceReg, Immediate(kSmiTagMask));
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
    __ LoadClassId(kClassIdReg, kInstanceReg);
    __ cmpl(kClassIdReg, Immediate(type_class.id()));
    __ j(EQUAL, is_instance_lbl);
    // List is a very common case.
    if (IsListClass(type_class)) {
      GenerateListTypeCheck(kClassIdReg, is_instance_lbl);
    }
    return GenerateSubtype1TestCacheLookup(
        token_pos, type_class, is_instance_lbl, is_not_instance_lbl);
  }
  // If one type argument only, check if type argument is Object or dynamic.
  if (type_arguments.Length() == 1) {
    const AbstractType& tp_argument =
        AbstractType::ZoneHandle(zone(), type_arguments.TypeAt(0));
    ASSERT(!tp_argument.IsMalformed());
    if (tp_argument.IsType()) {
      // Check if type argument is dynamic, Object, or void.
      const Type& object_type = Type::Handle(zone(), Type::ObjectType());
      if (object_type.IsSubtypeOf(tp_argument, NULL, NULL, Heap::kOld)) {
        // Instance class test only necessary.
        return GenerateSubtype1TestCacheLookup(
            token_pos, type_class, is_instance_lbl, is_not_instance_lbl);
      }
    }
  }
  // Regular subtype test cache involving instance's type arguments.
  const Register kInstantiatorTypeArgumentsReg = kNoRegister;
  const Register kFunctionTypeArgumentsReg = kNoRegister;
  const Register kTempReg = EDI;
  return GenerateCallSubtypeTestStub(kTestTypeTwoArgs, kInstanceReg,
                                     kInstantiatorTypeArgumentsReg,
                                     kFunctionTypeArgumentsReg, kTempReg,
                                     is_instance_lbl, is_not_instance_lbl);
}

void FlowGraphCompiler::CheckClassIds(Register class_id_reg,
                                      const GrowableArray<intptr_t>& class_ids,
                                      Label* is_equal_lbl,
                                      Label* is_not_equal_lbl) {
  for (intptr_t i = 0; i < class_ids.length(); i++) {
    __ cmpl(class_id_reg, Immediate(class_ids[i]));
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
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  __ Comment("InstantiatedTypeNoArgumentsTest");
  ASSERT(type.IsInstantiated());
  ASSERT(!type.IsFunctionType());
  const Class& type_class = Class::Handle(zone(), type.type_class());
  ASSERT(type_class.NumTypeArguments() == 0);

  const Register kInstanceReg = EAX;
  __ testl(kInstanceReg, Immediate(kSmiTagMask));
  // If instance is Smi, check directly.
  const Class& smi_class = Class::Handle(zone(), Smi::Class());
  if (smi_class.IsSubtypeOf(Object::null_type_arguments(), type_class,
                            Object::null_type_arguments(), NULL, NULL,
                            Heap::kOld)) {
    // Fast case for type = int/num/top-type.
    __ j(ZERO, is_instance_lbl);
  } else {
    __ j(ZERO, is_not_instance_lbl);
  }
  const Register kClassIdReg = ECX;
  __ LoadClassId(kClassIdReg, kInstanceReg);
  // See ClassFinalizer::ResolveSuperTypeAndInterfaces for list of restricted
  // interfaces.
  // Bool interface can be implemented only by core class Bool.
  if (type.IsBoolType()) {
    __ cmpl(kClassIdReg, Immediate(kBoolCid));
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
    __ cmpl(kClassIdReg, Immediate(kClosureCid));
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
RawSubtypeTestCache* FlowGraphCompiler::GenerateSubtype1TestCacheLookup(
    TokenPosition token_pos,
    const Class& type_class,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  __ Comment("Subtype1TestCacheLookup");
  const Register kInstanceReg = EAX;
#if defined(DEBUG)
  Label ok;
  __ BranchIfNotSmi(kInstanceReg, &ok);
  __ Breakpoint();
  __ Bind(&ok);
#endif
  __ LoadClassId(EDI, kInstanceReg);
  __ LoadClassById(ECX, EDI);
  // ECX: instance class.
  // Check immediate superclass equality.
  __ movl(EDI, FieldAddress(ECX, Class::super_type_offset()));
  __ movl(EDI, FieldAddress(EDI, Type::type_class_id_offset()));
  __ cmpl(EDI, Immediate(Smi::RawValue(type_class.id())));
  __ j(EQUAL, is_instance_lbl);

  const Register kInstantiatorTypeArgumentsReg = kNoRegister;
  const Register kFunctionTypeArgumentsReg = kNoRegister;
  const Register kTempReg = EDI;
  return GenerateCallSubtypeTestStub(kTestTypeOneArg, kInstanceReg,
                                     kInstantiatorTypeArgumentsReg,
                                     kFunctionTypeArgumentsReg, kTempReg,
                                     is_instance_lbl, is_not_instance_lbl);
}

// Generates inlined check if 'type' is a type parameter or type itself
// EAX: instance (preserved).
// Clobbers EDX, EDI, ECX.
RawSubtypeTestCache* FlowGraphCompiler::GenerateUninstantiatedTypeTest(
    TokenPosition token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  __ Comment("UninstantiatedTypeTest");
  const Register kInstanceReg = EAX;
  const Register kInstantiatorTypeArgumentsReg = EDX;
  const Register kFunctionTypeArgumentsReg = ECX;
  const Register kTempReg = EDI;
  ASSERT(!type.IsInstantiated());
  ASSERT(!type.IsFunctionType());
  // Skip check if destination is a dynamic type.
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  if (type.IsTypeParameter()) {
    const TypeParameter& type_param = TypeParameter::Cast(type);
    const AbstractType& bound = AbstractType::Handle(type_param.bound());

    __ movl(EDX, Address(ESP, 1 * kWordSize));  // Get instantiator type args.
    __ movl(ECX, Address(ESP, 0 * kWordSize));  // Get function type args.
    // EDX: instantiator type arguments.
    // ECX: function type arguments.
    const Register kTypeArgumentsReg =
        type_param.IsClassTypeParameter() ? EDX : ECX;
    // Check if type arguments are null, i.e. equivalent to vector of dynamic.
    __ cmpl(kTypeArgumentsReg, raw_null);
    __ j(EQUAL, is_instance_lbl);
    __ movl(EDI, FieldAddress(kTypeArgumentsReg, TypeArguments::type_at_offset(
                                                     type_param.index())));
    // EDI: concrete type of type.
    // Check if type argument is dynamic, Object, or void.
    __ CompareObject(EDI, Object::dynamic_type());
    __ j(EQUAL, is_instance_lbl);
    __ CompareObject(EDI, Type::ZoneHandle(zone(), Type::ObjectType()));
    __ j(EQUAL, is_instance_lbl);
    __ CompareObject(EDI, Object::void_type());
    __ j(EQUAL, is_instance_lbl);

    // For Smi check quickly against int and num interfaces.
    Label not_smi;
    __ testl(EAX, Immediate(kSmiTagMask));  // Value is Smi?
    __ j(NOT_ZERO, &not_smi, Assembler::kNearJump);
    __ CompareObject(EDI, Type::ZoneHandle(zone(), Type::IntType()));
    __ j(EQUAL, is_instance_lbl);
    __ CompareObject(EDI, Type::ZoneHandle(zone(), Type::Number()));
    __ j(EQUAL, is_instance_lbl);
    // Smi can be handled by type test cache.
    __ Bind(&not_smi);

    // If it's guaranteed, by type-parameter bound, that the type parameter will
    // never have a value of a function type.
    auto test_kind = !bound.IsTopType() && !bound.IsFunctionType() &&
                             !bound.IsDartFunctionType() && bound.IsType()
                         ? kTestTypeSixArgs
                         : kTestTypeFourArgs;

    const SubtypeTestCache& type_test_cache = SubtypeTestCache::ZoneHandle(
        zone(), GenerateCallSubtypeTestStub(
                    test_kind, kInstanceReg, kInstantiatorTypeArgumentsReg,
                    kFunctionTypeArgumentsReg, kTempReg, is_instance_lbl,
                    is_not_instance_lbl));
    return type_test_cache.raw();
  }
  if (type.IsType()) {
    // Smi is FutureOr<T>, when T is a top type or int or num.
    if (!Class::Handle(type.type_class()).IsFutureOrClass()) {
      __ testl(kInstanceReg, Immediate(kSmiTagMask));  // Is instance Smi?
      __ j(ZERO, is_not_instance_lbl);
    }
    __ movl(kInstantiatorTypeArgumentsReg, Address(ESP, 1 * kWordSize));
    __ movl(kFunctionTypeArgumentsReg, Address(ESP, 0 * kWordSize));
    // Uninstantiated type class is known at compile time, but the type
    // arguments are determined at runtime by the instantiator(s).
    return GenerateCallSubtypeTestStub(kTestTypeFourArgs, kInstanceReg,
                                       kInstantiatorTypeArgumentsReg,
                                       kFunctionTypeArgumentsReg, kTempReg,
                                       is_instance_lbl, is_not_instance_lbl);
  }
  return SubtypeTestCache::null();
}

// Generates function type check.
//
// See [GenerateUninstantiatedTypeTest] for calling convention.
RawSubtypeTestCache* FlowGraphCompiler::GenerateFunctionTypeTest(
    TokenPosition token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  const Register kInstanceReg = EAX;
  const Register kInstantiatorTypeArgumentsReg = EDX;
  const Register kFunctionTypeArgumentsReg = ECX;
  __ Comment("FunctionTypeTest");

  __ testl(kInstanceReg, Immediate(kSmiTagMask));
  __ j(ZERO, is_not_instance_lbl);
  // Uninstantiated type class is known at compile time, but the type
  // arguments are determined at runtime by the instantiator(s).
  const Register kTempReg = EDI;
  return GenerateCallSubtypeTestStub(kTestTypeSixArgs, kInstanceReg,
                                     kInstantiatorTypeArgumentsReg,
                                     kFunctionTypeArgumentsReg, kTempReg,
                                     is_instance_lbl, is_not_instance_lbl);
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
RawSubtypeTestCache* FlowGraphCompiler::GenerateInlineInstanceof(
    TokenPosition token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
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
// - NULL -> return type == Null (type is not Object or dynamic).
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
  ASSERT(type.IsFinalized() && !type.IsMalformedOrMalbounded());
  ASSERT(!type.IsObjectType() && !type.IsDynamicType() && !type.IsVoidType());

  __ pushl(EDX);  // Store instantiator type arguments.
  __ pushl(ECX);  // Store function type arguments.

  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label is_instance, is_not_instance;
  // If type is instantiated and non-parameterized, we can inline code
  // checking whether the tested instance is a Smi.
  if (type.IsInstantiated()) {
    // A null object is only an instance of Null, Object, and dynamic.
    // Object and dynamic have already been checked above (if the type is
    // instantiated). So we can return false here if the instance is null,
    // unless the type is Null (and if the type is instantiated).
    // We can only inline this null check if the type is instantiated at compile
    // time, since an uninstantiated type at compile time could be Null, Object,
    // or dynamic at run time.
    __ cmpl(EAX, raw_null);
    __ j(EQUAL, type.IsNullType() ? &is_instance : &is_not_instance);
  }

  // Generate inline instanceof test.
  SubtypeTestCache& test_cache = SubtypeTestCache::ZoneHandle(zone());
  test_cache =
      GenerateInlineInstanceof(token_pos, type, &is_instance, &is_not_instance);

  // test_cache is null if there is no fall-through.
  Label done;
  if (!test_cache.IsNull()) {
    // Generate runtime call.
    __ movl(EDX, Address(ESP, 1 * kWordSize));  // Get instantiator type args.
    __ movl(ECX, Address(ESP, 0 * kWordSize));  // Get function type args.
    __ PushObject(Object::null_object());       // Make room for the result.
    __ pushl(EAX);                              // Push the instance.
    __ PushObject(type);                        // Push the type.
    __ pushl(EDX);                              // Instantiator type arguments.
    __ pushl(ECX);                              // Function type arguments.
    __ LoadObject(EAX, test_cache);
    __ pushl(EAX);
    GenerateRuntimeCall(token_pos, deopt_id, kInstanceofRuntimeEntry, 5, locs);
    // Pop the parameters supplied to the runtime entry. The result of the
    // instanceof runtime call will be left as the result of the operation.
    __ Drop(5);
    __ popl(EAX);
    __ jmp(&done, Assembler::kNearJump);
  }
  __ Bind(&is_not_instance);
  __ LoadObject(EAX, Bool::Get(false));
  __ jmp(&done, Assembler::kNearJump);

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
// - EDX: instantiator type arguments or raw_null.
// - ECX: function type arguments or raw_null.
// Returns:
// - object in EAX for successful assignable check (or throws TypeError).
// Performance notes: positive checks must be quick, negative checks can be slow
// as they throw an exception.
void FlowGraphCompiler::GenerateAssertAssignable(TokenPosition token_pos,
                                                 intptr_t deopt_id,
                                                 const AbstractType& dst_type,
                                                 const String& dst_name,
                                                 LocationSummary* locs) {
  ASSERT(!token_pos.IsClassifying());
  ASSERT(!dst_type.IsNull());
  ASSERT(dst_type.IsFinalized());
  // Assignable check is skipped in FlowGraphBuilder, not here.
  ASSERT(dst_type.IsMalformedOrMalbounded() ||
         (!dst_type.IsDynamicType() && !dst_type.IsObjectType() &&
          !dst_type.IsVoidType()));
  __ pushl(EDX);  // Store instantiator type arguments.
  __ pushl(ECX);  // Store function type arguments.
  // A null object is always assignable and is returned as result.
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label is_assignable, runtime_call;
  __ cmpl(EAX, raw_null);
  __ j(EQUAL, &is_assignable);

  // Generate throw new TypeError() if the type is malformed or malbounded.
  if (dst_type.IsMalformedOrMalbounded()) {
    __ PushObject(Object::null_object());  // Make room for the result.
    __ pushl(EAX);                         // Push the source object.
    __ PushObject(dst_name);               // Push the name of the destination.
    __ PushObject(dst_type);               // Push the type of the destination.
    GenerateRuntimeCall(token_pos, deopt_id, kBadTypeErrorRuntimeEntry, 3,
                        locs);
    // We should never return here.
    __ int3();

    __ Bind(&is_assignable);  // For a null object.
    __ popl(ECX);             // Remove pushed function type arguments.
    __ popl(EDX);             // Remove pushed instantiator type arguments.
    return;
  }

  // Generate inline type check, linking to runtime call if not assignable.
  SubtypeTestCache& test_cache = SubtypeTestCache::ZoneHandle(zone());
  test_cache = GenerateInlineInstanceof(token_pos, dst_type, &is_assignable,
                                        &runtime_call);

  __ Bind(&runtime_call);
  __ movl(EDX, Address(ESP, 1 * kWordSize));  // Get instantiator type args.
  __ movl(ECX, Address(ESP, 0 * kWordSize));  // Get function type args.
  __ PushObject(Object::null_object());       // Make room for the result.
  __ pushl(EAX);                              // Push the source object.
  __ PushObject(dst_type);  // Push the type of the destination.
  __ pushl(EDX);            // Instantiator type arguments.
  __ pushl(ECX);            // Function type arguments.
  __ PushObject(dst_name);  // Push the name of the destination.
  __ LoadObject(EAX, test_cache);
  __ pushl(EAX);
  __ PushObject(Smi::ZoneHandle(zone(), Smi::New(kTypeCheckFromInline)));
  GenerateRuntimeCall(token_pos, deopt_id, kTypeCheckRuntimeEntry, 7, locs);
  // Pop the parameters supplied to the runtime entry. The result of the
  // type check runtime call is the checked value.
  __ Drop(7);
  __ popl(EAX);

  __ Bind(&is_assignable);
  __ popl(ECX);  // Remove pushed function type arguments.
  __ popl(EDX);  // Remove pushed instantiator type arguments.
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
      __ pushl(value.ToStackSlotAddress());
    }
  }
}

void FlowGraphCompiler::GenerateGetterIntrinsic(intptr_t offset) {
  // TOS: return address.
  // +1 : receiver.
  // Sequence node has one return node, its input is load field node.
  __ Comment("Inlined Getter");
  __ movl(EAX, Address(ESP, 1 * kWordSize));
  __ movl(EAX, FieldAddress(EAX, offset));
  __ ret();
}

void FlowGraphCompiler::GenerateSetterIntrinsic(intptr_t offset) {
  // TOS: return address.
  // +1 : value
  // +2 : receiver.
  // Sequence node has one store node and one return NULL node.
  __ Comment("Inlined Setter");
  __ movl(EAX, Address(ESP, 2 * kWordSize));  // Receiver.
  __ movl(EBX, Address(ESP, 1 * kWordSize));  // Value.
  __ StoreIntoObject(EAX, FieldAddress(EAX, offset), EBX);
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movl(EAX, raw_null);
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
      __ incl(FieldAddress(function_reg, Function::usage_counter_offset()));
    }
    __ cmpl(FieldAddress(function_reg, Function::usage_counter_offset()),
            Immediate(GetOptimizationThreshold()));
    ASSERT(function_reg == EBX);
    __ J(GREATER_EQUAL, StubCode::OptimizeFunction());
  }
  __ Comment("Enter frame");
  if (flow_graph().IsCompiledForOsr()) {
    intptr_t extra_slots = StackSize() - flow_graph().num_stack_locals();
    ASSERT(extra_slots >= 0);
    __ EnterOsrFrame(extra_slots * kWordSize);
  } else {
    ASSERT(StackSize() >= 0);
    __ EnterDartFrame(StackSize() * kWordSize);
  }
}

void FlowGraphCompiler::CompileGraph() {
  InitCompiler();

  if (TryIntrinsify()) {
    // Skip regular code generation.
    return;
  }

  EmitFrameEntry();

  // In unoptimized code, initialize (non-argument) stack allocated slots.
  if (!is_optimizing()) {
    const int num_locals = parsed_function().num_stack_locals();

    intptr_t args_desc_slot = -1;
    if (parsed_function().has_arg_desc_var()) {
      args_desc_slot = compiler_frame_layout.FrameSlotForVariable(
          parsed_function().arg_desc_var());
    }

    __ Comment("Initialize spill slots");
    if (num_locals > 1 || (num_locals == 1 && args_desc_slot == -1)) {
      const Immediate& raw_null =
          Immediate(reinterpret_cast<intptr_t>(Object::null()));
      __ movl(EAX, raw_null);
    }
    for (intptr_t i = 0; i < num_locals; ++i) {
      const intptr_t slot_index =
          compiler_frame_layout.FrameSlotForVariableIndex(-i);
      Register value_reg = slot_index == args_desc_slot ? ARGS_DESC_REG : EAX;
      __ movl(Address(EBP, slot_index * kWordSize), value_reg);
    }
  }

  EndCodeSourceRange(TokenPosition::kDartCodePrologue);
  ASSERT(!block_order().is_empty());
  VisitBlocks();

  __ int3();
  GenerateDeferredCode();
}

void FlowGraphCompiler::GenerateCall(TokenPosition token_pos,
                                     const Code& stub,
                                     RawPcDescriptors::Kind kind,
                                     LocationSummary* locs) {
  __ Call(stub);
  EmitCallsiteMetadata(token_pos, DeoptId::kNone, kind, locs);
  AddStubCallTarget(stub);
}

void FlowGraphCompiler::GenerateDartCall(intptr_t deopt_id,
                                         TokenPosition token_pos,
                                         const Code& stub,
                                         RawPcDescriptors::Kind kind,
                                         LocationSummary* locs,
                                         Code::EntryKind entry_kind) {
  // TODO(sjindel/entrypoints): Support multiple entrypoints on IA32.
  __ Call(stub);
  EmitCallsiteMetadata(token_pos, deopt_id, kind, locs);
}

void FlowGraphCompiler::GenerateStaticDartCall(intptr_t deopt_id,
                                               TokenPosition token_pos,
                                               RawPcDescriptors::Kind kind,
                                               LocationSummary* locs,
                                               const Function& target,
                                               Code::EntryKind entry_kind) {
  // TODO(sjindel/entrypoints): Support multiple entrypoints on IA32.
  const auto& stub = StubCode::CallStaticFunction();
  __ Call(stub, true /* movable_target */);
  EmitCallsiteMetadata(token_pos, deopt_id, kind, locs);
  AddStaticCallTarget(target);
}

void FlowGraphCompiler::GenerateRuntimeCall(TokenPosition token_pos,
                                            intptr_t deopt_id,
                                            const RuntimeEntry& entry,
                                            intptr_t argument_count,
                                            LocationSummary* locs) {
  __ CallRuntime(entry, argument_count);
  EmitCallsiteMetadata(token_pos, deopt_id, RawPcDescriptors::kOther, locs);
}

void FlowGraphCompiler::EmitUnoptimizedStaticCall(intptr_t count_with_type_args,
                                                  intptr_t deopt_id,
                                                  TokenPosition token_pos,
                                                  LocationSummary* locs,
                                                  const ICData& ic_data) {
  const Code& stub =
      StubCode::UnoptimizedStaticCallEntry(ic_data.NumArgsTested());
  __ LoadObject(ECX, ic_data);
  GenerateDartCall(deopt_id, token_pos, stub,
                   RawPcDescriptors::kUnoptStaticCall, locs);
  __ Drop(count_with_type_args);
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
  __ IncrementSmiField(FieldAddress(EAX, Array::element_offset(edge_id)), 1);
}

void FlowGraphCompiler::EmitOptimizedInstanceCall(const Code& stub,
                                                  const ICData& ic_data,
                                                  intptr_t deopt_id,
                                                  TokenPosition token_pos,
                                                  LocationSummary* locs,
                                                  Code::EntryKind entry_kind) {
  // TODO(sjindel/entrypoints): Support multiple entrypoints on IA32.
  ASSERT(Array::Handle(ic_data.arguments_descriptor()).Length() > 0);
  // Each ICData propagated from unoptimized to optimized code contains the
  // function that corresponds to the Dart function of that IC call. Due
  // to inlining in optimized code, that function may not correspond to the
  // top-level function (parsed_function().function()) which could be
  // reoptimized and which counter needs to be incremented.
  // Pass the function explicitly, it is used in IC stub.
  __ LoadObject(EBX, parsed_function().function());
  __ LoadObject(ECX, ic_data);
  GenerateDartCall(deopt_id, token_pos, stub, RawPcDescriptors::kIcCall, locs);
  __ Drop(ic_data.CountWithTypeArgs());
}

void FlowGraphCompiler::EmitInstanceCall(const Code& stub,
                                         const ICData& ic_data,
                                         intptr_t deopt_id,
                                         TokenPosition token_pos,
                                         LocationSummary* locs) {
  ASSERT(Array::Handle(ic_data.arguments_descriptor()).Length() > 0);
  __ LoadObject(ECX, ic_data);
  GenerateDartCall(deopt_id, token_pos, stub, RawPcDescriptors::kIcCall, locs);
  __ Drop(ic_data.CountWithTypeArgs());
}

void FlowGraphCompiler::EmitMegamorphicInstanceCall(
    const String& name,
    const Array& arguments_descriptor,
    intptr_t deopt_id,
    TokenPosition token_pos,
    LocationSummary* locs,
    intptr_t try_index,
    intptr_t slow_path_argument_count) {
  ASSERT(!arguments_descriptor.IsNull() && (arguments_descriptor.Length() > 0));
  const ArgumentsDescriptor args_desc(arguments_descriptor);
  const MegamorphicCache& cache = MegamorphicCache::ZoneHandle(
      zone(),
      MegamorphicCacheTable::Lookup(isolate(), name, arguments_descriptor));

  __ Comment("MegamorphicCall");
  // Load receiver into EBX.
  __ movl(EBX, Address(ESP, (args_desc.Count() - 1) * kWordSize));
  __ LoadObject(ECX, cache);
  __ call(Address(THR, Thread::megamorphic_call_checked_entry_offset()));
  __ call(EBX);

  AddCurrentDescriptor(RawPcDescriptors::kOther, DeoptId::kNone, token_pos);
  RecordSafepoint(locs, slow_path_argument_count);
  const intptr_t deopt_id_after = DeoptId::ToDeoptAfter(deopt_id);
  // Precompilation not implemented on ia32 platform.
  ASSERT(!FLAG_precompiled_mode);
  if (is_optimizing()) {
    AddDeoptIndexAtCall(deopt_id_after);
  } else {
    // Add deoptimization continuation point after the call and before the
    // arguments are removed.
    AddCurrentDescriptor(RawPcDescriptors::kDeopt, deopt_id_after, token_pos);
  }
  RecordCatchEntryMoves(pending_deoptimization_env_, try_index);
  __ Drop(args_desc.CountWithTypeArgs());
}

void FlowGraphCompiler::EmitSwitchableInstanceCall(const ICData& ic_data,
                                                   intptr_t deopt_id,
                                                   TokenPosition token_pos,
                                                   LocationSummary* locs,
                                                   Code::EntryKind entry_kind) {
  // Only generated with precompilation.
  UNREACHABLE();
}

void FlowGraphCompiler::EmitOptimizedStaticCall(
    const Function& function,
    const Array& arguments_descriptor,
    intptr_t count_with_type_args,
    intptr_t deopt_id,
    TokenPosition token_pos,
    LocationSummary* locs,
    Code::EntryKind entry_kind) {
  // TODO(sjindel/entrypoints): Support multiple entrypoints on IA32.
  if (function.HasOptionalParameters() || function.IsGeneric()) {
    __ LoadObject(EDX, arguments_descriptor);
  } else {
    __ xorl(EDX, EDX);  // GC safe smi zero because of stub.
  }
  // Do not use the code from the function, but let the code be patched so that
  // we can record the outgoing edges to other code.
  GenerateStaticDartCall(deopt_id, token_pos,
                         RawPcDescriptors::kOther, locs, function);
  __ Drop(count_with_type_args);
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
    AddCurrentDescriptor(RawPcDescriptors::kRuntimeCall, deopt_id, token_pos);
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
    AddCurrentDescriptor(RawPcDescriptors::kRuntimeCall, deopt_id, token_pos);
    // Stub returns result in flags (result of a cmpl, we need ZF computed).
    __ popl(right);
    __ popl(left);
  } else {
    __ cmpl(left, right);
  }
  return EQUAL;
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
    __ subl(ESP, Immediate(xmm_regs_count * kFpuRegisterSize));
    // Store XMM registers with the lowest register number at the lowest
    // address.
    intptr_t offset = 0;
    for (intptr_t i = 0; i < kNumberOfXmmRegisters; ++i) {
      XmmRegister xmm_reg = static_cast<XmmRegister>(i);
      if (locs->live_registers()->ContainsFpuRegister(xmm_reg)) {
        __ movups(Address(ESP, offset), xmm_reg);
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
        __ movups(xmm_reg, Address(ESP, offset));
        offset += kFpuRegisterSize;
      }
    }
    ASSERT(offset == (xmm_regs_count * kFpuRegisterSize));
    __ addl(ESP, Immediate(offset));
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
      __ movl(tmp.reg(), Immediate(0xf7));
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
  __ movl(EAX, Address(ESP, (count_without_type_args - 1) * kWordSize));
  __ LoadObject(EDX, arguments_descriptor);
}

void FlowGraphCompiler::EmitTestAndCallSmiBranch(Label* label, bool if_smi) {
  __ testl(EAX, Immediate(kSmiTagMask));
  // Jump if receiver is (not) Smi.
  __ j(if_smi ? ZERO : NOT_ZERO, label);
}

void FlowGraphCompiler::EmitTestAndCallLoadCid(Register class_id_reg) {
  ASSERT(class_id_reg != EAX);
  __ LoadClassId(class_id_reg, EAX);
}

#undef __
#define __ assembler->

int FlowGraphCompiler::EmitTestAndCallCheckCid(Assembler* assembler,
                                               Label* label,
                                               Register class_id_reg,
                                               const CidRange& range,
                                               int bias,
                                               bool jump_on_miss) {
  intptr_t cid_start = range.cid_start;
  if (range.IsSingleCid()) {
    __ cmpl(class_id_reg, Immediate(cid_start - bias));
    __ j(jump_on_miss ? NOT_EQUAL : EQUAL, label);
  } else {
    __ addl(class_id_reg, Immediate(bias - cid_start));
    bias = cid_start;
    __ cmpl(class_id_reg, Immediate(range.Extent()));
    __ j(jump_on_miss ? ABOVE : BELOW_EQUAL, label);  // Unsigned higher.
  }
  return bias;
}

#undef __
#define __ compiler_->assembler()->

void ParallelMoveResolver::EmitMove(int index) {
  MoveOperands* move = moves_[index];
  const Location source = move->src();
  const Location destination = move->dest();

  if (source.IsRegister()) {
    if (destination.IsRegister()) {
      __ movl(destination.reg(), source.reg());
    } else {
      ASSERT(destination.IsStackSlot());
      __ movl(destination.ToStackSlotAddress(), source.reg());
    }
  } else if (source.IsStackSlot()) {
    if (destination.IsRegister()) {
      __ movl(destination.reg(), source.ToStackSlotAddress());
    } else {
      ASSERT(destination.IsStackSlot());
      MoveMemoryToMemory(destination.ToStackSlotAddress(),
                         source.ToStackSlotAddress());
    }
  } else if (source.IsFpuRegister()) {
    if (destination.IsFpuRegister()) {
      // Optimization manual recommends using MOVAPS for register
      // to register moves.
      __ movaps(destination.fpu_reg(), source.fpu_reg());
    } else {
      if (destination.IsDoubleStackSlot()) {
        __ movsd(destination.ToStackSlotAddress(), source.fpu_reg());
      } else {
        ASSERT(destination.IsQuadStackSlot());
        __ movups(destination.ToStackSlotAddress(), source.fpu_reg());
      }
    }
  } else if (source.IsDoubleStackSlot()) {
    if (destination.IsFpuRegister()) {
      __ movsd(destination.fpu_reg(), source.ToStackSlotAddress());
    } else {
      ASSERT(destination.IsDoubleStackSlot());
      __ movsd(XMM0, source.ToStackSlotAddress());
      __ movsd(destination.ToStackSlotAddress(), XMM0);
    }
  } else if (source.IsQuadStackSlot()) {
    if (destination.IsFpuRegister()) {
      __ movups(destination.fpu_reg(), source.ToStackSlotAddress());
    } else {
      ASSERT(destination.IsQuadStackSlot());
      __ movups(XMM0, source.ToStackSlotAddress());
      __ movups(destination.ToStackSlotAddress(), XMM0);
    }
  } else {
    ASSERT(source.IsConstant());
    source.constant_instruction()->EmitMoveToLocation(compiler_, destination);
  }

  move->Eliminate();
}

void ParallelMoveResolver::EmitSwap(int index) {
  MoveOperands* move = moves_[index];
  const Location source = move->src();
  const Location destination = move->dest();

  if (source.IsRegister() && destination.IsRegister()) {
    __ xchgl(destination.reg(), source.reg());
  } else if (source.IsRegister() && destination.IsStackSlot()) {
    Exchange(source.reg(), destination.ToStackSlotAddress());
  } else if (source.IsStackSlot() && destination.IsRegister()) {
    Exchange(destination.reg(), source.ToStackSlotAddress());
  } else if (source.IsStackSlot() && destination.IsStackSlot()) {
    Exchange(destination.ToStackSlotAddress(), source.ToStackSlotAddress());
  } else if (source.IsFpuRegister() && destination.IsFpuRegister()) {
    __ movaps(XMM0, source.fpu_reg());
    __ movaps(source.fpu_reg(), destination.fpu_reg());
    __ movaps(destination.fpu_reg(), XMM0);
  } else if (source.IsFpuRegister() || destination.IsFpuRegister()) {
    ASSERT(destination.IsDoubleStackSlot() || destination.IsQuadStackSlot() ||
           source.IsDoubleStackSlot() || source.IsQuadStackSlot());
    bool double_width =
        destination.IsDoubleStackSlot() || source.IsDoubleStackSlot();
    XmmRegister reg =
        source.IsFpuRegister() ? source.fpu_reg() : destination.fpu_reg();
    const Address& slot_address = source.IsFpuRegister()
                                      ? destination.ToStackSlotAddress()
                                      : source.ToStackSlotAddress();

    if (double_width) {
      __ movsd(XMM0, slot_address);
      __ movsd(slot_address, reg);
    } else {
      __ movups(XMM0, slot_address);
      __ movups(slot_address, reg);
    }
    __ movaps(reg, XMM0);
  } else if (source.IsDoubleStackSlot() && destination.IsDoubleStackSlot()) {
    const Address& source_slot_address = source.ToStackSlotAddress();
    const Address& destination_slot_address = destination.ToStackSlotAddress();

    ScratchFpuRegisterScope ensure_scratch(this, XMM0);
    __ movsd(XMM0, source_slot_address);
    __ movsd(ensure_scratch.reg(), destination_slot_address);
    __ movsd(destination_slot_address, XMM0);
    __ movsd(source_slot_address, ensure_scratch.reg());
  } else if (source.IsQuadStackSlot() && destination.IsQuadStackSlot()) {
    const Address& source_slot_address = source.ToStackSlotAddress();
    const Address& destination_slot_address = destination.ToStackSlotAddress();

    ScratchFpuRegisterScope ensure_scratch(this, XMM0);
    __ movups(XMM0, source_slot_address);
    __ movups(ensure_scratch.reg(), destination_slot_address);
    __ movups(destination_slot_address, XMM0);
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

void ParallelMoveResolver::MoveMemoryToMemory(const Address& dst,
                                              const Address& src) {
  ScratchRegisterScope ensure_scratch(this, kNoRegister);
  __ movl(ensure_scratch.reg(), src);
  __ movl(dst, ensure_scratch.reg());
}

void ParallelMoveResolver::Exchange(Register reg, const Address& mem) {
  ScratchRegisterScope ensure_scratch(this, reg);
  __ movl(ensure_scratch.reg(), mem);
  __ movl(mem, reg);
  __ movl(reg, ensure_scratch.reg());
}

void ParallelMoveResolver::Exchange(const Address& mem1, const Address& mem2) {
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
  __ subl(ESP, Immediate(kFpuRegisterSize));
  __ movups(Address(ESP, 0), reg);
}

void ParallelMoveResolver::RestoreFpuScratch(FpuRegister reg) {
  __ movups(reg, Address(ESP, 0));
  __ addl(ESP, Immediate(kFpuRegisterSize));
}

#undef __

}  // namespace dart

#endif  // defined(TARGET_ARCH_IA32) && !defined(DART_PRECOMPILED_RUNTIME)

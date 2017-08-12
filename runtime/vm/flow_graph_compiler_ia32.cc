// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32) && !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/flow_graph_compiler.h"

#include "vm/ast_printer.h"
#include "vm/code_patcher.h"
#include "vm/compiler.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/deopt_instructions.h"
#include "vm/flow_graph_builder.h"
#include "vm/il_printer.h"
#include "vm/instructions.h"
#include "vm/locations.h"
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

bool FlowGraphCompiler::SupportsUnboxedMints() {
  return FLAG_unbox_mints;
}

bool FlowGraphCompiler::SupportsUnboxedSimd128() {
  return FLAG_enable_simd_inline;
}

bool FlowGraphCompiler::SupportsHardwareDivision() {
  return true;
}

bool FlowGraphCompiler::CanConvertUnboxedMintToDouble() {
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
                              Thread::ToDeoptAfter(current->deopt_id()),
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
  __ Call(*StubCode::Deoptimize_entry());
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
    __ Call(*StubCode::Subtype1TestCache_entry());
  } else if (test_kind == kTestTypeTwoArgs) {
    ASSERT(instantiator_type_arguments_reg == kNoRegister);
    ASSERT(function_type_arguments_reg == kNoRegister);
    __ pushl(raw_null);
    __ pushl(raw_null);
    __ Call(*StubCode::Subtype2TestCache_entry());
  } else if (test_kind == kTestTypeFourArgs) {
    __ pushl(instantiator_type_arguments_reg);
    __ pushl(function_type_arguments_reg);
    __ Call(*StubCode::Subtype4TestCache_entry());
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
  const Class& type_class = Class::ZoneHandle(zone(), type.type_class());
  ASSERT(type.IsFunctionType() || (type_class.NumTypeArguments() > 0));
  const Register kInstanceReg = EAX;
  Error& bound_error = Error::Handle(zone());
  const Type& int_type = Type::Handle(zone(), Type::IntType());
  const bool smi_is_ok =
      int_type.IsSubtypeOf(type, &bound_error, NULL, Heap::kOld);
  // Malformed type should have been handled at graph construction time.
  ASSERT(smi_is_ok || bound_error.IsNull());
  __ testl(kInstanceReg, Immediate(kSmiTagMask));
  if (smi_is_ok) {
    __ j(ZERO, is_instance_lbl);
  } else {
    __ j(ZERO, is_not_instance_lbl);
  }
  // A function type test requires checking the function signature.
  if (!type.IsFunctionType()) {
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
        ASSERT(tp_argument.HasResolvedTypeClass());
        // Check if type argument is dynamic or Object.
        const Type& object_type = Type::Handle(zone(), Type::ObjectType());
        if (object_type.IsSubtypeOf(tp_argument, NULL, NULL, Heap::kOld)) {
          // Instance class test only necessary.
          return GenerateSubtype1TestCacheLookup(
              token_pos, type_class, is_instance_lbl, is_not_instance_lbl);
        }
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
  if (type.IsFunctionType()) {
    // Fallthrough.
    return true;
  }
  const Class& type_class = Class::Handle(zone(), type.type_class());
  ASSERT(type_class.NumTypeArguments() == 0);

  const Register kInstanceReg = EAX;
  __ testl(kInstanceReg, Immediate(kSmiTagMask));
  // If instance is Smi, check directly.
  const Class& smi_class = Class::Handle(zone(), Smi::Class());
  if (smi_class.IsSubtypeOf(Object::null_type_arguments(), type_class,
                            Object::null_type_arguments(), NULL, NULL,
                            Heap::kOld)) {
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
  // Custom checking for numbers (Smi, Mint, Bigint and Double).
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
  // Compare if the classes are equal.
  if (!type_class.is_abstract()) {
    __ cmpl(kClassIdReg, Immediate(type_class.id()));
    __ j(EQUAL, is_instance_lbl);
  }
  // Otherwise fallthrough.
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
  __ LoadClass(ECX, kInstanceReg, EDI);
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
  ASSERT(!type.IsInstantiated());
  // Skip check if destination is a dynamic type.
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  if (type.IsTypeParameter()) {
    const TypeParameter& type_param = TypeParameter::Cast(type);
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
    // Check if type argument is dynamic.
    __ CompareObject(EDI, Object::dynamic_type());
    __ j(EQUAL, is_instance_lbl);
    __ CompareObject(EDI, Type::ZoneHandle(zone(), Type::ObjectType()));
    __ j(EQUAL, is_instance_lbl);
    // TODO(regis): Optimize void type as well once allowed as type argument.

    // For Smi check quickly against int and num interfaces.
    Label not_smi;
    __ testl(EAX, Immediate(kSmiTagMask));  // Value is Smi?
    __ j(NOT_ZERO, &not_smi, Assembler::kNearJump);
    __ CompareObject(EDI, Type::ZoneHandle(zone(), Type::IntType()));
    __ j(EQUAL, is_instance_lbl);
    __ CompareObject(EDI, Type::ZoneHandle(zone(), Type::Number()));
    __ j(EQUAL, is_instance_lbl);
    // Smi must be handled in runtime.
    Label fall_through;
    __ jmp(&fall_through);

    __ Bind(&not_smi);
    // EDX: instantiator type arguments.
    // ECX: function type arguments.
    // EAX: instance.
    const Register kInstanceReg = EAX;
    const Register kInstantiatorTypeArgumentsReg = EDX;
    const Register kFunctionTypeArgumentsReg = ECX;
    const Register kTempReg = EDI;
    const SubtypeTestCache& type_test_cache = SubtypeTestCache::ZoneHandle(
        zone(), GenerateCallSubtypeTestStub(
                    kTestTypeFourArgs, kInstanceReg,
                    kInstantiatorTypeArgumentsReg, kFunctionTypeArgumentsReg,
                    kTempReg, is_instance_lbl, is_not_instance_lbl));
    __ Bind(&fall_through);
    return type_test_cache.raw();
  }
  if (type.IsType()) {
    const Register kInstanceReg = EAX;
    const Register kInstantiatorTypeArgumentsReg = EDX;
    const Register kFunctionTypeArgumentsReg = ECX;
    __ testl(kInstanceReg, Immediate(kSmiTagMask));  // Is instance Smi?
    __ j(ZERO, is_not_instance_lbl);
    __ movl(kInstantiatorTypeArgumentsReg, Address(ESP, 1 * kWordSize));
    __ movl(kFunctionTypeArgumentsReg, Address(ESP, 0 * kWordSize));
    // Uninstantiated type class is known at compile time, but the type
    // arguments are determined at runtime by the instantiator(s).
    const Register kTempReg = EDI;
    return GenerateCallSubtypeTestStub(kTestTypeFourArgs, kInstanceReg,
                                       kInstantiatorTypeArgumentsReg,
                                       kFunctionTypeArgumentsReg, kTempReg,
                                       is_instance_lbl, is_not_instance_lbl);
  }
  return SubtypeTestCache::null();
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
  if (type.IsInstantiated()) {
    const Class& type_class = Class::ZoneHandle(zone(), type.type_class());
    // A class equality check is only applicable with a dst type (not a
    // function type) of a non-parameterized class or with a raw dst type of
    // a parameterized class.
    if (type.IsFunctionType() || (type_class.NumTypeArguments() > 0)) {
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
  GenerateRuntimeCall(token_pos, deopt_id, kTypeCheckRuntimeEntry, 6, locs);
  // Pop the parameters supplied to the runtime entry. The result of the
  // type check runtime call is the checked value.
  __ Drop(6);
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

void FlowGraphCompiler::CopyParameters() {
  __ Comment("Copy parameters");
  const Function& function = parsed_function().function();
  LocalScope* scope = parsed_function().node_sequence()->scope();
  const int num_fixed_params = function.num_fixed_parameters();
  const int num_opt_pos_params = function.NumOptionalPositionalParameters();
  const int num_opt_named_params = function.NumOptionalNamedParameters();
  const int num_params =
      num_fixed_params + num_opt_pos_params + num_opt_named_params;
  ASSERT(function.NumParameters() == num_params);
  ASSERT(parsed_function().first_parameter_index() == kFirstLocalSlotFromFp);

  // Check that min_num_pos_args <= num_pos_args <= max_num_pos_args,
  // where num_pos_args is the number of positional arguments passed in.
  const int min_num_pos_args = num_fixed_params;
  const int max_num_pos_args = num_fixed_params + num_opt_pos_params;

  __ movl(ECX,
          FieldAddress(EDX, ArgumentsDescriptor::positional_count_offset()));
  // Check that min_num_pos_args <= num_pos_args.
  Label wrong_num_arguments;
  __ cmpl(ECX, Immediate(Smi::RawValue(min_num_pos_args)));
  __ j(LESS, &wrong_num_arguments);
  // Check that num_pos_args <= max_num_pos_args.
  __ cmpl(ECX, Immediate(Smi::RawValue(max_num_pos_args)));
  __ j(GREATER, &wrong_num_arguments);

  // Copy positional arguments.
  // Argument i passed at fp[kParamEndSlotFromFp + num_args - i] is copied
  // to fp[kFirstLocalSlotFromFp - i].

  __ movl(EBX, FieldAddress(EDX, ArgumentsDescriptor::count_offset()));
  // Since EBX and ECX are Smi, use TIMES_2 instead of TIMES_4.
  // Let EBX point to the last passed positional argument, i.e. to
  // fp[kParamEndSlotFromFp + num_args - (num_pos_args - 1)].
  __ subl(EBX, ECX);
  __ leal(EBX,
          Address(EBP, EBX, TIMES_2, (kParamEndSlotFromFp + 1) * kWordSize));

  // Let EDI point to the last copied positional argument, i.e. to
  // fp[kFirstLocalSlotFromFp - (num_pos_args - 1)].
  __ leal(EDI, Address(EBP, (kFirstLocalSlotFromFp + 1) * kWordSize));
  __ subl(EDI, ECX);  // ECX is a Smi, subtract twice for TIMES_4 scaling.
  __ subl(EDI, ECX);
  __ SmiUntag(ECX);
  Label loop, loop_condition;
  __ jmp(&loop_condition, Assembler::kNearJump);
  // We do not use the final allocation index of the variable here, i.e.
  // scope->VariableAt(i)->index(), because captured variables still need
  // to be copied to the context that is not yet allocated.
  const Address argument_addr(EBX, ECX, TIMES_4, 0);
  const Address copy_addr(EDI, ECX, TIMES_4, 0);
  __ Bind(&loop);
  __ movl(EAX, argument_addr);
  __ movl(copy_addr, EAX);
  __ Bind(&loop_condition);
  __ decl(ECX);
  __ j(POSITIVE, &loop, Assembler::kNearJump);

  // Copy or initialize optional named arguments.
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label all_arguments_processed;
#ifdef DEBUG
  const bool check_correct_named_args = true;
#else
  const bool check_correct_named_args = function.IsClosureFunction();
#endif
  if (num_opt_named_params > 0) {
    // Start by alphabetically sorting the names of the optional parameters.
    LocalVariable** opt_param = new LocalVariable*[num_opt_named_params];
    int* opt_param_position = new int[num_opt_named_params];
    for (int pos = num_fixed_params; pos < num_params; pos++) {
      LocalVariable* parameter = scope->VariableAt(pos);
      const String& opt_param_name = parameter->name();
      int i = pos - num_fixed_params;
      while (--i >= 0) {
        LocalVariable* param_i = opt_param[i];
        const intptr_t result = opt_param_name.CompareTo(param_i->name());
        ASSERT(result != 0);
        if (result > 0) break;
        opt_param[i + 1] = opt_param[i];
        opt_param_position[i + 1] = opt_param_position[i];
      }
      opt_param[i + 1] = parameter;
      opt_param_position[i + 1] = pos;
    }
    // Generate code handling each optional parameter in alphabetical order.
    __ movl(EBX, FieldAddress(EDX, ArgumentsDescriptor::count_offset()));
    // Let EBX point to the first passed argument, i.e. to
    // fp[kParamEndSlotFromFp + num_args - 0]; num_args (EBX) is Smi.
    __ leal(EBX, Address(EBP, EBX, TIMES_2, kParamEndSlotFromFp * kWordSize));
    // Let EDI point to the entry of the first named argument.
    __ leal(EDI,
            FieldAddress(EDX, ArgumentsDescriptor::first_named_entry_offset()));
    for (int i = 0; i < num_opt_named_params; i++) {
      Label load_default_value, assign_optional_parameter;
      const int param_pos = opt_param_position[i];
      // Check if this named parameter was passed in.
      // Load EAX with the name of the argument.
      __ movl(EAX, Address(EDI, ArgumentsDescriptor::name_offset()));
      ASSERT(opt_param[i]->name().IsSymbol());
      __ CompareObject(EAX, opt_param[i]->name());
      __ j(NOT_EQUAL, &load_default_value, Assembler::kNearJump);
      // Load EAX with passed-in argument at provided arg_pos, i.e. at
      // fp[kParamEndSlotFromFp + num_args - arg_pos].
      __ movl(EAX, Address(EDI, ArgumentsDescriptor::position_offset()));
      // EAX is arg_pos as Smi.
      // Point to next named entry.
      __ addl(EDI, Immediate(ArgumentsDescriptor::named_entry_size()));
      __ negl(EAX);
      Address argument_addr(EBX, EAX, TIMES_2, 0);  // EAX is a negative Smi.
      __ movl(EAX, argument_addr);
      __ jmp(&assign_optional_parameter, Assembler::kNearJump);
      __ Bind(&load_default_value);
      // Load EAX with default argument.
      const Instance& value = parsed_function().DefaultParameterValueAt(
          param_pos - num_fixed_params);
      __ LoadObject(EAX, value);
      __ Bind(&assign_optional_parameter);
      // Assign EAX to fp[kFirstLocalSlotFromFp - param_pos].
      // We do not use the final allocation index of the variable here, i.e.
      // scope->VariableAt(i)->index(), because captured variables still need
      // to be copied to the context that is not yet allocated.
      const intptr_t computed_param_pos = kFirstLocalSlotFromFp - param_pos;
      const Address param_addr(EBP, computed_param_pos * kWordSize);
      __ movl(param_addr, EAX);
    }
    delete[] opt_param;
    delete[] opt_param_position;
    if (check_correct_named_args) {
      // Check that EDI now points to the null terminator in the arguments
      // descriptor.
      __ cmpl(Address(EDI, 0), raw_null);
      __ j(EQUAL, &all_arguments_processed, Assembler::kNearJump);
    }
  } else {
    ASSERT(num_opt_pos_params > 0);
    __ movl(ECX,
            FieldAddress(EDX, ArgumentsDescriptor::positional_count_offset()));
    __ SmiUntag(ECX);
    for (int i = 0; i < num_opt_pos_params; i++) {
      Label next_parameter;
      // Handle this optional positional parameter only if k or fewer positional
      // arguments have been passed, where k is param_pos, the position of this
      // optional parameter in the formal parameter list.
      const int param_pos = num_fixed_params + i;
      __ cmpl(ECX, Immediate(param_pos));
      __ j(GREATER, &next_parameter, Assembler::kNearJump);
      // Load EAX with default argument.
      const Object& value = parsed_function().DefaultParameterValueAt(i);
      __ LoadObject(EAX, value);
      // Assign EAX to fp[kFirstLocalSlotFromFp - param_pos].
      // We do not use the final allocation index of the variable here, i.e.
      // scope->VariableAt(i)->index(), because captured variables still need
      // to be copied to the context that is not yet allocated.
      const intptr_t computed_param_pos = kFirstLocalSlotFromFp - param_pos;
      const Address param_addr(EBP, computed_param_pos * kWordSize);
      __ movl(param_addr, EAX);
      __ Bind(&next_parameter);
    }
    if (check_correct_named_args) {
      __ movl(EBX, FieldAddress(EDX, ArgumentsDescriptor::count_offset()));
      __ SmiUntag(EBX);
      // Check that ECX equals EBX, i.e. no named arguments passed.
      __ cmpl(ECX, EBX);
      __ j(EQUAL, &all_arguments_processed, Assembler::kNearJump);
    }
  }

  __ Bind(&wrong_num_arguments);
  if (function.IsClosureFunction()) {
    __ LeaveFrame();  // The arguments are still on the stack.
    __ Jmp(*StubCode::CallClosureNoSuchMethod_entry());
    // The noSuchMethod call may return to the caller, but not here.
  } else if (check_correct_named_args) {
    __ Stop("Wrong arguments");
  }

  __ Bind(&all_arguments_processed);
  // Nullify originally passed arguments only after they have been copied and
  // checked, otherwise noSuchMethod would not see their original values.
  // This step can be skipped in case we decide that formal parameters are
  // implicitly final, since garbage collecting the unmodified value is not
  // an issue anymore.

  // EDX : arguments descriptor array.
  __ movl(ECX, FieldAddress(EDX, ArgumentsDescriptor::count_offset()));
  __ SmiUntag(ECX);
  Label null_args_loop, null_args_loop_condition;
  __ jmp(&null_args_loop_condition, Assembler::kNearJump);
  const Address original_argument_addr(EBP, ECX, TIMES_4,
                                       (kParamEndSlotFromFp + 1) * kWordSize);
  __ Bind(&null_args_loop);
  __ movl(original_argument_addr, raw_null);
  __ Bind(&null_args_loop_condition);
  __ decl(ECX);
  __ j(POSITIVE, &null_args_loop, Assembler::kNearJump);
}

void FlowGraphCompiler::GenerateInlinedGetter(intptr_t offset) {
  // TOS: return address.
  // +1 : receiver.
  // Sequence node has one return node, its input is load field node.
  __ Comment("Inlined Getter");
  __ movl(EAX, Address(ESP, 1 * kWordSize));
  __ movl(EAX, FieldAddress(EAX, offset));
  __ ret();
}

void FlowGraphCompiler::GenerateInlinedSetter(intptr_t offset) {
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
    __ J(GREATER_EQUAL, *StubCode::OptimizeFunction_entry());
  }
  __ Comment("Enter frame");
  if (flow_graph().IsCompiledForOsr()) {
    intptr_t extra_slots = StackSize() - flow_graph().num_stack_locals() -
                           flow_graph().num_copied_params();
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

  const Function& function = parsed_function().function();

  const int num_fixed_params = function.num_fixed_parameters();
  const int num_copied_params = parsed_function().num_copied_params();
  const int num_locals = parsed_function().num_stack_locals();

  // We check the number of passed arguments when we have to copy them due to
  // the presence of optional parameters.
  // No such checking code is generated if only fixed parameters are declared,
  // unless we are in debug mode or unless we are compiling a closure.
  if (num_copied_params == 0) {
    const bool check_arguments =
        function.IsClosureFunction() && !flow_graph().IsCompiledForOsr();
    if (check_arguments) {
      __ Comment("Check argument count");
      // Check that exactly num_fixed arguments are passed in.
      Label correct_num_arguments, wrong_num_arguments;
      __ movl(EAX, FieldAddress(EDX, ArgumentsDescriptor::count_offset()));
      __ cmpl(EAX, Immediate(Smi::RawValue(num_fixed_params)));
      __ j(NOT_EQUAL, &wrong_num_arguments, Assembler::kNearJump);
      __ cmpl(EAX, FieldAddress(
                       EDX, ArgumentsDescriptor::positional_count_offset()));
      __ j(EQUAL, &correct_num_arguments, Assembler::kNearJump);

      __ Bind(&wrong_num_arguments);
      __ LeaveFrame();  // The arguments are still on the stack.
      __ Jmp(*StubCode::CallClosureNoSuchMethod_entry());
      // The noSuchMethod call may return to the caller, but not here.
      __ Bind(&correct_num_arguments);
    }
  } else if (!flow_graph().IsCompiledForOsr()) {
    CopyParameters();
  }

  if (function.IsClosureFunction() && !flow_graph().IsCompiledForOsr()) {
    // Load context from the closure object (first argument).
    LocalScope* scope = parsed_function().node_sequence()->scope();
    LocalVariable* closure_parameter = scope->VariableAt(0);
    // TODO(fschneider): Don't load context for optimized functions that
    // don't use it.
    __ movl(CTX, Address(EBP, closure_parameter->index() * kWordSize));
    __ movl(CTX, FieldAddress(CTX, Closure::context_offset()));
#ifdef DEBUG
    Label ok;
    __ LoadClassId(EBX, CTX);
    __ cmpl(EBX, Immediate(kContextCid));
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Incorrect context at entry");
    __ Bind(&ok);
#endif
  }

  // In unoptimized code, initialize (non-argument) stack allocated slots to
  // null.
  if (!is_optimizing()) {
    ASSERT(num_locals > 0);  // There is always at least context_var.
    __ Comment("Initialize spill slots");
    const intptr_t slot_base = parsed_function().first_stack_local_index();
    const intptr_t context_index =
        parsed_function().current_context_var()->index();
    if (num_locals > 1) {
      const Immediate& raw_null =
          Immediate(reinterpret_cast<intptr_t>(Object::null()));
      __ movl(EAX, raw_null);
    }
    for (intptr_t i = 0; i < num_locals; ++i) {
      // Subtract index i (locals lie at lower addresses than EBP).
      if (((slot_base - i) == context_index)) {
        if (function.IsClosureFunction()) {
          __ movl(Address(EBP, (slot_base - i) * kWordSize), CTX);
        } else {
          const Immediate& raw_empty_context = Immediate(
              reinterpret_cast<intptr_t>(Object::empty_context().raw()));
          __ movl(Address(EBP, (slot_base - i) * kWordSize), raw_empty_context);
        }
      } else {
        ASSERT(num_locals > 1);
        __ movl(Address(EBP, (slot_base - i) * kWordSize), EAX);
      }
    }
  }

  // Check for a passed type argument vector if the function is generic.
  if (FLAG_reify_generic_functions && function.IsGeneric() &&
      !flow_graph().IsCompiledForOsr()) {
    __ Comment("Check passed-in type args");
    Label store_type_args, ok;
    __ cmpl(FieldAddress(EDX, ArgumentsDescriptor::type_args_len_offset()),
            Immediate(0));
    if (is_optimizing()) {
      // Initialize type_args to null if none passed in.
      const Immediate& raw_null =
          Immediate(reinterpret_cast<intptr_t>(Object::null()));
      __ movl(EAX, raw_null);
      __ j(EQUAL, &store_type_args, Assembler::kNearJump);
    } else {
      __ j(EQUAL, &ok, Assembler::kNearJump);  // Already initialized to null.
    }
    // TODO(regis): Verify that type_args_len is correct.
    // Load the passed type args vector in EAX from
    // fp[kParamEndSlotFromFp + num_args + 1]; num_args (EBX) is Smi.
    __ movl(EBX, FieldAddress(EDX, ArgumentsDescriptor::count_offset()));
    __ movl(EAX,
            Address(EBP, EBX, TIMES_2, (kParamEndSlotFromFp + 1) * kWordSize));
    // Store EAX into the stack slot reserved for the function type arguments.
    // If the function type arguments variable is captured, a copy will happen
    // after the context is allocated.
    const intptr_t slot_base = parsed_function().first_stack_local_index();
    ASSERT(parsed_function().function_type_arguments()->is_captured() ||
           parsed_function().function_type_arguments()->index() == slot_base);
    __ Bind(&store_type_args);
    __ movl(Address(EBP, slot_base * kWordSize), EAX);
    __ Bind(&ok);
  }

  // TODO(regis): Verify that no vector is passed if not generic, unless already
  // checked during resolution.

  EndCodeSourceRange(TokenPosition::kDartCodePrologue);
  ASSERT(!block_order().is_empty());
  VisitBlocks();

  __ int3();
  GenerateDeferredCode();
}

void FlowGraphCompiler::GenerateCall(TokenPosition token_pos,
                                     const StubEntry& stub_entry,
                                     RawPcDescriptors::Kind kind,
                                     LocationSummary* locs) {
  __ Call(stub_entry);
  EmitCallsiteMetaData(token_pos, Thread::kNoDeoptId, kind, locs);
}

void FlowGraphCompiler::GenerateDartCall(intptr_t deopt_id,
                                         TokenPosition token_pos,
                                         const StubEntry& stub_entry,
                                         RawPcDescriptors::Kind kind,
                                         LocationSummary* locs) {
  __ Call(stub_entry);
  EmitCallsiteMetaData(token_pos, deopt_id, kind, locs);
  // Marks either the continuation point in unoptimized code or the
  // deoptimization point in optimized code, after call.
  const intptr_t deopt_id_after = Thread::ToDeoptAfter(deopt_id);
  if (is_optimizing()) {
    AddDeoptIndexAtCall(deopt_id_after);
  } else {
    // Add deoptimization continuation point after the call and before the
    // arguments are removed.
    AddCurrentDescriptor(RawPcDescriptors::kDeopt, deopt_id_after, token_pos);
  }
}

void FlowGraphCompiler::GenerateStaticDartCall(intptr_t deopt_id,
                                               TokenPosition token_pos,
                                               const StubEntry& stub_entry,
                                               RawPcDescriptors::Kind kind,
                                               LocationSummary* locs,
                                               const Function& target) {
  GenerateDartCall(deopt_id, token_pos, stub_entry, kind, locs);
  AddStaticCallTarget(target);
}

void FlowGraphCompiler::GenerateRuntimeCall(TokenPosition token_pos,
                                            intptr_t deopt_id,
                                            const RuntimeEntry& entry,
                                            intptr_t argument_count,
                                            LocationSummary* locs) {
  __ CallRuntime(entry, argument_count);
  EmitCallsiteMetaData(token_pos, deopt_id, RawPcDescriptors::kOther, locs);
  if (deopt_id != Thread::kNoDeoptId) {
    // Marks either the continuation point in unoptimized code or the
    // deoptimization point in optimized code, after call.
    const intptr_t deopt_id_after = Thread::ToDeoptAfter(deopt_id);
    if (is_optimizing()) {
      AddDeoptIndexAtCall(deopt_id_after);
    } else {
      // Add deoptimization continuation point after the call and before the
      // arguments are removed.
      AddCurrentDescriptor(RawPcDescriptors::kDeopt, deopt_id_after, token_pos);
    }
  }
}

void FlowGraphCompiler::EmitUnoptimizedStaticCall(intptr_t argument_count,
                                                  intptr_t deopt_id,
                                                  TokenPosition token_pos,
                                                  LocationSummary* locs,
                                                  const ICData& ic_data) {
  const StubEntry& stub_entry =
      *StubCode::UnoptimizedStaticCallEntry(ic_data.NumArgsTested());
  __ LoadObject(ECX, ic_data);
  GenerateDartCall(deopt_id, token_pos, stub_entry,
                   RawPcDescriptors::kUnoptStaticCall, locs);
  __ Drop(argument_count);
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

void FlowGraphCompiler::EmitOptimizedInstanceCall(const StubEntry& stub_entry,
                                                  const ICData& ic_data,
                                                  intptr_t argument_count,
                                                  intptr_t deopt_id,
                                                  TokenPosition token_pos,
                                                  LocationSummary* locs) {
  ASSERT(Array::Handle(ic_data.arguments_descriptor()).Length() > 0);
  // Each ICData propagated from unoptimized to optimized code contains the
  // function that corresponds to the Dart function of that IC call. Due
  // to inlining in optimized code, that function may not correspond to the
  // top-level function (parsed_function().function()) which could be
  // reoptimized and which counter needs to be incremented.
  // Pass the function explicitly, it is used in IC stub.
  __ LoadObject(EBX, parsed_function().function());
  __ LoadObject(ECX, ic_data);
  GenerateDartCall(deopt_id, token_pos, stub_entry, RawPcDescriptors::kIcCall,
                   locs);
  __ Drop(argument_count);
}

void FlowGraphCompiler::EmitInstanceCall(const StubEntry& stub_entry,
                                         const ICData& ic_data,
                                         intptr_t argument_count,
                                         intptr_t deopt_id,
                                         TokenPosition token_pos,
                                         LocationSummary* locs) {
  ASSERT(Array::Handle(ic_data.arguments_descriptor()).Length() > 0);
  __ LoadObject(ECX, ic_data);
  GenerateDartCall(deopt_id, token_pos, stub_entry, RawPcDescriptors::kIcCall,
                   locs);
  __ Drop(argument_count);
}

void FlowGraphCompiler::EmitMegamorphicInstanceCall(
    const String& name,
    const Array& arguments_descriptor,
    intptr_t argument_count,
    intptr_t deopt_id,
    TokenPosition token_pos,
    LocationSummary* locs,
    intptr_t try_index,
    intptr_t slow_path_argument_count) {
  ASSERT(!arguments_descriptor.IsNull() && (arguments_descriptor.Length() > 0));
  const MegamorphicCache& cache = MegamorphicCache::ZoneHandle(
      zone(),
      MegamorphicCacheTable::Lookup(isolate(), name, arguments_descriptor));

  __ Comment("MegamorphicCall");
  // Load receiver into EBX.
  __ movl(EBX, Address(ESP, (argument_count - 1) * kWordSize));
  __ LoadObject(ECX, cache);
  __ call(Address(THR, Thread::megamorphic_call_checked_entry_offset()));
  __ call(EBX);

  AddCurrentDescriptor(RawPcDescriptors::kOther, Thread::kNoDeoptId, token_pos);
  RecordSafepoint(locs, slow_path_argument_count);
  const intptr_t deopt_id_after = Thread::ToDeoptAfter(deopt_id);
  // Precompilation not implemented on ia32 platform.
  ASSERT(!FLAG_precompiled_mode);
  if (is_optimizing()) {
    AddDeoptIndexAtCall(deopt_id_after);
  } else {
    // Add deoptimization continuation point after the call and before the
    // arguments are removed.
    AddCurrentDescriptor(RawPcDescriptors::kDeopt, deopt_id_after, token_pos);
  }
  EmitCatchEntryState(pending_deoptimization_env_, try_index);
  __ Drop(argument_count);
}

void FlowGraphCompiler::EmitSwitchableInstanceCall(const ICData& ic_data,
                                                   intptr_t argument_count,
                                                   intptr_t deopt_id,
                                                   TokenPosition token_pos,
                                                   LocationSummary* locs) {
  // Only generated with precompilation.
  UNREACHABLE();
}

void FlowGraphCompiler::EmitOptimizedStaticCall(
    const Function& function,
    const Array& arguments_descriptor,
    intptr_t argument_count,
    intptr_t deopt_id,
    TokenPosition token_pos,
    LocationSummary* locs) {
  if (function.HasOptionalParameters() ||
      (FLAG_reify_generic_functions && function.IsGeneric())) {
    __ LoadObject(EDX, arguments_descriptor);
  } else {
    __ xorl(EDX, EDX);  // GC safe smi zero because of stub.
  }
  // Do not use the code from the function, but let the code be patched so that
  // we can record the outgoing edges to other code.
  GenerateDartCall(deopt_id, token_pos, *StubCode::CallStaticFunction_entry(),
                   RawPcDescriptors::kOther, locs);
  AddStaticCallTarget(function);
  __ Drop(argument_count);
}

Condition FlowGraphCompiler::EmitEqualityRegConstCompare(
    Register reg,
    const Object& obj,
    bool needs_number_check,
    TokenPosition token_pos,
    intptr_t deopt_id) {
  ASSERT(!needs_number_check ||
         (!obj.IsMint() && !obj.IsDouble() && !obj.IsBigint()));

  if (obj.IsSmi() && (Smi::Cast(obj).Value() == 0)) {
    ASSERT(!needs_number_check);
    __ testl(reg, reg);
    return EQUAL;
  }

  if (needs_number_check) {
    __ pushl(reg);
    __ PushObject(obj);
    if (is_optimizing()) {
      __ Call(*StubCode::OptimizedIdenticalWithNumberCheck_entry());
    } else {
      __ Call(*StubCode::UnoptimizedIdenticalWithNumberCheck_entry());
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
      __ Call(*StubCode::OptimizedIdenticalWithNumberCheck_entry());
    } else {
      __ Call(*StubCode::UnoptimizedIdenticalWithNumberCheck_entry());
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

void FlowGraphCompiler::EmitTestAndCallLoadReceiver(
    intptr_t argument_count,
    const Array& arguments_descriptor) {
  __ Comment("EmitTestAndCall");
  // Load receiver into EAX.
  __ movl(EAX, Address(ESP, (argument_count - 1) * kWordSize));
  __ LoadObject(EDX, arguments_descriptor);
}

void FlowGraphCompiler::EmitTestAndCallSmiBranch(Label* label, bool if_smi) {
  __ testl(EAX, Immediate(kSmiTagMask));
  // Jump if receiver is (not) Smi.
  __ j(if_smi ? ZERO : NOT_ZERO, label);
}

void FlowGraphCompiler::EmitTestAndCallLoadCid() {
  __ LoadClassId(EDI, EAX);
}

int FlowGraphCompiler::EmitTestAndCallCheckCid(Label* next_label,
                                               const CidRange& range,
                                               int bias) {
  intptr_t cid_start = range.cid_start;
  if (range.IsSingleCid()) {
    __ cmpl(EDI, Immediate(cid_start - bias));
    __ j(NOT_EQUAL, next_label);
  } else {
    __ addl(EDI, Immediate(bias - cid_start));
    bias = cid_start;
    __ cmpl(EDI, Immediate(range.Extent()));
    __ j(ABOVE, next_label);  // Unsigned higher.
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
    if (destination.IsRegister()) {
      const Object& constant = source.constant();
      if (constant.IsSmi() && (Smi::Cast(constant).Value() == 0)) {
        __ xorl(destination.reg(), destination.reg());
      } else if (constant.IsSmi() &&
                 (source.constant_instruction()->representation() ==
                  kUnboxedInt32)) {
        __ movl(destination.reg(), Immediate(Smi::Cast(constant).Value()));
      } else {
        __ LoadObjectSafely(destination.reg(), constant);
      }
    } else if (destination.IsFpuRegister()) {
      const Double& constant = Double::Cast(source.constant());
      uword addr = FlowGraphBuilder::FindDoubleConstant(constant.value());
      if (addr == 0) {
        __ pushl(EAX);
        __ LoadObject(EAX, constant);
        __ movsd(destination.fpu_reg(),
                 FieldAddress(EAX, Double::value_offset()));
        __ popl(EAX);
      } else if (Utils::DoublesBitEqual(constant.value(), 0.0)) {
        __ xorps(destination.fpu_reg(), destination.fpu_reg());
      } else {
        __ movsd(destination.fpu_reg(), Address::Absolute(addr));
      }
    } else if (destination.IsDoubleStackSlot()) {
      const Double& constant = Double::Cast(source.constant());
      uword addr = FlowGraphBuilder::FindDoubleConstant(constant.value());
      if (addr == 0) {
        __ pushl(EAX);
        __ LoadObject(EAX, constant);
        __ movsd(XMM0, FieldAddress(EAX, Double::value_offset()));
        __ popl(EAX);
      } else if (Utils::DoublesBitEqual(constant.value(), 0.0)) {
        __ xorps(XMM0, XMM0);
      } else {
        __ movsd(XMM0, Address::Absolute(addr));
      }
      __ movsd(destination.ToStackSlotAddress(), XMM0);
    } else {
      ASSERT(destination.IsStackSlot());
      const Object& constant = source.constant();
      if (constant.IsSmi() &&
          (source.constant_instruction()->representation() == kUnboxedInt32)) {
        __ movl(destination.ToStackSlotAddress(),
                Immediate(Smi::Cast(constant).Value()));
      } else {
        StoreObject(destination.ToStackSlotAddress(), source.constant());
      }
    }
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

void ParallelMoveResolver::StoreObject(const Address& dst, const Object& obj) {
  if (Assembler::IsSafeSmi(obj) || obj.IsNull()) {
    __ movl(dst, Immediate(reinterpret_cast<int32_t>(obj.raw())));
  } else {
    ScratchRegisterScope ensure_scratch(this, kNoRegister);
    __ LoadObjectSafely(ensure_scratch.reg(), obj);
    __ movl(dst, ensure_scratch.reg());
  }
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

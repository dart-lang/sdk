// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/flow_graph_compiler.h"

#include "vm/ast_printer.h"
#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/deopt_instructions.h"
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


bool FlowGraphCompiler::SupportsSinCos() {
  return true;
}


bool FlowGraphCompiler::SupportsHardwareDivision() {
  return true;
}


bool FlowGraphCompiler::CanConvertUnboxedMintToDouble() {
  return false;
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
  Assembler* assembler = compiler->assembler();
#define __ assembler->
  __ Comment("%s", Name());
  __ Bind(entry_label());
  if (FLAG_trap_on_deoptimization) {
    __ int3();
  }

  ASSERT(deopt_env() != NULL);

  __ pushq(CODE_REG);
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
  Label fall_through;
  __ CompareObject(bool_register, Object::null_object());
  __ j(EQUAL, &fall_through, Assembler::kNearJump);
  __ CompareObject(bool_register, Bool::True());
  __ j(EQUAL, is_true);
  __ jmp(is_false);
  __ Bind(&fall_through);
}


// Clobbers RCX.
RawSubtypeTestCache* FlowGraphCompiler::GenerateCallSubtypeTestStub(
    TypeTestStubKind test_kind,
    Register instance_reg,
    Register type_arguments_reg,
    Register temp_reg,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  const SubtypeTestCache& type_test_cache =
      SubtypeTestCache::ZoneHandle(zone(), SubtypeTestCache::New());
  __ LoadUniqueObject(temp_reg, type_test_cache);
  __ pushq(temp_reg);      // Subtype test cache.
  __ pushq(instance_reg);  // Instance.
  if (test_kind == kTestTypeOneArg) {
    ASSERT(type_arguments_reg == kNoRegister);
    __ PushObject(Object::null_object());
    __ Call(*StubCode::Subtype1TestCache_entry());
  } else if (test_kind == kTestTypeTwoArgs) {
    ASSERT(type_arguments_reg == kNoRegister);
    __ PushObject(Object::null_object());
    __ Call(*StubCode::Subtype2TestCache_entry());
  } else if (test_kind == kTestTypeThreeArgs) {
    __ pushq(type_arguments_reg);
    __ Call(*StubCode::Subtype3TestCache_entry());
  } else {
    UNREACHABLE();
  }
  // Result is in RCX: null -> not found, otherwise Bool::True or Bool::False.
  ASSERT(instance_reg != RCX);
  ASSERT(temp_reg != RCX);
  __ popq(instance_reg);  // Discard.
  __ popq(instance_reg);  // Restore receiver.
  __ popq(temp_reg);      // Discard.
  GenerateBoolToJump(RCX, is_instance_lbl, is_not_instance_lbl);
  return type_test_cache.raw();
}


// Jumps to labels 'is_instance' or 'is_not_instance' respectively, if
// type test is conclusive, otherwise fallthrough if a type test could not
// be completed.
// RAX: instance (must survive).
// Clobbers R10.
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
  const Register kInstanceReg = RAX;
  Error& bound_error = Error::Handle(zone());
  const Type& int_type = Type::Handle(zone(), Type::IntType());
  const bool smi_is_ok =
      int_type.IsSubtypeOf(type, &bound_error, NULL, Heap::kOld);
  // Malformed type should have been handled at graph construction time.
  ASSERT(smi_is_ok || bound_error.IsNull());
  __ testq(kInstanceReg, Immediate(kSmiTagMask));
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
      const Register kClassIdReg = R10;
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
  const Register kTypeArgumentsReg = kNoRegister;
  const Register kTempReg = R10;
  return GenerateCallSubtypeTestStub(kTestTypeTwoArgs, kInstanceReg,
                                     kTypeArgumentsReg, kTempReg,
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
// RAX: instance to test against (preserved).
// Clobbers R10, R13.
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

  const Register kInstanceReg = RAX;
  __ testq(kInstanceReg, Immediate(kSmiTagMask));
  // If instance is Smi, check directly.
  const Class& smi_class = Class::Handle(zone(), Smi::Class());
  if (smi_class.IsSubtypeOf(TypeArguments::Handle(zone()), type_class,
                            TypeArguments::Handle(zone()), NULL, NULL,
                            Heap::kOld)) {
    __ j(ZERO, is_instance_lbl);
  } else {
    __ j(ZERO, is_not_instance_lbl);
  }
  const Register kClassIdReg = R10;
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
    __ cmpq(kClassIdReg, Immediate(kClosureCid));
    __ j(EQUAL, is_instance_lbl);
    return true;
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
// RAX: instance to test.
// Clobbers R10, R13.
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
  const Register kInstanceReg = RAX;
  __ LoadClass(R10, kInstanceReg);
  // R10: instance class.
  // Check immediate superclass equality.
  __ movq(R13, FieldAddress(R10, Class::super_type_offset()));
  __ movq(R13, FieldAddress(R13, Type::type_class_id_offset()));
  __ CompareImmediate(R13, Immediate(Smi::RawValue(type_class.id())));
  __ j(EQUAL, is_instance_lbl);

  const Register kTypeArgumentsReg = kNoRegister;
  const Register kTempReg = R10;
  return GenerateCallSubtypeTestStub(kTestTypeOneArg, kInstanceReg,
                                     kTypeArgumentsReg, kTempReg,
                                     is_instance_lbl, is_not_instance_lbl);
}


// Generates inlined check if 'type' is a type parameter or type itself
// RAX: instance (preserved).
// Clobbers RDI, RDX, R10.
RawSubtypeTestCache* FlowGraphCompiler::GenerateUninstantiatedTypeTest(
    TokenPosition token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  __ Comment("UninstantiatedTypeTest");
  ASSERT(!type.IsInstantiated());
  // Skip check if destination is a dynamic type.
  if (type.IsTypeParameter()) {
    const TypeParameter& type_param = TypeParameter::Cast(type);
    // Load instantiator type arguments on stack.
    __ movq(RDX, Address(RSP, 0));  // Get instantiator type arguments.
    // RDX: instantiator type arguments.
    // Check if type arguments are null, i.e. equivalent to vector of dynamic.
    __ CompareObject(RDX, Object::null_object());
    __ j(EQUAL, is_instance_lbl);
    __ movq(RDI, FieldAddress(
                     RDX, TypeArguments::type_at_offset(type_param.index())));
    // RDI: Concrete type of type.
    // Check if type argument is dynamic.
    __ CompareObject(RDI, Object::dynamic_type());
    __ j(EQUAL, is_instance_lbl);
    const Type& object_type = Type::ZoneHandle(zone(), Type::ObjectType());
    __ CompareObject(RDI, object_type);
    __ j(EQUAL, is_instance_lbl);

    // For Smi check quickly against int and num interfaces.
    Label not_smi;
    __ testq(RAX, Immediate(kSmiTagMask));  // Value is Smi?
    __ j(NOT_ZERO, &not_smi, Assembler::kNearJump);
    __ CompareObject(RDI, Type::ZoneHandle(zone(), Type::IntType()));
    __ j(EQUAL, is_instance_lbl);
    __ CompareObject(RDI, Type::ZoneHandle(zone(), Type::Number()));
    __ j(EQUAL, is_instance_lbl);
    // Smi must be handled in runtime.
    Label fall_through;
    __ jmp(&fall_through);

    __ Bind(&not_smi);
    // RDX: instantiator type arguments.
    // RAX: instance.
    const Register kInstanceReg = RAX;
    const Register kTypeArgumentsReg = RDX;
    const Register kTempReg = R10;
    const SubtypeTestCache& type_test_cache = SubtypeTestCache::ZoneHandle(
        zone(), GenerateCallSubtypeTestStub(
                    kTestTypeThreeArgs, kInstanceReg, kTypeArgumentsReg,
                    kTempReg, is_instance_lbl, is_not_instance_lbl));
    __ Bind(&fall_through);
    return type_test_cache.raw();
  }
  if (type.IsType()) {
    const Register kInstanceReg = RAX;
    const Register kTypeArgumentsReg = RDX;
    __ testq(kInstanceReg, Immediate(kSmiTagMask));  // Is instance Smi?
    __ j(ZERO, is_not_instance_lbl);
    __ movq(kTypeArgumentsReg, Address(RSP, 0));  // Instantiator type args.
    // Uninstantiated type class is known at compile time, but the type
    // arguments are determined at runtime by the instantiator.
    const Register kTempReg = R10;
    return GenerateCallSubtypeTestStub(kTestTypeThreeArgs, kInstanceReg,
                                       kTypeArgumentsReg, kTempReg,
                                       is_instance_lbl, is_not_instance_lbl);
  }
  return SubtypeTestCache::null();
}


// Inputs:
// - RAX: instance to test against (preserved).
// - RDX: optional instantiator type arguments (preserved).
// Clobbers R10, R13.
// Returns:
// - preserved instance in RAX and optional instantiator type arguments in RDX.
// Note that this inlined code must be followed by the runtime_call code, as it
// may fall through to it. Otherwise, this inline code will jump to the label
// is_instance or to the label is_not_instance.
RawSubtypeTestCache* FlowGraphCompiler::GenerateInlineInstanceof(
    TokenPosition token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  __ Comment("InlineInstanceof");
  if (type.IsVoidType()) {
    // A non-null value is returned from a void function, which will result in a
    // type error. A null value is handled prior to executing this inline code.
    return SubtypeTestCache::null();
  }
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
// - NULL -> return false.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs:
// - RAX: object.
// - RDX: instantiator type arguments or raw_null.
// Clobbers RDX.
// Returns:
// - true or false in RAX.
void FlowGraphCompiler::GenerateInstanceOf(TokenPosition token_pos,
                                           intptr_t deopt_id,
                                           const AbstractType& type,
                                           bool negate_result,
                                           LocationSummary* locs) {
  ASSERT(type.IsFinalized() && !type.IsMalformedOrMalbounded());

  Label is_instance, is_not_instance;
  __ pushq(RDX);  // Store instantiator type arguments.
  // If type is instantiated and non-parameterized, we can inline code
  // checking whether the tested instance is a Smi.
  if (type.IsInstantiated()) {
    // A null object is only an instance of Object and dynamic, which has
    // already been checked above (if the type is instantiated). So we can
    // return false here if the instance is null (and if the type is
    // instantiated).
    // We can only inline this null check if the type is instantiated at compile
    // time, since an uninstantiated type at compile time could be Object or
    // dynamic at run time.
    __ CompareObject(RAX, Object::null_object());
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
    __ movq(RDX, Address(RSP, 0));         // Get instantiator type arguments.
    __ PushObject(Object::null_object());  // Make room for the result.
    __ pushq(RAX);                         // Push the instance.
    __ PushObject(type);                   // Push the type.
    __ pushq(RDX);                         // Instantiator type arguments.
    __ LoadUniqueObject(RAX, test_cache);
    __ pushq(RAX);
    GenerateRuntimeCall(token_pos, deopt_id, kInstanceofRuntimeEntry, 4, locs);
    // Pop the parameters supplied to the runtime entry. The result of the
    // instanceof runtime call will be left as the result of the operation.
    __ Drop(4);
    if (negate_result) {
      __ popq(RDX);
      __ LoadObject(RAX, Bool::True());
      __ cmpq(RDX, RAX);
      __ j(NOT_EQUAL, &done, Assembler::kNearJump);
      __ LoadObject(RAX, Bool::False());
    } else {
      __ popq(RAX);
    }
    __ jmp(&done, Assembler::kNearJump);
  }
  __ Bind(&is_not_instance);
  __ LoadObject(RAX, Bool::Get(negate_result));
  __ jmp(&done, Assembler::kNearJump);

  __ Bind(&is_instance);
  __ LoadObject(RAX, Bool::Get(!negate_result));
  __ Bind(&done);
  __ popq(RDX);  // Remove pushed instantiator type arguments.
}


// Optimize assignable type check by adding inlined tests for:
// - NULL -> return NULL.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs:
// - RAX: object.
// - RDX: instantiator type arguments or raw_null.
// Returns:
// - object in RAX for successful assignable check (or throws TypeError).
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
         (!dst_type.IsDynamicType() && !dst_type.IsObjectType()));
  __ pushq(RDX);  // Store instantiator type arguments.
  // A null object is always assignable and is returned as result.
  Label is_assignable, runtime_call;
  __ CompareObject(RAX, Object::null_object());
  __ j(EQUAL, &is_assignable);

  // Generate throw new TypeError() if the type is malformed or malbounded.
  if (dst_type.IsMalformedOrMalbounded()) {
    __ PushObject(Object::null_object());  // Make room for the result.
    __ pushq(RAX);                         // Push the source object.
    __ PushObject(dst_name);               // Push the name of the destination.
    __ PushObject(dst_type);               // Push the type of the destination.
    GenerateRuntimeCall(token_pos, deopt_id, kBadTypeErrorRuntimeEntry, 3,
                        locs);
    // We should never return here.
    __ int3();

    __ Bind(&is_assignable);  // For a null object.
    __ popq(RDX);             // Remove pushed instantiator type arguments.
    return;
  }

  // Generate inline type check, linking to runtime call if not assignable.
  SubtypeTestCache& test_cache = SubtypeTestCache::ZoneHandle(zone());
  test_cache = GenerateInlineInstanceof(token_pos, dst_type, &is_assignable,
                                        &runtime_call);

  __ Bind(&runtime_call);
  __ movq(RDX, Address(RSP, 0));         // Get instantiator type arguments.
  __ PushObject(Object::null_object());  // Make room for the result.
  __ pushq(RAX);                         // Push the source object.
  __ PushObject(dst_type);               // Push the type of the destination.
  __ pushq(RDX);                         // Instantiator type arguments.
  __ PushObject(dst_name);               // Push the name of the destination.
  __ LoadUniqueObject(RAX, test_cache);
  __ pushq(RAX);
  GenerateRuntimeCall(token_pos, deopt_id, kTypeCheckRuntimeEntry, 5, locs);
  // Pop the parameters supplied to the runtime entry. The result of the
  // type check runtime call is the checked value.
  __ Drop(5);
  __ popq(RAX);

  __ Bind(&is_assignable);
  __ popq(RDX);  // Remove pushed instantiator type arguments.
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
      __ pushq(value.ToStackSlotAddress());
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

  __ movq(RCX,
          FieldAddress(R10, ArgumentsDescriptor::positional_count_offset()));
  // Check that min_num_pos_args <= num_pos_args.
  Label wrong_num_arguments;
  __ CompareImmediate(RCX, Immediate(Smi::RawValue(min_num_pos_args)));
  __ j(LESS, &wrong_num_arguments);
  // Check that num_pos_args <= max_num_pos_args.
  __ CompareImmediate(RCX, Immediate(Smi::RawValue(max_num_pos_args)));
  __ j(GREATER, &wrong_num_arguments);

  // Copy positional arguments.
  // Argument i passed at fp[kParamEndSlotFromFp + num_args - i] is copied
  // to fp[kFirstLocalSlotFromFp - i].

  __ movq(RBX, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
  // Since RBX and RCX are Smi, use TIMES_4 instead of TIMES_8.
  // Let RBX point to the last passed positional argument, i.e. to
  // fp[kParamEndSlotFromFp + num_args - (num_pos_args - 1)].
  __ subq(RBX, RCX);
  __ leaq(RBX,
          Address(RBP, RBX, TIMES_4, (kParamEndSlotFromFp + 1) * kWordSize));

  // Let RDI point to the last copied positional argument, i.e. to
  // fp[kFirstLocalSlotFromFp - (num_pos_args - 1)].
  __ SmiUntag(RCX);
  __ movq(RAX, RCX);
  __ negq(RAX);
  // -num_pos_args is in RAX.
  __ leaq(RDI,
          Address(RBP, RAX, TIMES_8, (kFirstLocalSlotFromFp + 1) * kWordSize));
  Label loop, loop_condition;
  __ jmp(&loop_condition, Assembler::kNearJump);
  // We do not use the final allocation index of the variable here, i.e.
  // scope->VariableAt(i)->index(), because captured variables still need
  // to be copied to the context that is not yet allocated.
  const Address argument_addr(RBX, RCX, TIMES_8, 0);
  const Address copy_addr(RDI, RCX, TIMES_8, 0);
  __ Bind(&loop);
  __ movq(RAX, argument_addr);
  __ movq(copy_addr, RAX);
  __ Bind(&loop_condition);
  __ decq(RCX);
  __ j(POSITIVE, &loop, Assembler::kNearJump);

  // Copy or initialize optional named arguments.
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
    __ movq(RBX, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
    // Let RBX point to the first passed argument, i.e. to
    // fp[kParamEndSlotFromFp + num_args]; num_args (RBX) is Smi.
    __ leaq(RBX, Address(RBP, RBX, TIMES_4, kParamEndSlotFromFp * kWordSize));
    // Let RDI point to the entry of the first named argument.
    __ leaq(RDI,
            FieldAddress(R10, ArgumentsDescriptor::first_named_entry_offset()));
    for (int i = 0; i < num_opt_named_params; i++) {
      Label load_default_value, assign_optional_parameter;
      const int param_pos = opt_param_position[i];
      // Check if this named parameter was passed in.
      // Load RAX with the name of the argument.
      __ movq(RAX, Address(RDI, ArgumentsDescriptor::name_offset()));
      ASSERT(opt_param[i]->name().IsSymbol());
      __ CompareObject(RAX, opt_param[i]->name());
      __ j(NOT_EQUAL, &load_default_value, Assembler::kNearJump);
      // Load RAX with passed-in argument at provided arg_pos, i.e. at
      // fp[kParamEndSlotFromFp + num_args - arg_pos].
      __ movq(RAX, Address(RDI, ArgumentsDescriptor::position_offset()));
      // RAX is arg_pos as Smi.
      // Point to next named entry.
      __ AddImmediate(RDI, Immediate(ArgumentsDescriptor::named_entry_size()));
      __ negq(RAX);
      Address argument_addr(RBX, RAX, TIMES_4, 0);  // RAX is a negative Smi.
      __ movq(RAX, argument_addr);
      __ jmp(&assign_optional_parameter, Assembler::kNearJump);
      __ Bind(&load_default_value);
      // Load RAX with default argument.
      const Instance& value = parsed_function().DefaultParameterValueAt(
          param_pos - num_fixed_params);
      __ LoadObject(RAX, value);
      __ Bind(&assign_optional_parameter);
      // Assign RAX to fp[kFirstLocalSlotFromFp - param_pos].
      // We do not use the final allocation index of the variable here, i.e.
      // scope->VariableAt(i)->index(), because captured variables still need
      // to be copied to the context that is not yet allocated.
      const intptr_t computed_param_pos = kFirstLocalSlotFromFp - param_pos;
      const Address param_addr(RBP, computed_param_pos * kWordSize);
      __ movq(param_addr, RAX);
    }
    delete[] opt_param;
    delete[] opt_param_position;
    if (check_correct_named_args) {
      // Check that RDI now points to the null terminator in the arguments
      // descriptor.
      __ LoadObject(TMP, Object::null_object());
      __ cmpq(Address(RDI, 0), TMP);
      __ j(EQUAL, &all_arguments_processed, Assembler::kNearJump);
    }
  } else {
    ASSERT(num_opt_pos_params > 0);
    __ movq(RCX,
            FieldAddress(R10, ArgumentsDescriptor::positional_count_offset()));
    __ SmiUntag(RCX);
    for (int i = 0; i < num_opt_pos_params; i++) {
      Label next_parameter;
      // Handle this optional positional parameter only if k or fewer positional
      // arguments have been passed, where k is param_pos, the position of this
      // optional parameter in the formal parameter list.
      const int param_pos = num_fixed_params + i;
      __ CompareImmediate(RCX, Immediate(param_pos));
      __ j(GREATER, &next_parameter, Assembler::kNearJump);
      // Load RAX with default argument.
      const Object& value = parsed_function().DefaultParameterValueAt(i);
      __ LoadObject(RAX, value);
      // Assign RAX to fp[kFirstLocalSlotFromFp - param_pos].
      // We do not use the final allocation index of the variable here, i.e.
      // scope->VariableAt(i)->index(), because captured variables still need
      // to be copied to the context that is not yet allocated.
      const intptr_t computed_param_pos = kFirstLocalSlotFromFp - param_pos;
      const Address param_addr(RBP, computed_param_pos * kWordSize);
      __ movq(param_addr, RAX);
      __ Bind(&next_parameter);
    }
    if (check_correct_named_args) {
      __ movq(RBX, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
      __ SmiUntag(RBX);
      // Check that RCX equals RBX, i.e. no named arguments passed.
      __ cmpq(RCX, RBX);
      __ j(EQUAL, &all_arguments_processed, Assembler::kNearJump);
    }
  }

  __ Bind(&wrong_num_arguments);
  if (function.IsClosureFunction()) {
    __ LeaveDartFrame(kKeepCalleePP);  // The arguments are still on the stack.
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

  // R10 : arguments descriptor array.
  __ movq(RCX, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
  __ SmiUntag(RCX);
  __ LoadObject(R12, Object::null_object());
  Label null_args_loop, null_args_loop_condition;
  __ jmp(&null_args_loop_condition, Assembler::kNearJump);
  const Address original_argument_addr(RBP, RCX, TIMES_8,
                                       (kParamEndSlotFromFp + 1) * kWordSize);
  __ Bind(&null_args_loop);
  __ movq(original_argument_addr, R12);
  __ Bind(&null_args_loop_condition);
  __ decq(RCX);
  __ j(POSITIVE, &null_args_loop, Assembler::kNearJump);
}


void FlowGraphCompiler::GenerateInlinedGetter(intptr_t offset) {
  // TOS: return address.
  // +1 : receiver.
  // Sequence node has one return node, its input is load field node.
  __ Comment("Inlined Getter");
  __ movq(RAX, Address(RSP, 1 * kWordSize));
  __ movq(RAX, FieldAddress(RAX, offset));
  __ ret();
}


void FlowGraphCompiler::GenerateInlinedSetter(intptr_t offset) {
  // TOS: return address.
  // +1 : value
  // +2 : receiver.
  // Sequence node has one store node and one return NULL node.
  __ Comment("Inlined Setter");
  __ movq(RAX, Address(RSP, 2 * kWordSize));  // Receiver.
  __ movq(RBX, Address(RSP, 1 * kWordSize));  // Value.
  __ StoreIntoObject(RAX, FieldAddress(RAX, offset), RBX);
  __ LoadObject(RAX, Object::null_object());
  __ ret();
}


// NOTE: If the entry code shape changes, ReturnAddressLocator in profiler.cc
// needs to be updated to match.
void FlowGraphCompiler::EmitFrameEntry() {
  if (flow_graph().IsCompiledForOsr()) {
    intptr_t extra_slots = StackSize() - flow_graph().num_stack_locals() -
                           flow_graph().num_copied_params();
    ASSERT(extra_slots >= 0);
    __ EnterOsrFrame(extra_slots * kWordSize);
  } else {
    const Register new_pp = R13;
    __ LoadPoolPointer(new_pp);

    const Function& function = parsed_function().function();
    if (CanOptimizeFunction() && function.IsOptimizable() &&
        (!is_optimizing() || may_reoptimize())) {
      __ Comment("Invocation Count Check");
      const Register function_reg = RDI;
      // Load function object using the callee's pool pointer.
      __ LoadFunctionFromCalleePool(function_reg, function, new_pp);

      // Reoptimization of an optimized function is triggered by counting in
      // IC stubs, but not at the entry of the function.
      if (!is_optimizing()) {
        __ incl(FieldAddress(function_reg, Function::usage_counter_offset()));
      }
      __ cmpl(FieldAddress(function_reg, Function::usage_counter_offset()),
              Immediate(GetOptimizationThreshold()));
      ASSERT(function_reg == RDI);
      __ J(GREATER_EQUAL, *StubCode::OptimizeFunction_entry(), new_pp);
    }
    ASSERT(StackSize() >= 0);
    __ Comment("Enter frame");
    __ EnterDartFrame(StackSize() * kWordSize, new_pp);
  }
}


void FlowGraphCompiler::CompileGraph() {
  InitCompiler();
  const Function& function = parsed_function().function();

#ifdef DART_PRECOMPILER
  if (function.IsDynamicFunction()) {
    __ MonomorphicCheckedEntry();
  }
#endif  // DART_PRECOMPILER

  if (TryIntrinsify()) {
    // Skip regular code generation.
    return;
  }

  EmitFrameEntry();
  ASSERT(assembler()->constant_pool_allowed());

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
      __ movq(RAX, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
      __ CompareImmediate(RAX, Immediate(Smi::RawValue(num_fixed_params)));
      __ j(NOT_EQUAL, &wrong_num_arguments, Assembler::kNearJump);
      __ cmpq(RAX, FieldAddress(
                       R10, ArgumentsDescriptor::positional_count_offset()));
      __ j(EQUAL, &correct_num_arguments, Assembler::kNearJump);

      __ Bind(&wrong_num_arguments);
      __ LeaveDartFrame(kKeepCalleePP);  // Leave arguments on the stack.
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
    __ movq(CTX, Address(RBP, closure_parameter->index() * kWordSize));
    __ movq(CTX, FieldAddress(CTX, Closure::context_offset()));
#ifdef DEBUG
    Label ok;
    __ LoadClassId(RAX, CTX);
    __ cmpq(RAX, Immediate(kContextCid));
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
      __ LoadObject(RAX, Object::null_object());
    }
    for (intptr_t i = 0; i < num_locals; ++i) {
      // Subtract index i (locals lie at lower addresses than RBP).
      if (((slot_base - i) == context_index)) {
        if (function.IsClosureFunction()) {
          __ movq(Address(RBP, (slot_base - i) * kWordSize), CTX);
        } else {
          const Context& empty_context = Context::ZoneHandle(
              zone(), isolate()->object_store()->empty_context());
          __ StoreObject(Address(RBP, (slot_base - i) * kWordSize),
                         empty_context);
        }
      } else {
        ASSERT(num_locals > 1);
        __ movq(Address(RBP, (slot_base - i) * kWordSize), RAX);
      }
    }
  }

  EndCodeSourceRange(TokenPosition::kDartCodePrologue);
  ASSERT(!block_order().is_empty());
  VisitBlocks();

  __ int3();
  ASSERT(assembler()->constant_pool_allowed());
  GenerateDeferredCode();
}


void FlowGraphCompiler::GenerateCall(TokenPosition token_pos,
                                     const StubEntry& stub_entry,
                                     RawPcDescriptors::Kind kind,
                                     LocationSummary* locs) {
  __ Call(stub_entry);
  AddCurrentDescriptor(kind, Thread::kNoDeoptId, token_pos);
  RecordSafepoint(locs);
}


void FlowGraphCompiler::GeneratePatchableCall(TokenPosition token_pos,
                                              const StubEntry& stub_entry,
                                              RawPcDescriptors::Kind kind,
                                              LocationSummary* locs) {
  __ CallPatchable(stub_entry);
  AddCurrentDescriptor(kind, Thread::kNoDeoptId, token_pos);
  RecordSafepoint(locs);
}


void FlowGraphCompiler::GenerateDartCall(intptr_t deopt_id,
                                         TokenPosition token_pos,
                                         const StubEntry& stub_entry,
                                         RawPcDescriptors::Kind kind,
                                         LocationSummary* locs) {
  __ CallPatchable(stub_entry);
  AddCurrentDescriptor(kind, deopt_id, token_pos);
  RecordSafepoint(locs);
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
  // Call sites to the same target can share object pool entries. These
  // call sites are never patched for breakpoints: the function is deoptimized
  // and the unoptimized code with IC calls for static calls is patched instead.
  ASSERT(is_optimizing());
  __ CallWithEquivalence(stub_entry, target);

  AddCurrentDescriptor(kind, deopt_id, token_pos);
  RecordSafepoint(locs);
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
  AddStaticCallTarget(target);
}


void FlowGraphCompiler::GenerateRuntimeCall(TokenPosition token_pos,
                                            intptr_t deopt_id,
                                            const RuntimeEntry& entry,
                                            intptr_t argument_count,
                                            LocationSummary* locs) {
  __ CallRuntime(entry, argument_count);
  AddCurrentDescriptor(RawPcDescriptors::kOther, deopt_id, token_pos);
  RecordSafepoint(locs);
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
  const StubEntry* stub_entry =
      StubCode::UnoptimizedStaticCallEntry(ic_data.NumArgsTested());
  __ LoadObject(RBX, ic_data);
  GenerateDartCall(deopt_id, token_pos, *stub_entry,
                   RawPcDescriptors::kUnoptStaticCall, locs);
  __ Drop(argument_count, RCX);
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
  __ IncrementSmiField(FieldAddress(RAX, Array::element_offset(edge_id)), 1);
}


void FlowGraphCompiler::EmitOptimizedInstanceCall(const StubEntry& stub_entry,
                                                  const ICData& ic_data,
                                                  intptr_t argument_count,
                                                  intptr_t deopt_id,
                                                  TokenPosition token_pos,
                                                  LocationSummary* locs) {
  ASSERT(Array::Handle(zone(), ic_data.arguments_descriptor()).Length() > 0);
  // Each ICData propagated from unoptimized to optimized code contains the
  // function that corresponds to the Dart function of that IC call. Due
  // to inlining in optimized code, that function may not correspond to the
  // top-level function (parsed_function().function()) which could be
  // reoptimized and which counter needs to be incremented.
  // Pass the function explicitly, it is used in IC stub.
  __ LoadObject(RDI, parsed_function().function());
  __ LoadUniqueObject(RBX, ic_data);
  GenerateDartCall(deopt_id, token_pos, stub_entry, RawPcDescriptors::kIcCall,
                   locs);
  __ Drop(argument_count, RCX);
}


void FlowGraphCompiler::EmitInstanceCall(const StubEntry& stub_entry,
                                         const ICData& ic_data,
                                         intptr_t argument_count,
                                         intptr_t deopt_id,
                                         TokenPosition token_pos,
                                         LocationSummary* locs) {
  ASSERT(Array::Handle(zone(), ic_data.arguments_descriptor()).Length() > 0);
  __ LoadUniqueObject(RBX, ic_data);
  GenerateDartCall(deopt_id, token_pos, stub_entry, RawPcDescriptors::kIcCall,
                   locs);
  __ Drop(argument_count, RCX);
}


void FlowGraphCompiler::EmitMegamorphicInstanceCall(
    const ICData& ic_data,
    intptr_t argument_count,
    intptr_t deopt_id,
    TokenPosition token_pos,
    LocationSummary* locs,
    intptr_t try_index,
    intptr_t slow_path_argument_count) {
  const String& name = String::Handle(zone(), ic_data.target_name());
  const Array& arguments_descriptor =
      Array::ZoneHandle(zone(), ic_data.arguments_descriptor());
  ASSERT(!arguments_descriptor.IsNull() && (arguments_descriptor.Length() > 0));
  const MegamorphicCache& cache = MegamorphicCache::ZoneHandle(
      zone(),
      MegamorphicCacheTable::Lookup(isolate(), name, arguments_descriptor));
  __ Comment("MegamorphicCall");
  // Load receiver into RDI.
  __ movq(RDI, Address(RSP, (argument_count - 1) * kWordSize));
  Label done;
  if (ShouldInlineSmiStringHashCode(ic_data)) {
    Label megamorphic_call;
    __ Comment("Inlined get:hashCode for Smi and OneByteString");
    __ movq(RAX, RDI);  // Move Smi hashcode to RAX.
    __ testq(RDI, Immediate(kSmiTagMask));
    __ j(ZERO, &done, Assembler::kNearJump);  // It is Smi, we are done.

    __ CompareClassId(RDI, kOneByteStringCid);
    __ j(NOT_EQUAL, &megamorphic_call, Assembler::kNearJump);
    __ movq(RAX, FieldAddress(RDI, String::hash_offset()));
    __ cmpq(RAX, Immediate(0));
    __ j(NOT_EQUAL, &done, Assembler::kNearJump);

    __ Bind(&megamorphic_call);
    __ Comment("Slow case: megamorphic call");
  }
  __ LoadObject(RBX, cache);
  __ call(Address(THR, Thread::megamorphic_call_checked_entry_offset()));

  __ Bind(&done);
  RecordSafepoint(locs, slow_path_argument_count);
  const intptr_t deopt_id_after = Thread::ToDeoptAfter(deopt_id);
  if (FLAG_precompiled_mode) {
    // Megamorphic calls may occur in slow path stubs.
    // If valid use try_index argument.
    if (try_index == CatchClauseNode::kInvalidTryIndex) {
      try_index = CurrentTryIndex();
    }
    pc_descriptors_list()->AddDescriptor(
        RawPcDescriptors::kOther, assembler()->CodeSize(), Thread::kNoDeoptId,
        token_pos, try_index);
  } else if (is_optimizing()) {
    AddCurrentDescriptor(RawPcDescriptors::kOther, Thread::kNoDeoptId,
                         token_pos);
    AddDeoptIndexAtCall(deopt_id_after);
  } else {
    AddCurrentDescriptor(RawPcDescriptors::kOther, Thread::kNoDeoptId,
                         token_pos);
    // Add deoptimization continuation point after the call and before the
    // arguments are removed.
    AddCurrentDescriptor(RawPcDescriptors::kDeopt, deopt_id_after, token_pos);
  }
  __ Drop(argument_count, RCX);
}


void FlowGraphCompiler::EmitSwitchableInstanceCall(const ICData& ic_data,
                                                   intptr_t argument_count,
                                                   intptr_t deopt_id,
                                                   TokenPosition token_pos,
                                                   LocationSummary* locs) {
  ASSERT(ic_data.NumArgsTested() == 1);
  const Code& initial_stub =
      Code::ZoneHandle(StubCode::ICCallThroughFunction_entry()->code());

  __ Comment("SwitchableCall");
  __ movq(RDI, Address(RSP, (argument_count - 1) * kWordSize));
  __ LoadUniqueObject(CODE_REG, initial_stub);
  __ movq(RCX, FieldAddress(CODE_REG, Code::checked_entry_point_offset()));
  __ LoadUniqueObject(RBX, ic_data);
  __ call(RCX);

  AddCurrentDescriptor(RawPcDescriptors::kOther, Thread::kNoDeoptId, token_pos);
  RecordSafepoint(locs);
  const intptr_t deopt_id_after = Thread::ToDeoptAfter(deopt_id);
  if (is_optimizing()) {
    AddDeoptIndexAtCall(deopt_id_after);
  } else {
    // Add deoptimization continuation point after the call and before the
    // arguments are removed.
    AddCurrentDescriptor(RawPcDescriptors::kDeopt, deopt_id_after, token_pos);
  }
  __ Drop(argument_count, RCX);
}


void FlowGraphCompiler::EmitOptimizedStaticCall(
    const Function& function,
    const Array& arguments_descriptor,
    intptr_t argument_count,
    intptr_t deopt_id,
    TokenPosition token_pos,
    LocationSummary* locs) {
  ASSERT(!function.IsClosureFunction());
  if (function.HasOptionalParameters()) {
    __ LoadObject(R10, arguments_descriptor);
  } else {
    __ xorq(R10, R10);  // GC safe smi zero because of stub.
  }
  // Do not use the code from the function, but let the code be patched so that
  // we can record the outgoing edges to other code.
  GenerateStaticDartCall(deopt_id, token_pos,
                         *StubCode::CallStaticFunction_entry(),
                         RawPcDescriptors::kOther, locs, function);
  __ Drop(argument_count, RCX);
}


Condition FlowGraphCompiler::EmitEqualityRegConstCompare(
    Register reg,
    const Object& obj,
    bool needs_number_check,
    TokenPosition token_pos) {
  ASSERT(!needs_number_check ||
         (!obj.IsMint() && !obj.IsDouble() && !obj.IsBigint()));

  if (obj.IsSmi() && (Smi::Cast(obj).Value() == 0)) {
    ASSERT(!needs_number_check);
    __ testq(reg, reg);
    return EQUAL;
  }

  if (needs_number_check) {
    __ pushq(reg);
    __ PushObject(obj);
    if (is_optimizing()) {
      __ CallPatchable(*StubCode::OptimizedIdenticalWithNumberCheck_entry());
    } else {
      __ CallPatchable(*StubCode::UnoptimizedIdenticalWithNumberCheck_entry());
    }
    if (token_pos.IsReal()) {
      AddCurrentDescriptor(RawPcDescriptors::kRuntimeCall, Thread::kNoDeoptId,
                           token_pos);
    }
    // Stub returns result in flags (result of a cmpq, we need ZF computed).
    __ popq(reg);  // Discard constant.
    __ popq(reg);  // Restore 'reg'.
  } else {
    __ CompareObject(reg, obj);
  }
  return EQUAL;
}


Condition FlowGraphCompiler::EmitEqualityRegRegCompare(
    Register left,
    Register right,
    bool needs_number_check,
    TokenPosition token_pos) {
  if (needs_number_check) {
    __ pushq(left);
    __ pushq(right);
    if (is_optimizing()) {
      __ CallPatchable(*StubCode::OptimizedIdenticalWithNumberCheck_entry());
    } else {
      __ CallPatchable(*StubCode::UnoptimizedIdenticalWithNumberCheck_entry());
    }
    if (token_pos.IsReal()) {
      AddCurrentDescriptor(RawPcDescriptors::kRuntimeCall, Thread::kNoDeoptId,
                           token_pos);
    }
    // Stub returns result in flags (result of a cmpq, we need ZF computed).
    __ popq(right);
    __ popq(left);
  } else {
    __ CompareRegisters(left, right);
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
      __ movq(tmp.reg(), Immediate(0xf7));
    }
  }
}
#endif


void FlowGraphCompiler::EmitTestAndCall(const ICData& ic_data,
                                        intptr_t argument_count,
                                        const Array& argument_names,
                                        Label* failed,
                                        Label* match_found,
                                        intptr_t deopt_id,
                                        TokenPosition token_index,
                                        LocationSummary* locs,
                                        bool complete) {
  ASSERT(is_optimizing());

  __ Comment("EmitTestAndCall");
  const Array& arguments_descriptor = Array::ZoneHandle(
      zone(), ArgumentsDescriptor::New(argument_count, argument_names));
  // Load receiver into RAX.
  __ movq(RAX, Address(RSP, (argument_count - 1) * kWordSize));
  __ LoadObject(R10, arguments_descriptor);

  const bool kFirstCheckIsSmi = ic_data.GetReceiverClassIdAt(0) == kSmiCid;
  const intptr_t kNumChecks = ic_data.NumberOfChecks();

  ASSERT(!ic_data.IsNull() && (kNumChecks > 0));

  Label after_smi_test;
  if (kFirstCheckIsSmi) {
    __ testq(RAX, Immediate(kSmiTagMask));
    // Jump if receiver is not Smi.
    if (kNumChecks == 1) {
      __ j(NOT_ZERO, failed);
    } else {
      __ j(NOT_ZERO, &after_smi_test);
    }
    // Do not use the code from the function, but let the code be patched so
    // that we can record the outgoing edges to other code.
    const Function& function =
        Function::ZoneHandle(zone(), ic_data.GetTargetAt(0));
    GenerateStaticDartCall(deopt_id, token_index,
                           *StubCode::CallStaticFunction_entry(),
                           RawPcDescriptors::kOther, locs, function);
    __ Drop(argument_count, RCX);
    if (kNumChecks > 1) {
      __ jmp(match_found);
    }
  } else {
    // Receiver is Smi, but Smi is not a valid class therefore fail.
    // (Smi class must be first in the list).
    if (!complete) {
      __ testq(RAX, Immediate(kSmiTagMask));
      __ j(ZERO, failed);
    }
  }
  __ Bind(&after_smi_test);

  ASSERT(!ic_data.IsNull() && (kNumChecks > 0));
  GrowableArray<CidTarget> sorted(kNumChecks);
  SortICDataByCount(ic_data, &sorted, /* drop_smi = */ true);

  const intptr_t kSortedLen = sorted.length();
  // If kSortedLen is 0 then only a Smi check was needed; the Smi check above
  // will fail if there was only one check and receiver is not Smi.
  if (kSortedLen == 0) return;

  // Value is not Smi,
  __ LoadClassId(RDI, RAX);
  for (intptr_t i = 0; i < kSortedLen; i++) {
    const bool kIsLastCheck = (i == (kSortedLen - 1));
    ASSERT(sorted[i].cid != kSmiCid);
    Label next_test;
    if (!complete) {
      __ cmpl(RDI, Immediate(sorted[i].cid));
      if (kIsLastCheck) {
        __ j(NOT_EQUAL, failed);
      } else {
        __ j(NOT_EQUAL, &next_test);
      }
    } else {
      if (!kIsLastCheck) {
        __ cmpl(RDI, Immediate(sorted[i].cid));
        __ j(NOT_EQUAL, &next_test);
      }
    }
    // Do not use the code from the function, but let the code be patched so
    // that we can record the outgoing edges to other code.
    const Function& function = *sorted[i].target;
    GenerateStaticDartCall(deopt_id, token_index,
                           *StubCode::CallStaticFunction_entry(),
                           RawPcDescriptors::kOther, locs, function);
    __ Drop(argument_count, RCX);
    if (!kIsLastCheck) {
      __ jmp(match_found);
    }
    __ Bind(&next_test);
  }
}


#undef __
#define __ compiler_->assembler()->


void ParallelMoveResolver::EmitMove(int index) {
  MoveOperands* move = moves_[index];
  const Location source = move->src();
  const Location destination = move->dest();

  if (source.IsRegister()) {
    if (destination.IsRegister()) {
      __ movq(destination.reg(), source.reg());
    } else {
      ASSERT(destination.IsStackSlot());
      __ movq(destination.ToStackSlotAddress(), source.reg());
    }
  } else if (source.IsStackSlot()) {
    if (destination.IsRegister()) {
      __ movq(destination.reg(), source.ToStackSlotAddress());
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
    const Object& constant = source.constant();
    if (destination.IsRegister()) {
      if (constant.IsSmi() && (Smi::Cast(constant).Value() == 0)) {
        __ xorq(destination.reg(), destination.reg());
      } else if (constant.IsSmi() &&
                 (source.constant_instruction()->representation() ==
                  kUnboxedInt32)) {
        __ movl(destination.reg(), Immediate(Smi::Cast(constant).Value()));
      } else {
        __ LoadObject(destination.reg(), constant);
      }
    } else if (destination.IsFpuRegister()) {
      if (Utils::DoublesBitEqual(Double::Cast(constant).value(), 0.0)) {
        __ xorps(destination.fpu_reg(), destination.fpu_reg());
      } else {
        __ LoadObject(TMP, constant);
        __ movsd(destination.fpu_reg(),
                 FieldAddress(TMP, Double::value_offset()));
      }
    } else if (destination.IsDoubleStackSlot()) {
      if (Utils::DoublesBitEqual(Double::Cast(constant).value(), 0.0)) {
        __ xorps(XMM0, XMM0);
      } else {
        __ LoadObject(TMP, constant);
        __ movsd(XMM0, FieldAddress(TMP, Double::value_offset()));
      }
      __ movsd(destination.ToStackSlotAddress(), XMM0);
    } else {
      ASSERT(destination.IsStackSlot());
      if (constant.IsSmi() &&
          (source.constant_instruction()->representation() == kUnboxedInt32)) {
        __ movl(destination.ToStackSlotAddress(),
                Immediate(Smi::Cast(constant).Value()));
      } else {
        StoreObject(destination.ToStackSlotAddress(), constant);
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
    __ xchgq(destination.reg(), source.reg());
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
    Address slot_address = source.IsFpuRegister()
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
  __ MoveMemoryToMemory(dst, src);
}


void ParallelMoveResolver::StoreObject(const Address& dst, const Object& obj) {
  __ StoreObject(dst, obj);
}


void ParallelMoveResolver::Exchange(Register reg, const Address& mem) {
  __ Exchange(reg, mem);
}


void ParallelMoveResolver::Exchange(const Address& mem1, const Address& mem2) {
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
  __ AddImmediate(RSP, Immediate(-kFpuRegisterSize));
  __ movups(Address(RSP, 0), reg);
}


void ParallelMoveResolver::RestoreFpuScratch(FpuRegister reg) {
  __ movups(reg, Address(RSP, 0));
  __ AddImmediate(RSP, Immediate(kFpuRegisterSize));
}


#undef __

}  // namespace dart

#endif  // defined TARGET_ARCH_X64

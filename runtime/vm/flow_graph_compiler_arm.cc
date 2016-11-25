// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

#include "vm/flow_graph_compiler.h"

#include "vm/ast_printer.h"
#include "vm/compiler.h"
#include "vm/cpu.h"
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
DEFINE_FLAG(bool, unbox_doubles, true, "Optimize double arithmetic.");
DECLARE_FLAG(bool, enable_simd_inline);


FlowGraphCompiler::~FlowGraphCompiler() {
  // BlockInfos are zone-allocated, so their destructors are not called.
  // Verify the labels explicitly here.
  for (int i = 0; i < block_info_.length(); ++i) {
    ASSERT(!block_info_[i]->jump_label()->IsLinked());
  }
}


bool FlowGraphCompiler::SupportsUnboxedDoubles() {
  return TargetCPUFeatures::vfp_supported() && FLAG_unbox_doubles;
}


bool FlowGraphCompiler::SupportsUnboxedMints() {
  return FLAG_unbox_mints;
}


bool FlowGraphCompiler::SupportsUnboxedSimd128() {
  return TargetCPUFeatures::neon_supported() && FLAG_enable_simd_inline;
}


bool FlowGraphCompiler::SupportsSinCos() {
  return false;
}


bool FlowGraphCompiler::SupportsHardwareDivision() {
  return TargetCPUFeatures::can_divide();
}


bool FlowGraphCompiler::CanConvertUnboxedMintToDouble() {
  // ARM does not have a short instruction sequence for converting int64 to
  // double.
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
    __ bkpt(0);
  }

  ASSERT(deopt_env() != NULL);

  // LR may be live. It will be clobbered by BranchLink, so cache it in IP.
  // It will be restored at the top of the deoptimization stub, specifically in
  // GenerateDeoptimizationSequence in stub_code_arm.cc.
  __ Push(CODE_REG);
  __ mov(IP, Operand(LR));
  __ BranchLink(*StubCode::Deoptimize_entry());
  set_pc_offset(assembler->CodeSize());
#undef __
}


#define __ assembler()->


// Fall through if bool_register contains null.
void FlowGraphCompiler::GenerateBoolToJump(Register bool_register,
                                           Label* is_true,
                                           Label* is_false) {
  Label fall_through;
  __ CompareObject(bool_register, Object::null_object());
  __ b(&fall_through, EQ);
  __ CompareObject(bool_register, Bool::True());
  __ b(is_true, EQ);
  __ b(is_false);
  __ Bind(&fall_through);
}


// R0: instance (must be preserved).
// R1: instantiator type arguments (if used).
RawSubtypeTestCache* FlowGraphCompiler::GenerateCallSubtypeTestStub(
    TypeTestStubKind test_kind,
    Register instance_reg,
    Register type_arguments_reg,
    Register temp_reg,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  ASSERT(instance_reg == R0);
  ASSERT(temp_reg == kNoRegister);  // Unused on ARM.
  const SubtypeTestCache& type_test_cache =
      SubtypeTestCache::ZoneHandle(zone(), SubtypeTestCache::New());
  __ LoadUniqueObject(R2, type_test_cache);
  if (test_kind == kTestTypeOneArg) {
    ASSERT(type_arguments_reg == kNoRegister);
    __ LoadObject(R1, Object::null_object());
    __ BranchLink(*StubCode::Subtype1TestCache_entry());
  } else if (test_kind == kTestTypeTwoArgs) {
    ASSERT(type_arguments_reg == kNoRegister);
    __ LoadObject(R1, Object::null_object());
    __ BranchLink(*StubCode::Subtype2TestCache_entry());
  } else if (test_kind == kTestTypeThreeArgs) {
    ASSERT(type_arguments_reg == R1);
    __ BranchLink(*StubCode::Subtype3TestCache_entry());
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
// Clobbers R2.
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
  const Register kInstanceReg = R0;
  Error& bound_error = Error::Handle(zone());
  const Type& int_type = Type::Handle(zone(), Type::IntType());
  const bool smi_is_ok =
      int_type.IsSubtypeOf(type, &bound_error, NULL, Heap::kOld);
  // Malformed type should have been handled at graph construction time.
  ASSERT(smi_is_ok || bound_error.IsNull());
  __ tst(kInstanceReg, Operand(kSmiTagMask));
  if (smi_is_ok) {
    __ b(is_instance_lbl, EQ);
  } else {
    __ b(is_not_instance_lbl, EQ);
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
      const Register kClassIdReg = R2;
      // dynamic type argument, check only classes.
      __ LoadClassId(kClassIdReg, kInstanceReg);
      __ CompareImmediate(kClassIdReg, type_class.id());
      __ b(is_instance_lbl, EQ);
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
  const Register kTempReg = kNoRegister;
  // R0: instance (must be preserved).
  return GenerateCallSubtypeTestStub(kTestTypeTwoArgs, kInstanceReg,
                                     kTypeArgumentsReg, kTempReg,
                                     is_instance_lbl, is_not_instance_lbl);
}


void FlowGraphCompiler::CheckClassIds(Register class_id_reg,
                                      const GrowableArray<intptr_t>& class_ids,
                                      Label* is_equal_lbl,
                                      Label* is_not_equal_lbl) {
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

  const Register kInstanceReg = R0;
  __ tst(kInstanceReg, Operand(kSmiTagMask));
  // If instance is Smi, check directly.
  const Class& smi_class = Class::Handle(zone(), Smi::Class());
  if (smi_class.IsSubtypeOf(TypeArguments::Handle(zone()), type_class,
                            TypeArguments::Handle(zone()), NULL, NULL,
                            Heap::kOld)) {
    __ b(is_instance_lbl, EQ);
  } else {
    __ b(is_not_instance_lbl, EQ);
  }
  const Register kClassIdReg = R2;
  __ LoadClassId(kClassIdReg, kInstanceReg);
  // See ClassFinalizer::ResolveSuperTypeAndInterfaces for list of restricted
  // interfaces.
  // Bool interface can be implemented only by core class Bool.
  if (type.IsBoolType()) {
    __ CompareImmediate(kClassIdReg, kBoolCid);
    __ b(is_instance_lbl, EQ);
    __ b(is_not_instance_lbl);
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
    __ CompareImmediate(kClassIdReg, kClosureCid);
    __ b(is_instance_lbl, EQ);
    return true;  // Fall through
  }
  // Compare if the classes are equal.
  if (!type_class.is_abstract()) {
    __ CompareImmediate(kClassIdReg, type_class.id());
    __ b(is_instance_lbl, EQ);
  }
  // Otherwise fallthrough.
  return true;
}


// Uses SubtypeTestCache to store instance class and result.
// R0: instance to test.
// Clobbers R1-R4,R9.
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
  const Register kInstanceReg = R0;
  __ LoadClass(R1, kInstanceReg, R2);
  // R1: instance class.
  // Check immediate superclass equality.
  __ ldr(R2, FieldAddress(R1, Class::super_type_offset()));
  __ ldr(R2, FieldAddress(R2, Type::type_class_id_offset()));
  __ CompareImmediate(R2, Smi::RawValue(type_class.id()));
  __ b(is_instance_lbl, EQ);

  const Register kTypeArgumentsReg = kNoRegister;
  const Register kTempReg = kNoRegister;
  return GenerateCallSubtypeTestStub(kTestTypeOneArg, kInstanceReg,
                                     kTypeArgumentsReg, kTempReg,
                                     is_instance_lbl, is_not_instance_lbl);
}


// Generates inlined check if 'type' is a type parameter or type itself
// R0: instance (preserved).
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
    __ ldr(R1, Address(SP, 0));  // Get instantiator type arguments.
    // R1: instantiator type arguments.
    // Check if type arguments are null, i.e. equivalent to vector of dynamic.
    __ CompareObject(R1, Object::null_object());
    __ b(is_instance_lbl, EQ);
    __ ldr(R2,
           FieldAddress(R1, TypeArguments::type_at_offset(type_param.index())));
    // R2: concrete type of type.
    // Check if type argument is dynamic.
    __ CompareObject(R2, Object::dynamic_type());
    __ b(is_instance_lbl, EQ);
    __ CompareObject(R2, Type::ZoneHandle(zone(), Type::ObjectType()));
    __ b(is_instance_lbl, EQ);

    // For Smi check quickly against int and num interfaces.
    Label not_smi;
    __ tst(R0, Operand(kSmiTagMask));  // Value is Smi?
    __ b(&not_smi, NE);
    __ CompareObject(R2, Type::ZoneHandle(zone(), Type::IntType()));
    __ b(is_instance_lbl, EQ);
    __ CompareObject(R2, Type::ZoneHandle(zone(), Type::Number()));
    __ b(is_instance_lbl, EQ);
    // Smi must be handled in runtime.
    Label fall_through;
    __ b(&fall_through);

    __ Bind(&not_smi);
    // R1: instantiator type arguments.
    // R0: instance.
    const Register kInstanceReg = R0;
    const Register kTypeArgumentsReg = R1;
    const Register kTempReg = kNoRegister;
    const SubtypeTestCache& type_test_cache = SubtypeTestCache::ZoneHandle(
        zone(), GenerateCallSubtypeTestStub(
                    kTestTypeThreeArgs, kInstanceReg, kTypeArgumentsReg,
                    kTempReg, is_instance_lbl, is_not_instance_lbl));
    __ Bind(&fall_through);
    return type_test_cache.raw();
  }
  if (type.IsType()) {
    const Register kInstanceReg = R0;
    const Register kTypeArgumentsReg = R1;
    __ tst(kInstanceReg, Operand(kSmiTagMask));  // Is instance Smi?
    __ b(is_not_instance_lbl, EQ);
    __ ldr(kTypeArgumentsReg, Address(SP, 0));  // Instantiator type args.
    // Uninstantiated type class is known at compile time, but the type
    // arguments are determined at runtime by the instantiator.
    const Register kTempReg = kNoRegister;
    return GenerateCallSubtypeTestStub(kTestTypeThreeArgs, kInstanceReg,
                                       kTypeArgumentsReg, kTempReg,
                                       is_instance_lbl, is_not_instance_lbl);
  }
  return SubtypeTestCache::null();
}


// Inputs:
// - R0: instance being type checked (preserved).
// - R1: optional instantiator type arguments (preserved).
// Clobbers R2, R3.
// Returns:
// - preserved instance in R0 and optional instantiator type arguments in R1.
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
// - R0: object.
// - R1: instantiator type arguments or raw_null.
// Returns:
// - true or false in R0.
void FlowGraphCompiler::GenerateInstanceOf(TokenPosition token_pos,
                                           intptr_t deopt_id,
                                           const AbstractType& type,
                                           bool negate_result,
                                           LocationSummary* locs) {
  ASSERT(type.IsFinalized() && !type.IsMalformed() && !type.IsMalbounded());

  // Preserve instantiator type arguments (R1).
  __ Push(R1);

  Label is_instance, is_not_instance;
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
    __ CompareObject(R0, Object::null_object());
    __ b(type.IsNullType() ? &is_instance : &is_not_instance, EQ);
  }

  // Generate inline instanceof test.
  SubtypeTestCache& test_cache = SubtypeTestCache::ZoneHandle(zone());
  test_cache =
      GenerateInlineInstanceof(token_pos, type, &is_instance, &is_not_instance);

  // test_cache is null if there is no fall-through.
  Label done;
  if (!test_cache.IsNull()) {
    // Generate runtime call.
    // Load instantiator type arguments (R1).
    __ ldr(R1, Address(SP, 0 * kWordSize));
    __ PushObject(Object::null_object());  // Make room for the result.
    __ Push(R0);                           // Push the instance.
    __ PushObject(type);                   // Push the type.
    __ Push(R1);  // Push instantiator type arguments (R1).
    __ LoadUniqueObject(R0, test_cache);
    __ Push(R0);
    GenerateRuntimeCall(token_pos, deopt_id, kInstanceofRuntimeEntry, 4, locs);
    // Pop the parameters supplied to the runtime entry. The result of the
    // instanceof runtime call will be left as the result of the operation.
    __ Drop(4);
    if (negate_result) {
      __ Pop(R1);
      __ LoadObject(R0, Bool::True());
      __ cmp(R1, Operand(R0));
      __ b(&done, NE);
      __ LoadObject(R0, Bool::False());
    } else {
      __ Pop(R0);
    }
    __ b(&done);
  }
  __ Bind(&is_not_instance);
  __ LoadObject(R0, Bool::Get(negate_result));
  __ b(&done);

  __ Bind(&is_instance);
  __ LoadObject(R0, Bool::Get(!negate_result));
  __ Bind(&done);
  // Remove instantiator type arguments (R1).
  __ Drop(1);
}


// Optimize assignable type check by adding inlined tests for:
// - NULL -> return NULL.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs:
// - R0: instance being type checked.
// - R1: instantiator type arguments or raw_null.
// Returns:
// - object in R0 for successful assignable check (or throws TypeError).
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
  // Preserve instantiator type arguments (R1).
  __ Push(R1);
  // A null object is always assignable and is returned as result.
  Label is_assignable, runtime_call;
  __ CompareObject(R0, Object::null_object());
  __ b(&is_assignable, EQ);

  // Generate throw new TypeError() if the type is malformed or malbounded.
  if (dst_type.IsMalformedOrMalbounded()) {
    __ PushObject(Object::null_object());  // Make room for the result.
    __ Push(R0);                           // Push the source object.
    __ PushObject(dst_name);               // Push the name of the destination.
    __ PushObject(dst_type);               // Push the type of the destination.
    GenerateRuntimeCall(token_pos, deopt_id, kBadTypeErrorRuntimeEntry, 3,
                        locs);
    // We should never return here.
    __ bkpt(0);

    __ Bind(&is_assignable);  // For a null object.
    // Restore instantiator type arguments (R1).
    __ Pop(R1);
    return;
  }

  // Generate inline type check, linking to runtime call if not assignable.
  SubtypeTestCache& test_cache = SubtypeTestCache::ZoneHandle(zone());
  test_cache = GenerateInlineInstanceof(token_pos, dst_type, &is_assignable,
                                        &runtime_call);

  __ Bind(&runtime_call);
  // Load instantiator type arguments (R1).
  __ ldr(R1, Address(SP, 0 * kWordSize));
  __ PushObject(Object::null_object());  // Make room for the result.
  __ Push(R0);                           // Push the source object.
  __ PushObject(dst_type);               // Push the type of the destination.
  __ Push(R1);              // Push instantiator type arguments (R1).
  __ PushObject(dst_name);  // Push the name of the destination.
  __ LoadUniqueObject(R0, test_cache);
  __ Push(R0);
  GenerateRuntimeCall(token_pos, deopt_id, kTypeCheckRuntimeEntry, 5, locs);
  // Pop the parameters supplied to the runtime entry. The result of the
  // type check runtime call is the checked value.
  __ Drop(5);
  __ Pop(R0);

  __ Bind(&is_assignable);
  // Restore instantiator type arguments (R1).
  __ Pop(R1);
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


// Input parameters:
//   R4: arguments descriptor array.
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

  __ ldr(R6, FieldAddress(R4, ArgumentsDescriptor::positional_count_offset()));
  // Check that min_num_pos_args <= num_pos_args.
  Label wrong_num_arguments;
  __ CompareImmediate(R6, Smi::RawValue(min_num_pos_args));
  __ b(&wrong_num_arguments, LT);
  // Check that num_pos_args <= max_num_pos_args.
  __ CompareImmediate(R6, Smi::RawValue(max_num_pos_args));
  __ b(&wrong_num_arguments, GT);

  // Copy positional arguments.
  // Argument i passed at fp[kParamEndSlotFromFp + num_args - i] is copied
  // to fp[kFirstLocalSlotFromFp - i].

  __ ldr(NOTFP, FieldAddress(R4, ArgumentsDescriptor::count_offset()));
  // Since NOTFP and R6 are Smi, use LSL 1 instead of LSL 2.
  // Let NOTFP point to the last passed positional argument, i.e. to
  // fp[kParamEndSlotFromFp + num_args - (num_pos_args - 1)].
  __ sub(NOTFP, NOTFP, Operand(R6));
  __ add(NOTFP, FP, Operand(NOTFP, LSL, 1));
  __ add(NOTFP, NOTFP, Operand((kParamEndSlotFromFp + 1) * kWordSize));

  // Let R8 point to the last copied positional argument, i.e. to
  // fp[kFirstLocalSlotFromFp - (num_pos_args - 1)].
  __ AddImmediate(R8, FP, (kFirstLocalSlotFromFp + 1) * kWordSize);
  __ sub(R8, R8, Operand(R6, LSL, 1));  // R6 is a Smi.
  __ SmiUntag(R6);
  Label loop, loop_condition;
  __ b(&loop_condition);
  // We do not use the final allocation index of the variable here, i.e.
  // scope->VariableAt(i)->index(), because captured variables still need
  // to be copied to the context that is not yet allocated.
  const Address argument_addr(NOTFP, R6, LSL, 2);
  const Address copy_addr(R8, R6, LSL, 2);
  __ Bind(&loop);
  __ ldr(IP, argument_addr);
  __ str(IP, copy_addr);
  __ Bind(&loop_condition);
  __ subs(R6, R6, Operand(1));
  __ b(&loop, PL);

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
    __ ldr(NOTFP, FieldAddress(R4, ArgumentsDescriptor::count_offset()));
    // Let NOTFP point to the first passed argument, i.e. to
    // fp[kParamEndSlotFromFp + num_args - 0]; num_args (NOTFP) is Smi.
    __ add(NOTFP, FP, Operand(NOTFP, LSL, 1));
    __ AddImmediate(NOTFP, NOTFP, kParamEndSlotFromFp * kWordSize);
    // Let R8 point to the entry of the first named argument.
    __ add(R8, R4, Operand(ArgumentsDescriptor::first_named_entry_offset() -
                           kHeapObjectTag));
    for (int i = 0; i < num_opt_named_params; i++) {
      Label load_default_value, assign_optional_parameter;
      const int param_pos = opt_param_position[i];
      // Check if this named parameter was passed in.
      // Load R9 with the name of the argument.
      __ ldr(R9, Address(R8, ArgumentsDescriptor::name_offset()));
      ASSERT(opt_param[i]->name().IsSymbol());
      __ CompareObject(R9, opt_param[i]->name());
      __ b(&load_default_value, NE);
      // Load R9 with passed-in argument at provided arg_pos, i.e. at
      // fp[kParamEndSlotFromFp + num_args - arg_pos].
      __ ldr(R9, Address(R8, ArgumentsDescriptor::position_offset()));
      // R9 is arg_pos as Smi.
      // Point to next named entry.
      __ add(R8, R8, Operand(ArgumentsDescriptor::named_entry_size()));
      __ rsb(R9, R9, Operand(0));
      Address argument_addr(NOTFP, R9, LSL, 1);  // R9 is a negative Smi.
      __ ldr(R9, argument_addr);
      __ b(&assign_optional_parameter);
      __ Bind(&load_default_value);
      // Load R9 with default argument.
      const Instance& value = parsed_function().DefaultParameterValueAt(
          param_pos - num_fixed_params);
      __ LoadObject(R9, value);
      __ Bind(&assign_optional_parameter);
      // Assign R9 to fp[kFirstLocalSlotFromFp - param_pos].
      // We do not use the final allocation index of the variable here, i.e.
      // scope->VariableAt(i)->index(), because captured variables still need
      // to be copied to the context that is not yet allocated.
      const intptr_t computed_param_pos = kFirstLocalSlotFromFp - param_pos;
      const Address param_addr(FP, computed_param_pos * kWordSize);
      __ str(R9, param_addr);
    }
    delete[] opt_param;
    delete[] opt_param_position;
    if (check_correct_named_args) {
      // Check that R8 now points to the null terminator in the arguments
      // descriptor.
      __ ldr(R9, Address(R8, 0));
      __ CompareObject(R9, Object::null_object());
      __ b(&all_arguments_processed, EQ);
    }
  } else {
    ASSERT(num_opt_pos_params > 0);
    __ ldr(R6,
           FieldAddress(R4, ArgumentsDescriptor::positional_count_offset()));
    __ SmiUntag(R6);
    for (int i = 0; i < num_opt_pos_params; i++) {
      Label next_parameter;
      // Handle this optional positional parameter only if k or fewer positional
      // arguments have been passed, where k is param_pos, the position of this
      // optional parameter in the formal parameter list.
      const int param_pos = num_fixed_params + i;
      __ CompareImmediate(R6, param_pos);
      __ b(&next_parameter, GT);
      // Load R9 with default argument.
      const Object& value = parsed_function().DefaultParameterValueAt(i);
      __ LoadObject(R9, value);
      // Assign R9 to fp[kFirstLocalSlotFromFp - param_pos].
      // We do not use the final allocation index of the variable here, i.e.
      // scope->VariableAt(i)->index(), because captured variables still need
      // to be copied to the context that is not yet allocated.
      const intptr_t computed_param_pos = kFirstLocalSlotFromFp - param_pos;
      const Address param_addr(FP, computed_param_pos * kWordSize);
      __ str(R9, param_addr);
      __ Bind(&next_parameter);
    }
    if (check_correct_named_args) {
      __ ldr(NOTFP, FieldAddress(R4, ArgumentsDescriptor::count_offset()));
      __ SmiUntag(NOTFP);
      // Check that R6 equals NOTFP, i.e. no named arguments passed.
      __ cmp(R6, Operand(NOTFP));
      __ b(&all_arguments_processed, EQ);
    }
  }

  __ Bind(&wrong_num_arguments);
  if (function.IsClosureFunction()) {
    __ LeaveDartFrame(kKeepCalleePP);  // The arguments are still on the stack.
    __ Branch(*StubCode::CallClosureNoSuchMethod_entry());
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

  // R4 : arguments descriptor array.
  __ ldr(R6, FieldAddress(R4, ArgumentsDescriptor::count_offset()));
  __ SmiUntag(R6);
  __ add(NOTFP, FP, Operand((kParamEndSlotFromFp + 1) * kWordSize));
  const Address original_argument_addr(NOTFP, R6, LSL, 2);
  __ LoadObject(IP, Object::null_object());
  Label null_args_loop, null_args_loop_condition;
  __ b(&null_args_loop_condition);
  __ Bind(&null_args_loop);
  __ str(IP, original_argument_addr);
  __ Bind(&null_args_loop_condition);
  __ subs(R6, R6, Operand(1));
  __ b(&null_args_loop, PL);
}


void FlowGraphCompiler::GenerateInlinedGetter(intptr_t offset) {
  // LR: return address.
  // SP: receiver.
  // Sequence node has one return node, its input is load field node.
  __ Comment("Inlined Getter");
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ LoadFieldFromOffset(kWord, R0, R0, offset);
  __ Ret();
}


void FlowGraphCompiler::GenerateInlinedSetter(intptr_t offset) {
  // LR: return address.
  // SP+1: receiver.
  // SP+0: value.
  // Sequence node has one store node and one return NULL node.
  __ Comment("Inlined Setter");
  __ ldr(R0, Address(SP, 1 * kWordSize));  // Receiver.
  __ ldr(R1, Address(SP, 0 * kWordSize));  // Value.
  __ StoreIntoObjectOffset(R0, offset, R1);
  __ LoadObject(R0, Object::null_object());
  __ Ret();
}


static const Register new_pp = NOTFP;


void FlowGraphCompiler::EmitFrameEntry() {
  const Function& function = parsed_function().function();
  if (CanOptimizeFunction() && function.IsOptimizable() &&
      (!is_optimizing() || may_reoptimize())) {
    __ Comment("Invocation Count Check");
    const Register function_reg = R8;
    // The pool pointer is not setup before entering the Dart frame.
    // Temporarily setup pool pointer for this dart function.
    __ LoadPoolPointer(new_pp);
    // Load function object from object pool.
    __ LoadFunctionFromCalleePool(function_reg, function, new_pp);

    __ ldr(R3, FieldAddress(function_reg, Function::usage_counter_offset()));
    // Reoptimization of an optimized function is triggered by counting in
    // IC stubs, but not at the entry of the function.
    if (!is_optimizing()) {
      __ add(R3, R3, Operand(1));
      __ str(R3, FieldAddress(function_reg, Function::usage_counter_offset()));
    }
    __ CompareImmediate(R3, GetOptimizationThreshold());
    ASSERT(function_reg == R8);
    __ Branch(*StubCode::OptimizeFunction_entry(), kNotPatchable, new_pp, GE);
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


// Input parameters:
//   LR: return address.
//   SP: address of last argument.
//   FP: caller's frame pointer.
//   PP: caller's pool pointer.
//   R9: ic-data.
//   R4: arguments descriptor array.
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
      __ ldr(R0, FieldAddress(R4, ArgumentsDescriptor::count_offset()));
      __ CompareImmediate(R0, Smi::RawValue(num_fixed_params));
      __ b(&wrong_num_arguments, NE);
      __ ldr(R1,
             FieldAddress(R4, ArgumentsDescriptor::positional_count_offset()));
      __ cmp(R0, Operand(R1));
      __ b(&correct_num_arguments, EQ);
      __ Bind(&wrong_num_arguments);
      ASSERT(assembler()->constant_pool_allowed());
      __ LeaveDartFrame(kKeepCalleePP);  // Arguments are still on the stack.
      __ Branch(*StubCode::CallClosureNoSuchMethod_entry());
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
    __ ldr(CTX, Address(FP, closure_parameter->index() * kWordSize));
    __ ldr(CTX, FieldAddress(CTX, Closure::context_offset()));
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
      __ LoadObject(R0, Object::null_object());
    }
    for (intptr_t i = 0; i < num_locals; ++i) {
      // Subtract index i (locals lie at lower addresses than FP).
      if (((slot_base - i) == context_index)) {
        if (function.IsClosureFunction()) {
          __ StoreToOffset(kWord, CTX, FP, (slot_base - i) * kWordSize);
        } else {
          const Context& empty_context = Context::ZoneHandle(
              zone(), isolate()->object_store()->empty_context());
          __ LoadObject(R1, empty_context);
          __ StoreToOffset(kWord, R1, FP, (slot_base - i) * kWordSize);
        }
      } else {
        ASSERT(num_locals > 1);
        __ StoreToOffset(kWord, R0, FP, (slot_base - i) * kWordSize);
      }
    }
  }

  EndCodeSourceRange(TokenPosition::kDartCodePrologue);
  VisitBlocks();

  __ bkpt(0);
  ASSERT(assembler()->constant_pool_allowed());
  GenerateDeferredCode();
}


void FlowGraphCompiler::GenerateCall(TokenPosition token_pos,
                                     const StubEntry& stub_entry,
                                     RawPcDescriptors::Kind kind,
                                     LocationSummary* locs) {
  __ BranchLink(stub_entry);
  AddCurrentDescriptor(kind, Thread::kNoDeoptId, token_pos);
  RecordSafepoint(locs);
}


void FlowGraphCompiler::GeneratePatchableCall(TokenPosition token_pos,
                                              const StubEntry& stub_entry,
                                              RawPcDescriptors::Kind kind,
                                              LocationSummary* locs) {
  __ BranchLinkPatchable(stub_entry);
  AddCurrentDescriptor(kind, Thread::kNoDeoptId, token_pos);
  RecordSafepoint(locs);
}


void FlowGraphCompiler::GenerateDartCall(intptr_t deopt_id,
                                         TokenPosition token_pos,
                                         const StubEntry& stub_entry,
                                         RawPcDescriptors::Kind kind,
                                         LocationSummary* locs) {
  __ BranchLinkPatchable(stub_entry);
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
  __ BranchLinkWithEquivalence(stub_entry, target);

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
#if defined(DEBUG)
  bool old_use_far_branches = assembler_->use_far_branches();
  assembler_->set_use_far_branches(true);
#endif  // DEBUG
  __ LoadFieldFromOffset(kWord, R1, R0, Array::element_offset(edge_id));
  __ add(R1, R1, Operand(Smi::RawValue(1)));
  __ StoreIntoObjectNoBarrierOffset(R0, Array::element_offset(edge_id), R1);
#if defined(DEBUG)
  assembler_->set_use_far_branches(old_use_far_branches);
#endif  // DEBUG
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

  __ LoadObject(R8, parsed_function().function());
  __ LoadUniqueObject(R9, ic_data);
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
  ASSERT(Array::Handle(zone(), ic_data.arguments_descriptor()).Length() > 0);
  __ LoadUniqueObject(R9, ic_data);
  GenerateDartCall(deopt_id, token_pos, stub_entry, RawPcDescriptors::kIcCall,
                   locs);
  __ Drop(argument_count);
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
  // Load receiver into R0.
  __ LoadFromOffset(kWord, R0, SP, (argument_count - 1) * kWordSize);
  Label done;
  if (ShouldInlineSmiStringHashCode(ic_data)) {
    Label megamorphic_call;
    __ Comment("Inlined get:hashCode for Smi and OneByteString");
    __ tst(R0, Operand(kSmiTagMask));
    __ b(&done, EQ);  // Is Smi (result is receiver).

    // Use R9 (cache for megamorphic call) as scratch.
    __ CompareClassId(R0, kOneByteStringCid, R9);
    __ b(&megamorphic_call, NE);

    __ mov(R9, Operand(R0));  // Preserve receiver in R9.
    __ ldr(R0, FieldAddress(R0, String::hash_offset()));
    ASSERT(Smi::New(0) == 0);
    __ cmp(R0, Operand(0));

    __ b(&done, NE);          // Return if already computed.
    __ mov(R0, Operand(R9));  // Restore receiver in R0.

    __ Bind(&megamorphic_call);
    __ Comment("Slow case: megamorphic call");
  }
  __ LoadObject(R9, cache);
  __ ldr(LR, Address(THR, Thread::megamorphic_call_checked_entry_offset()));
  __ blx(LR);

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
  __ Drop(argument_count);
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

  __ LoadFromOffset(kWord, R0, SP, (argument_count - 1) * kWordSize);
  __ LoadUniqueObject(CODE_REG, initial_stub);
  __ ldr(LR, FieldAddress(CODE_REG, Code::checked_entry_point_offset()));
  __ LoadUniqueObject(R9, ic_data);
  __ blx(LR);

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
  __ Drop(argument_count);
}


void FlowGraphCompiler::EmitUnoptimizedStaticCall(intptr_t argument_count,
                                                  intptr_t deopt_id,
                                                  TokenPosition token_pos,
                                                  LocationSummary* locs,
                                                  const ICData& ic_data) {
  const StubEntry* stub_entry =
      StubCode::UnoptimizedStaticCallEntry(ic_data.NumArgsTested());
  __ LoadObject(R9, ic_data);
  GenerateDartCall(deopt_id, token_pos, *stub_entry,
                   RawPcDescriptors::kUnoptStaticCall, locs);
  __ Drop(argument_count);
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
    __ LoadObject(R4, arguments_descriptor);
  } else {
    __ LoadImmediate(R4, 0);  // GC safe smi zero because of stub.
  }
  // Do not use the code from the function, but let the code be patched so that
  // we can record the outgoing edges to other code.
  GenerateStaticDartCall(deopt_id, token_pos,
                         *StubCode::CallStaticFunction_entry(),
                         RawPcDescriptors::kOther, locs, function);
  __ Drop(argument_count);
}


Condition FlowGraphCompiler::EmitEqualityRegConstCompare(
    Register reg,
    const Object& obj,
    bool needs_number_check,
    TokenPosition token_pos) {
  if (needs_number_check) {
    ASSERT(!obj.IsMint() && !obj.IsDouble() && !obj.IsBigint());
    __ Push(reg);
    __ PushObject(obj);
    if (is_optimizing()) {
      __ BranchLinkPatchable(
          *StubCode::OptimizedIdenticalWithNumberCheck_entry());
    } else {
      __ BranchLinkPatchable(
          *StubCode::UnoptimizedIdenticalWithNumberCheck_entry());
    }
    if (token_pos.IsReal()) {
      AddCurrentDescriptor(RawPcDescriptors::kRuntimeCall, Thread::kNoDeoptId,
                           token_pos);
    }
    // Stub returns result in flags (result of a cmp, we need Z computed).
    __ Drop(1);   // Discard constant.
    __ Pop(reg);  // Restore 'reg'.
  } else {
    __ CompareObject(reg, obj);
  }
  return EQ;
}


Condition FlowGraphCompiler::EmitEqualityRegRegCompare(
    Register left,
    Register right,
    bool needs_number_check,
    TokenPosition token_pos) {
  if (needs_number_check) {
    __ Push(left);
    __ Push(right);
    if (is_optimizing()) {
      __ BranchLinkPatchable(
          *StubCode::OptimizedIdenticalWithNumberCheck_entry());
    } else {
      __ BranchLinkPatchable(
          *StubCode::UnoptimizedIdenticalWithNumberCheck_entry());
    }
    if (token_pos.IsReal()) {
      AddCurrentDescriptor(RawPcDescriptors::kRuntimeCall, Thread::kNoDeoptId,
                           token_pos);
    }
    // Stub returns result in flags (result of a cmp, we need Z computed).
    __ Pop(right);
    __ Pop(left);
  } else {
    __ cmp(left, Operand(right));
  }
  return EQ;
}


// This function must be in sync with FlowGraphCompiler::RecordSafepoint and
// FlowGraphCompiler::SlowPathEnvironmentFor.
void FlowGraphCompiler::SaveLiveRegisters(LocationSummary* locs) {
#if defined(DEBUG)
  locs->CheckWritableInputs();
  ClobberDeadTempRegisters(locs);
#endif

  // TODO(vegorov): consider saving only caller save (volatile) registers.
  const intptr_t fpu_regs_count = locs->live_registers()->FpuRegisterCount();
  if (fpu_regs_count > 0) {
    __ AddImmediate(SP, -(fpu_regs_count * kFpuRegisterSize));
    // Store fpu registers with the lowest register number at the lowest
    // address.
    intptr_t offset = 0;
    for (intptr_t i = 0; i < kNumberOfFpuRegisters; ++i) {
      QRegister fpu_reg = static_cast<QRegister>(i);
      if (locs->live_registers()->ContainsFpuRegister(fpu_reg)) {
        DRegister d1 = EvenDRegisterOf(fpu_reg);
        DRegister d2 = OddDRegisterOf(fpu_reg);
        // TODO(regis): merge stores using vstmd instruction.
        __ vstrd(d1, Address(SP, offset));
        __ vstrd(d2, Address(SP, offset + 2 * kWordSize));
        offset += kFpuRegisterSize;
      }
    }
    ASSERT(offset == (fpu_regs_count * kFpuRegisterSize));
  }

  // The order in which the registers are pushed must match the order
  // in which the registers are encoded in the safe point's stack map.
  // NOTE: This matches the order of ARM's multi-register push.
  RegList reg_list = 0;
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; --i) {
    Register reg = static_cast<Register>(i);
    if (locs->live_registers()->ContainsRegister(reg)) {
      reg_list |= (1 << reg);
    }
  }
  if (reg_list != 0) {
    __ PushList(reg_list);
  }
}


void FlowGraphCompiler::RestoreLiveRegisters(LocationSummary* locs) {
  RegList reg_list = 0;
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; --i) {
    Register reg = static_cast<Register>(i);
    if (locs->live_registers()->ContainsRegister(reg)) {
      reg_list |= (1 << reg);
    }
  }
  if (reg_list != 0) {
    __ PopList(reg_list);
  }

  const intptr_t fpu_regs_count = locs->live_registers()->FpuRegisterCount();
  if (fpu_regs_count > 0) {
    // Fpu registers have the lowest register number at the lowest address.
    intptr_t offset = 0;
    for (intptr_t i = 0; i < kNumberOfFpuRegisters; ++i) {
      QRegister fpu_reg = static_cast<QRegister>(i);
      if (locs->live_registers()->ContainsFpuRegister(fpu_reg)) {
        DRegister d1 = EvenDRegisterOf(fpu_reg);
        DRegister d2 = OddDRegisterOf(fpu_reg);
        // TODO(regis): merge loads using vldmd instruction.
        __ vldrd(d1, Address(SP, offset));
        __ vldrd(d2, Address(SP, offset + 2 * kWordSize));
        offset += kFpuRegisterSize;
      }
    }
    ASSERT(offset == (fpu_regs_count * kFpuRegisterSize));
    __ AddImmediate(SP, offset);
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
      __ mov(tmp.reg(), Operand(0xf7));
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

  // Load receiver into R0.
  __ LoadFromOffset(kWord, R0, SP, (argument_count - 1) * kWordSize);
  __ LoadObject(R4, arguments_descriptor);

  const bool kFirstCheckIsSmi = ic_data.GetReceiverClassIdAt(0) == kSmiCid;
  const intptr_t kNumChecks = ic_data.NumberOfChecks();

  ASSERT(!ic_data.IsNull() && (kNumChecks > 0));

  Label after_smi_test;
  if (kFirstCheckIsSmi) {
    __ tst(R0, Operand(kSmiTagMask));
    // Jump if receiver is not Smi.
    if (kNumChecks == 1) {
      __ b(failed, NE);
    } else {
      __ b(&after_smi_test, NE);
    }
    // Do not use the code from the function, but let the code be patched so
    // that we can record the outgoing edges to other code.
    const Function& function =
        Function::ZoneHandle(zone(), ic_data.GetTargetAt(0));
    GenerateStaticDartCall(deopt_id, token_index,
                           *StubCode::CallStaticFunction_entry(),
                           RawPcDescriptors::kOther, locs, function);
    __ Drop(argument_count);
    if (kNumChecks > 1) {
      __ b(match_found);
    }
  } else {
    // Receiver is Smi, but Smi is not a valid class therefore fail.
    // (Smi class must be first in the list).
    if (!complete) {
      __ tst(R0, Operand(kSmiTagMask));
      __ b(failed, EQ);
    }
  }
  __ Bind(&after_smi_test);

  ASSERT(!ic_data.IsNull() && (kNumChecks > 0));
  GrowableArray<CidTarget> sorted(kNumChecks);
  SortICDataByCount(ic_data, &sorted, /* drop_smi = */ true);

  // Value is not Smi,
  const intptr_t kSortedLen = sorted.length();
  // If kSortedLen is 0 then only a Smi check was needed; the Smi check above
  // will fail if there was only one check and receiver is not Smi.
  if (kSortedLen == 0) return;

  __ LoadClassId(R2, R0);
  for (intptr_t i = 0; i < kSortedLen; i++) {
    const bool kIsLastCheck = (i == (kSortedLen - 1));
    ASSERT(sorted[i].cid != kSmiCid);
    Label next_test;
    if (!complete) {
      __ CompareImmediate(R2, sorted[i].cid);
      if (kIsLastCheck) {
        __ b(failed, NE);
      } else {
        __ b(&next_test, NE);
      }
    } else {
      if (!kIsLastCheck) {
        __ CompareImmediate(R2, sorted[i].cid);
        __ b(&next_test, NE);
      }
    }
    // Do not use the code from the function, but let the code be patched so
    // that we can record the outgoing edges to other code.
    const Function& function = *sorted[i].target;
    GenerateStaticDartCall(deopt_id, token_index,
                           *StubCode::CallStaticFunction_entry(),
                           RawPcDescriptors::kOther, locs, function);
    __ Drop(argument_count);
    if (!kIsLastCheck) {
      __ b(match_found);
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
      __ mov(destination.reg(), Operand(source.reg()));
    } else {
      ASSERT(destination.IsStackSlot());
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      __ StoreToOffset(kWord, source.reg(), destination.base_reg(),
                       dest_offset);
    }
  } else if (source.IsStackSlot()) {
    if (destination.IsRegister()) {
      const intptr_t source_offset = source.ToStackSlotOffset();
      __ LoadFromOffset(kWord, destination.reg(), source.base_reg(),
                        source_offset);
    } else {
      ASSERT(destination.IsStackSlot());
      const intptr_t source_offset = source.ToStackSlotOffset();
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      __ LoadFromOffset(kWord, TMP, source.base_reg(), source_offset);
      __ StoreToOffset(kWord, TMP, destination.base_reg(), dest_offset);
    }
  } else if (source.IsFpuRegister()) {
    if (destination.IsFpuRegister()) {
      if (TargetCPUFeatures::neon_supported()) {
        __ vmovq(destination.fpu_reg(), source.fpu_reg());
      } else {
        // If we're not inlining simd values, then only the even numbered D
        // register will have anything in them.
        __ vmovd(EvenDRegisterOf(destination.fpu_reg()),
                 EvenDRegisterOf(source.fpu_reg()));
      }
    } else {
      if (destination.IsDoubleStackSlot()) {
        const intptr_t dest_offset = destination.ToStackSlotOffset();
        DRegister src = EvenDRegisterOf(source.fpu_reg());
        __ StoreDToOffset(src, destination.base_reg(), dest_offset);
      } else {
        ASSERT(destination.IsQuadStackSlot());
        const intptr_t dest_offset = destination.ToStackSlotOffset();
        const DRegister dsrc0 = EvenDRegisterOf(source.fpu_reg());
        __ StoreMultipleDToOffset(dsrc0, 2, destination.base_reg(),
                                  dest_offset);
      }
    }
  } else if (source.IsDoubleStackSlot()) {
    if (destination.IsFpuRegister()) {
      const intptr_t source_offset = source.ToStackSlotOffset();
      const DRegister dst = EvenDRegisterOf(destination.fpu_reg());
      __ LoadDFromOffset(dst, source.base_reg(), source_offset);
    } else {
      ASSERT(destination.IsDoubleStackSlot());
      const intptr_t source_offset = source.ToStackSlotOffset();
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      __ LoadDFromOffset(DTMP, source.base_reg(), source_offset);
      __ StoreDToOffset(DTMP, destination.base_reg(), dest_offset);
    }
  } else if (source.IsQuadStackSlot()) {
    if (destination.IsFpuRegister()) {
      const intptr_t source_offset = source.ToStackSlotOffset();
      const DRegister dst0 = EvenDRegisterOf(destination.fpu_reg());
      __ LoadMultipleDFromOffset(dst0, 2, source.base_reg(), source_offset);
    } else {
      ASSERT(destination.IsQuadStackSlot());
      const intptr_t source_offset = source.ToStackSlotOffset();
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      const DRegister dtmp0 = DTMP;
      __ LoadMultipleDFromOffset(dtmp0, 2, source.base_reg(), source_offset);
      __ StoreMultipleDToOffset(dtmp0, 2, destination.base_reg(), dest_offset);
    }
  } else {
    ASSERT(source.IsConstant());
    const Object& constant = source.constant();
    if (destination.IsRegister()) {
      if (source.constant_instruction()->representation() == kUnboxedInt32) {
        __ LoadImmediate(destination.reg(), Smi::Cast(constant).Value());
      } else {
        __ LoadObject(destination.reg(), constant);
      }
    } else if (destination.IsFpuRegister()) {
      const DRegister dst = EvenDRegisterOf(destination.fpu_reg());
      if (Utils::DoublesBitEqual(Double::Cast(constant).value(), 0.0) &&
          TargetCPUFeatures::neon_supported()) {
        QRegister qdst = destination.fpu_reg();
        __ veorq(qdst, qdst, qdst);
      } else {
        __ LoadObject(TMP, constant);
        __ AddImmediate(TMP, TMP, Double::value_offset() - kHeapObjectTag);
        __ vldrd(dst, Address(TMP, 0));
      }
    } else if (destination.IsDoubleStackSlot()) {
      if (Utils::DoublesBitEqual(Double::Cast(constant).value(), 0.0) &&
          TargetCPUFeatures::neon_supported()) {
        __ veorq(QTMP, QTMP, QTMP);
      } else {
        __ LoadObject(TMP, constant);
        __ AddImmediate(TMP, TMP, Double::value_offset() - kHeapObjectTag);
        __ vldrd(DTMP, Address(TMP, 0));
      }
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      __ StoreDToOffset(DTMP, destination.base_reg(), dest_offset);
    } else {
      ASSERT(destination.IsStackSlot());
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      if (source.constant_instruction()->representation() == kUnboxedInt32) {
        __ LoadImmediate(TMP, Smi::Cast(constant).Value());
      } else {
        __ LoadObject(TMP, constant);
      }
      __ StoreToOffset(kWord, TMP, destination.base_reg(), dest_offset);
    }
  }

  move->Eliminate();
}


void ParallelMoveResolver::EmitSwap(int index) {
  MoveOperands* move = moves_[index];
  const Location source = move->src();
  const Location destination = move->dest();

  if (source.IsRegister() && destination.IsRegister()) {
    ASSERT(source.reg() != IP);
    ASSERT(destination.reg() != IP);
    __ mov(IP, Operand(source.reg()));
    __ mov(source.reg(), Operand(destination.reg()));
    __ mov(destination.reg(), Operand(IP));
  } else if (source.IsRegister() && destination.IsStackSlot()) {
    Exchange(source.reg(), destination.base_reg(),
             destination.ToStackSlotOffset());
  } else if (source.IsStackSlot() && destination.IsRegister()) {
    Exchange(destination.reg(), source.base_reg(), source.ToStackSlotOffset());
  } else if (source.IsStackSlot() && destination.IsStackSlot()) {
    Exchange(source.base_reg(), source.ToStackSlotOffset(),
             destination.base_reg(), destination.ToStackSlotOffset());
  } else if (source.IsFpuRegister() && destination.IsFpuRegister()) {
    if (TargetCPUFeatures::neon_supported()) {
      const QRegister dst = destination.fpu_reg();
      const QRegister src = source.fpu_reg();
      __ vmovq(QTMP, src);
      __ vmovq(src, dst);
      __ vmovq(dst, QTMP);
    } else {
      const DRegister dst = EvenDRegisterOf(destination.fpu_reg());
      const DRegister src = EvenDRegisterOf(source.fpu_reg());
      __ vmovd(DTMP, src);
      __ vmovd(src, dst);
      __ vmovd(dst, DTMP);
    }
  } else if (source.IsFpuRegister() || destination.IsFpuRegister()) {
    ASSERT(destination.IsDoubleStackSlot() || destination.IsQuadStackSlot() ||
           source.IsDoubleStackSlot() || source.IsQuadStackSlot());
    bool double_width =
        destination.IsDoubleStackSlot() || source.IsDoubleStackSlot();
    QRegister qreg =
        source.IsFpuRegister() ? source.fpu_reg() : destination.fpu_reg();
    DRegister reg = EvenDRegisterOf(qreg);
    Register base_reg =
        source.IsFpuRegister() ? destination.base_reg() : source.base_reg();
    const intptr_t slot_offset = source.IsFpuRegister()
                                     ? destination.ToStackSlotOffset()
                                     : source.ToStackSlotOffset();

    if (double_width) {
      __ LoadDFromOffset(DTMP, base_reg, slot_offset);
      __ StoreDToOffset(reg, base_reg, slot_offset);
      __ vmovd(reg, DTMP);
    } else {
      __ LoadMultipleDFromOffset(DTMP, 2, base_reg, slot_offset);
      __ StoreMultipleDToOffset(reg, 2, base_reg, slot_offset);
      __ vmovq(qreg, QTMP);
    }
  } else if (source.IsDoubleStackSlot() && destination.IsDoubleStackSlot()) {
    const intptr_t source_offset = source.ToStackSlotOffset();
    const intptr_t dest_offset = destination.ToStackSlotOffset();

    ScratchFpuRegisterScope ensure_scratch(this, kNoQRegister);
    DRegister scratch = EvenDRegisterOf(ensure_scratch.reg());
    __ LoadDFromOffset(DTMP, source.base_reg(), source_offset);
    __ LoadDFromOffset(scratch, destination.base_reg(), dest_offset);
    __ StoreDToOffset(DTMP, destination.base_reg(), dest_offset);
    __ StoreDToOffset(scratch, destination.base_reg(), source_offset);
  } else if (source.IsQuadStackSlot() && destination.IsQuadStackSlot()) {
    const intptr_t source_offset = source.ToStackSlotOffset();
    const intptr_t dest_offset = destination.ToStackSlotOffset();

    ScratchFpuRegisterScope ensure_scratch(this, kNoQRegister);
    DRegister scratch = EvenDRegisterOf(ensure_scratch.reg());
    __ LoadMultipleDFromOffset(DTMP, 2, source.base_reg(), source_offset);
    __ LoadMultipleDFromOffset(scratch, 2, destination.base_reg(), dest_offset);
    __ StoreMultipleDToOffset(DTMP, 2, destination.base_reg(), dest_offset);
    __ StoreMultipleDToOffset(scratch, 2, destination.base_reg(),
                              source_offset);
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
  UNREACHABLE();
}


void ParallelMoveResolver::StoreObject(const Address& dst, const Object& obj) {
  UNREACHABLE();
}


// Do not call or implement this function. Instead, use the form below that
// uses an offset from the frame pointer instead of an Address.
void ParallelMoveResolver::Exchange(Register reg, const Address& mem) {
  UNREACHABLE();
}


// Do not call or implement this function. Instead, use the form below that
// uses offsets from the frame pointer instead of Addresses.
void ParallelMoveResolver::Exchange(const Address& mem1, const Address& mem2) {
  UNREACHABLE();
}


void ParallelMoveResolver::Exchange(Register reg,
                                    Register base_reg,
                                    intptr_t stack_offset) {
  ScratchRegisterScope tmp(this, reg);
  __ mov(tmp.reg(), Operand(reg));
  __ LoadFromOffset(kWord, reg, base_reg, stack_offset);
  __ StoreToOffset(kWord, tmp.reg(), base_reg, stack_offset);
}


void ParallelMoveResolver::Exchange(Register base_reg1,
                                    intptr_t stack_offset1,
                                    Register base_reg2,
                                    intptr_t stack_offset2) {
  ScratchRegisterScope tmp1(this, kNoRegister);
  ScratchRegisterScope tmp2(this, tmp1.reg());
  __ LoadFromOffset(kWord, tmp1.reg(), base_reg1, stack_offset1);
  __ LoadFromOffset(kWord, tmp2.reg(), base_reg2, stack_offset2);
  __ StoreToOffset(kWord, tmp1.reg(), base_reg2, stack_offset2);
  __ StoreToOffset(kWord, tmp2.reg(), base_reg1, stack_offset1);
}


void ParallelMoveResolver::SpillScratch(Register reg) {
  __ Push(reg);
}


void ParallelMoveResolver::RestoreScratch(Register reg) {
  __ Pop(reg);
}


void ParallelMoveResolver::SpillFpuScratch(FpuRegister reg) {
  DRegister dreg = EvenDRegisterOf(reg);
  __ vstrd(dreg, Address(SP, -kDoubleSize, Address::PreIndex));
}


void ParallelMoveResolver::RestoreFpuScratch(FpuRegister reg) {
  DRegister dreg = EvenDRegisterOf(reg);
  __ vldrd(dreg, Address(SP, kDoubleSize, Address::PostIndex));
}


#undef __

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM

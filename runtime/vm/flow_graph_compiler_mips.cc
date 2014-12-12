// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_MIPS.
#if defined(TARGET_ARCH_MIPS)

#include "vm/flow_graph_compiler.h"

#include "vm/ast_printer.h"
#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/deopt_instructions.h"
#include "vm/il_printer.h"
#include "vm/locations.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool, trap_on_deoptimization, false, "Trap on deoptimization.");
DECLARE_FLAG(bool, enable_type_checks);


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


bool FlowGraphCompiler::SupportsUnboxedMints() {
  return true;
}


bool FlowGraphCompiler::SupportsUnboxedSimd128() {
  return false;
}


bool FlowGraphCompiler::SupportsSinCos() {
  return false;
}


void FlowGraphCompiler::EnterIntrinsicMode() {
  ASSERT(!intrinsic_mode());
  intrinsic_mode_ = true;
  assembler()->set_allow_constant_pool(false);
}


void FlowGraphCompiler::ExitIntrinsicMode() {
  ASSERT(intrinsic_mode());
  intrinsic_mode_ = false;
  assembler()->set_allow_constant_pool(true);
}


RawDeoptInfo* CompilerDeoptInfo::CreateDeoptInfo(FlowGraphCompiler* compiler,
                                                 DeoptInfoBuilder* builder,
                                                 const Array& deopt_table) {
  if (deopt_env_ == NULL) {
    ++builder->current_info_number_;
    return DeoptInfo::null();
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

  // Current PP, FP, and PC.
  builder->AddPp(current->code(), slot_ix++);
  builder->AddCallerFp(slot_ix++);
  builder->AddReturnAddress(current->code(), deopt_id(), slot_ix++);

  // Callee's PC marker is not used anymore. Pass Code::null() to set to 0.
  builder->AddPcMarker(Code::Handle(), slot_ix++);

  // Emit all values that are needed for materialization as a part of the
  // expression stack for the bottom-most frame. This guarantees that GC
  // will be able to find them during materialization.
  slot_ix = builder->EmitMaterializationArguments(slot_ix);

  // For the innermost environment, set outgoing arguments and the locals.
  for (intptr_t i = current->Length() - 1;
       i >= current->fixed_parameter_count();
       i--) {
    builder->AddCopy(current->ValueAt(i), current->LocationAt(i), slot_ix++);
  }

  Environment* previous = current;
  current = current->outer();
  while (current != NULL) {
    // PP, FP, and PC.
    builder->AddPp(current->code(), slot_ix++);
    builder->AddCallerFp(slot_ix++);

    // For any outer environment the deopt id is that of the call instruction
    // which is recorded in the outer environment.
    builder->AddReturnAddress(current->code(),
                              Isolate::ToDeoptAfter(current->deopt_id()),
                              slot_ix++);

    // PC marker.
    builder->AddPcMarker(previous->code(), slot_ix++);

    // The values of outgoing arguments can be changed from the inlined call so
    // we must read them from the previous environment.
    for (intptr_t i = previous->fixed_parameter_count() - 1; i >= 0; i--) {
      builder->AddCopy(previous->ValueAt(i),
                       previous->LocationAt(i),
                       slot_ix++);
    }

    // Set the locals, note that outgoing arguments are not in the environment.
    for (intptr_t i = current->Length() - 1;
         i >= current->fixed_parameter_count();
         i--) {
      builder->AddCopy(current->ValueAt(i),
                       current->LocationAt(i),
                       slot_ix++);
    }

    // Iterate on the outer environment.
    previous = current;
    current = current->outer();
  }
  // The previous pointer is now the outermost environment.
  ASSERT(previous != NULL);

  // For the outermost environment, set caller PC, caller PP, and caller FP.
  builder->AddCallerPp(slot_ix++);
  builder->AddCallerFp(slot_ix++);
  builder->AddCallerPc(slot_ix++);

  // PC marker.
  builder->AddPcMarker(previous->code(), slot_ix++);

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
  Assembler* assem = compiler->assembler();
#define __ assem->
  __ Comment("%s", Name());
  __ Bind(entry_label());
  if (FLAG_trap_on_deoptimization) {
    __ break_(0);
  }

  ASSERT(deopt_env() != NULL);

  StubCode* stub_code = compiler->isolate()->stub_code();
  __ BranchLink(&stub_code->DeoptimizeLabel());
  set_pc_offset(assem->CodeSize());
#undef __
}


#define __ assembler()->


// Fall through if bool_register contains null.
void FlowGraphCompiler::GenerateBoolToJump(Register bool_register,
                                           Label* is_true,
                                           Label* is_false) {
  __ TraceSimMsg("BoolToJump");
  Label fall_through;
  __ BranchEqual(bool_register, Object::null_object(), &fall_through);
  __ BranchEqual(bool_register, Bool::True(), is_true);
  __ b(is_false);
  __ Bind(&fall_through);
}


// A0: instance (must be preserved).
// A1: instantiator type arguments (if used).
RawSubtypeTestCache* FlowGraphCompiler::GenerateCallSubtypeTestStub(
    TypeTestStubKind test_kind,
    Register instance_reg,
    Register type_arguments_reg,
    Register temp_reg,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  __ TraceSimMsg("CallSubtypeTestStub");
  ASSERT(instance_reg == A0);
  ASSERT(temp_reg == kNoRegister);  // Unused on MIPS.
  const SubtypeTestCache& type_test_cache =
      SubtypeTestCache::ZoneHandle(SubtypeTestCache::New());
  StubCode* stub_code = isolate()->stub_code();
  __ LoadObject(A2, type_test_cache);
  if (test_kind == kTestTypeOneArg) {
    ASSERT(type_arguments_reg == kNoRegister);
    __ LoadImmediate(A1, reinterpret_cast<int32_t>(Object::null()));
    __ BranchLink(&stub_code->Subtype1TestCacheLabel());
  } else if (test_kind == kTestTypeTwoArgs) {
    ASSERT(type_arguments_reg == kNoRegister);
    __ LoadImmediate(A1, reinterpret_cast<int32_t>(Object::null()));
    __ BranchLink(&stub_code->Subtype2TestCacheLabel());
  } else if (test_kind == kTestTypeThreeArgs) {
    ASSERT(type_arguments_reg == A1);
    __ BranchLink(&stub_code->Subtype3TestCacheLabel());
  } else {
    UNREACHABLE();
  }
  // Result is in V0: null -> not found, otherwise Bool::True or Bool::False.
  GenerateBoolToJump(V0, is_instance_lbl, is_not_instance_lbl);
  return type_test_cache.raw();
}


// Jumps to labels 'is_instance' or 'is_not_instance' respectively, if
// type test is conclusive, otherwise fallthrough if a type test could not
// be completed.
// A0: instance being type checked (preserved).
// Clobbers T0.
RawSubtypeTestCache*
FlowGraphCompiler::GenerateInstantiatedTypeWithArgumentsTest(
    intptr_t token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  __ Comment("InstantiatedTypeWithArgumentsTest");
  ASSERT(type.IsInstantiated());
  const Class& type_class = Class::ZoneHandle(type.type_class());
  ASSERT((type_class.NumTypeArguments() > 0) || type_class.IsSignatureClass());
  const Register kInstanceReg = A0;
  Error& malformed_error = Error::Handle();
  const Type& int_type = Type::Handle(Type::IntType());
  const bool smi_is_ok = int_type.IsSubtypeOf(type, &malformed_error);
  // Malformed type should have been handled at graph construction time.
  ASSERT(smi_is_ok || malformed_error.IsNull());
  __ andi(CMPRES1, kInstanceReg, Immediate(kSmiTagMask));
  if (smi_is_ok) {
    __ beq(CMPRES1, ZR, is_instance_lbl);
  } else {
    __ beq(CMPRES1, ZR, is_not_instance_lbl);
  }
  const intptr_t num_type_args = type_class.NumTypeArguments();
  const intptr_t num_type_params = type_class.NumTypeParameters();
  const intptr_t from_index = num_type_args - num_type_params;
  const TypeArguments& type_arguments =
      TypeArguments::ZoneHandle(type.arguments());
  const bool is_raw_type = type_arguments.IsNull() ||
      type_arguments.IsRaw(from_index, num_type_params);
  // Signature class is an instantiated parameterized type.
  if (!type_class.IsSignatureClass()) {
    if (is_raw_type) {
      const Register kClassIdReg = T0;
      // dynamic type argument, check only classes.
      __ LoadClassId(kClassIdReg, kInstanceReg);
      __ BranchEqual(kClassIdReg, Immediate(type_class.id()), is_instance_lbl);
      // List is a very common case.
      if (IsListClass(type_class)) {
        GenerateListTypeCheck(kClassIdReg, is_instance_lbl);
      }
      return GenerateSubtype1TestCacheLookup(
          token_pos, type_class, is_instance_lbl, is_not_instance_lbl);
    }
    // If one type argument only, check if type argument is Object or dynamic.
    if (type_arguments.Length() == 1) {
      const AbstractType& tp_argument = AbstractType::ZoneHandle(
          type_arguments.TypeAt(0));
      ASSERT(!tp_argument.IsMalformed());
      if (tp_argument.IsType()) {
        ASSERT(tp_argument.HasResolvedTypeClass());
        // Check if type argument is dynamic or Object.
        const Type& object_type = Type::Handle(Type::ObjectType());
        if (object_type.IsSubtypeOf(tp_argument, NULL)) {
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
  // A0: instance (must be preserved).
  return GenerateCallSubtypeTestStub(kTestTypeTwoArgs,
                                     kInstanceReg,
                                     kTypeArgumentsReg,
                                     kTempReg,
                                     is_instance_lbl,
                                     is_not_instance_lbl);
}


void FlowGraphCompiler::CheckClassIds(Register class_id_reg,
                                      const GrowableArray<intptr_t>& class_ids,
                                      Label* is_equal_lbl,
                                      Label* is_not_equal_lbl) {
  __ TraceSimMsg("CheckClassIds");
  for (intptr_t i = 0; i < class_ids.length(); i++) {
    __ BranchEqual(class_id_reg, Immediate(class_ids[i]), is_equal_lbl);
  }
  __ b(is_not_equal_lbl);
}


// Testing against an instantiated type with no arguments, without
// SubtypeTestCache.
// A0: instance being type checked (preserved).
// Clobbers: T0, T1, T2
// Returns true if there is a fallthrough.
bool FlowGraphCompiler::GenerateInstantiatedTypeNoArgumentsTest(
    intptr_t token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  __ TraceSimMsg("InstantiatedTypeNoArgumentsTest");
  __ Comment("InstantiatedTypeNoArgumentsTest");
  ASSERT(type.IsInstantiated());
  const Class& type_class = Class::Handle(type.type_class());
  ASSERT(type_class.NumTypeArguments() == 0);

  const Register kInstanceReg = A0;
  __ andi(T0, A0, Immediate(kSmiTagMask));
  // If instance is Smi, check directly.
  const Class& smi_class = Class::Handle(Smi::Class());
  if (smi_class.IsSubtypeOf(TypeArguments::Handle(),
                            type_class,
                            TypeArguments::Handle(),
                            NULL)) {
    __ beq(T0, ZR, is_instance_lbl);
  } else {
    __ beq(T0, ZR, is_not_instance_lbl);
  }
  // Compare if the classes are equal.
  const Register kClassIdReg = T0;
  __ LoadClassId(kClassIdReg, kInstanceReg);
  __ BranchEqual(kClassIdReg, Immediate(type_class.id()), is_instance_lbl);

  // See ClassFinalizer::ResolveSuperTypeAndInterfaces for list of restricted
  // interfaces.
  // Bool interface can be implemented only by core class Bool.
  if (type.IsBoolType()) {
    __ BranchEqual(kClassIdReg, Immediate(kBoolCid), is_instance_lbl);
    __ b(is_not_instance_lbl);
    return false;
  }
  if (type.IsFunctionType()) {
    // Check if instance is a closure.
    __ LoadClassById(T1, kClassIdReg);
    __ lw(T1, FieldAddress(T1, Class::signature_function_offset()));
    __ BranchNotEqual(T1, Object::null_object(), is_instance_lbl);
  }
  // Custom checking for numbers (Smi, Mint, Bigint and Double).
  // Note that instance is not Smi (checked above).
  if (type.IsSubtypeOf(Type::Handle(Type::Number()), NULL)) {
    GenerateNumberTypeCheck(
        kClassIdReg, type, is_instance_lbl, is_not_instance_lbl);
    return false;
  }
  if (type.IsStringType()) {
    GenerateStringTypeCheck(kClassIdReg, is_instance_lbl, is_not_instance_lbl);
    return false;
  }
  // Otherwise fallthrough.
  return true;
}


// Uses SubtypeTestCache to store instance class and result.
// A0: instance to test.
// Clobbers A1, A2, T0-T3.
// Immediate class test already done.
// TODO(srdjan): Implement a quicker subtype check, as type test
// arrays can grow too high, but they may be useful when optimizing
// code (type-feedback).
RawSubtypeTestCache* FlowGraphCompiler::GenerateSubtype1TestCacheLookup(
    intptr_t token_pos,
    const Class& type_class,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  __ TraceSimMsg("Subtype1TestCacheLookup");
  __ Comment("Subtype1TestCacheLookup");
  const Register kInstanceReg = A0;
  __ LoadClass(T0, kInstanceReg);
  // T0: instance class.
  // Check immediate superclass equality.
  __ lw(T0, FieldAddress(T0, Class::super_type_offset()));
  __ lw(T0, FieldAddress(T0, Type::type_class_offset()));
  __ BranchEqual(T0, type_class, is_instance_lbl);

  const Register kTypeArgumentsReg = kNoRegister;
  const Register kTempReg = kNoRegister;
  return GenerateCallSubtypeTestStub(kTestTypeOneArg,
                                     kInstanceReg,
                                     kTypeArgumentsReg,
                                     kTempReg,
                                     is_instance_lbl,
                                     is_not_instance_lbl);
}


// Generates inlined check if 'type' is a type parameter or type itself
// A0: instance (preserved).
RawSubtypeTestCache* FlowGraphCompiler::GenerateUninstantiatedTypeTest(
    intptr_t token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  __ TraceSimMsg("UninstantiatedTypeTest");
  __ Comment("UninstantiatedTypeTest");
  ASSERT(!type.IsInstantiated());
  // Skip check if destination is a dynamic type.
  if (type.IsTypeParameter()) {
    const TypeParameter& type_param = TypeParameter::Cast(type);
    // Load instantiator (or null) and instantiator type arguments on stack.
    __ lw(A1, Address(SP, 0));  // Get instantiator type arguments.
    // A1: instantiator type arguments.
    // Check if type arguments are null, i.e. equivalent to vector of dynamic.
    __ LoadImmediate(T7, reinterpret_cast<int32_t>(Object::null()));
    __ beq(A1, T7, is_instance_lbl);
    __ lw(T2,
        FieldAddress(A1, TypeArguments::type_at_offset(type_param.index())));
    // R2: concrete type of type.
    // Check if type argument is dynamic.
    __ BranchEqual(T2, Type::ZoneHandle(Type::DynamicType()), is_instance_lbl);
    __ BranchEqual(T2, Type::ZoneHandle(Type::ObjectType()), is_instance_lbl);

    // For Smi check quickly against int and num interfaces.
    Label not_smi;
    __ andi(CMPRES1, A0, Immediate(kSmiTagMask));
    __ bne(CMPRES1, ZR, &not_smi);  // Value is Smi?
    __ BranchEqual(T2, Type::ZoneHandle(Type::IntType()), is_instance_lbl);
    __ BranchEqual(T2, Type::ZoneHandle(Type::Number()), is_instance_lbl);
    // Smi must be handled in runtime.
    Label fall_through;
    __ b(&fall_through);

    __ Bind(&not_smi);
    // T1: instantiator type arguments.
    // A0: instance.
    const Register kInstanceReg = A0;
    const Register kTypeArgumentsReg = A1;
    const Register kTempReg = kNoRegister;
    const SubtypeTestCache& type_test_cache =
        SubtypeTestCache::ZoneHandle(
            GenerateCallSubtypeTestStub(kTestTypeThreeArgs,
                                        kInstanceReg,
                                        kTypeArgumentsReg,
                                        kTempReg,
                                        is_instance_lbl,
                                        is_not_instance_lbl));
    __ Bind(&fall_through);
    return type_test_cache.raw();
  }
  if (type.IsType()) {
    const Register kInstanceReg = A0;
    const Register kTypeArgumentsReg = A1;
    __ andi(CMPRES1, kInstanceReg, Immediate(kSmiTagMask));
    __ beq(CMPRES1, ZR, is_not_instance_lbl);  // Is instance Smi?
    __ lw(kTypeArgumentsReg, Address(SP, 0));  // Instantiator type args.
    // Uninstantiated type class is known at compile time, but the type
    // arguments are determined at runtime by the instantiator.
    const Register kTempReg = kNoRegister;
    return GenerateCallSubtypeTestStub(kTestTypeThreeArgs,
                                       kInstanceReg,
                                       kTypeArgumentsReg,
                                       kTempReg,
                                       is_instance_lbl,
                                       is_not_instance_lbl);
  }
  return SubtypeTestCache::null();
}


// Inputs:
// - A0: instance being type checked (preserved).
// - A1: optional instantiator type arguments (preserved).
// Returns:
// - preserved instance in A0 and optional instantiator type arguments in A1.
// Clobbers: T0, T1, T2
// Note that this inlined code must be followed by the runtime_call code, as it
// may fall through to it. Otherwise, this inline code will jump to the label
// is_instance or to the label is_not_instance.
RawSubtypeTestCache* FlowGraphCompiler::GenerateInlineInstanceof(
    intptr_t token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  __ TraceSimMsg("InlineInstanceof");
  __ Comment("InlineInstanceof");
  if (type.IsVoidType()) {
    // A non-null value is returned from a void function, which will result in a
    // type error. A null value is handled prior to executing this inline code.
    return SubtypeTestCache::null();
  }
  if (type.IsInstantiated()) {
    const Class& type_class = Class::ZoneHandle(type.type_class());
    // A class equality check is only applicable with a dst type of a
    // non-parameterized class, non-signature class, or with a raw dst type of
    // a parameterized class.
    if (type_class.IsSignatureClass() || (type_class.NumTypeArguments() > 0)) {
      return GenerateInstantiatedTypeWithArgumentsTest(token_pos,
                                                       type,
                                                       is_instance_lbl,
                                                       is_not_instance_lbl);
      // Fall through to runtime call.
    }
    const bool has_fall_through =
        GenerateInstantiatedTypeNoArgumentsTest(token_pos,
                                                type,
                                                is_instance_lbl,
                                                is_not_instance_lbl);
    if (has_fall_through) {
      // If test non-conclusive so far, try the inlined type-test cache.
      // 'type' is known at compile time.
      return GenerateSubtype1TestCacheLookup(
          token_pos, type_class, is_instance_lbl, is_not_instance_lbl);
    } else {
      return SubtypeTestCache::null();
    }
  }
  return GenerateUninstantiatedTypeTest(token_pos,
                                        type,
                                        is_instance_lbl,
                                        is_not_instance_lbl);
}


// If instanceof type test cannot be performed successfully at compile time and
// therefore eliminated, optimize it by adding inlined tests for:
// - NULL -> return false.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs:
// - A0: object.
// - A1: instantiator type arguments or raw_null.
// - A2: instantiator or raw_null.
// Returns:
// - true or false in V0.
void FlowGraphCompiler::GenerateInstanceOf(intptr_t token_pos,
                                           intptr_t deopt_id,
                                           const AbstractType& type,
                                           bool negate_result,
                                           LocationSummary* locs) {
  ASSERT(type.IsFinalized() && !type.IsMalformed() && !type.IsMalbounded());

  // Preserve instantiator (A2) and its type arguments (A1).
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(A2, Address(SP, 1 * kWordSize));
  __ sw(A1, Address(SP, 0 * kWordSize));

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
    __ BranchEqual(A0, Object::null_object(), &is_not_instance);
  }

  // Generate inline instanceof test.
  SubtypeTestCache& test_cache = SubtypeTestCache::ZoneHandle();
  test_cache = GenerateInlineInstanceof(token_pos, type,
                                        &is_instance, &is_not_instance);

  // test_cache is null if there is no fall-through.
  Label done;
  if (!test_cache.IsNull()) {
    // Generate runtime call.
    // Load instantiator (A2) and its type arguments (A1).
    __ lw(A1, Address(SP, 0 * kWordSize));
    __ lw(A2, Address(SP, 1 * kWordSize));

    __ addiu(SP, SP, Immediate(-6 * kWordSize));
    __ LoadObject(TMP, Object::null_object());
    __ sw(TMP, Address(SP, 5 * kWordSize));  // Make room for the result.
    __ sw(A0, Address(SP, 4 * kWordSize));  // Push the instance.
    __ LoadObject(TMP, type);
    __ sw(TMP, Address(SP, 3 * kWordSize));  // Push the type.
    __ sw(A2, Address(SP, 2 * kWordSize));  // Push instantiator.
    __ sw(A1, Address(SP, 1 * kWordSize));  // Push type arguments.
    __ LoadObject(A0, test_cache);
    __ sw(A0, Address(SP, 0 * kWordSize));
    GenerateRuntimeCall(token_pos, deopt_id, kInstanceofRuntimeEntry, 5, locs);
    // Pop the parameters supplied to the runtime entry. The result of the
    // instanceof runtime call will be left as the result of the operation.
    __ lw(T0, Address(SP, 5 * kWordSize));
    __ addiu(SP, SP, Immediate(6 * kWordSize));
    if (negate_result) {
      __ LoadObject(V0, Bool::True());
      __ bne(T0, V0, &done);
      __ LoadObject(V0, Bool::False());
    } else {
      __ mov(V0, T0);
    }
    __ b(&done);
  }
  __ Bind(&is_not_instance);
  __ LoadObject(V0, Bool::Get(negate_result));
  __ b(&done);

  __ Bind(&is_instance);
  __ LoadObject(V0, Bool::Get(!negate_result));
  __ Bind(&done);
  // Remove instantiator (A2) and its type arguments (A1).
  __ Drop(2);
}


// Optimize assignable type check by adding inlined tests for:
// - NULL -> return NULL.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs:
// - A0: instance being type checked.
// - A1: instantiator type arguments or raw_null.
// - A2: instantiator or raw_null.
// Returns:
// - object in A0 for successful assignable check (or throws TypeError).
// Clobbers: T0, T1, T2
// Performance notes: positive checks must be quick, negative checks can be slow
// as they throw an exception.
void FlowGraphCompiler::GenerateAssertAssignable(intptr_t token_pos,
                                                 intptr_t deopt_id,
                                                 const AbstractType& dst_type,
                                                 const String& dst_name,
                                                 LocationSummary* locs) {
  __ TraceSimMsg("AssertAssignable");
  ASSERT(token_pos >= 0);
  ASSERT(!dst_type.IsNull());
  ASSERT(dst_type.IsFinalized());
  // Assignable check is skipped in FlowGraphBuilder, not here.
  ASSERT(dst_type.IsMalformedOrMalbounded() ||
         (!dst_type.IsDynamicType() && !dst_type.IsObjectType()));
  // Preserve instantiator and its type arguments.
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(A2, Address(SP, 1 * kWordSize));

  // A null object is always assignable and is returned as result.
  Label is_assignable, runtime_call;

  __ BranchEqual(A0, Object::null_object(), &is_assignable);
  __ delay_slot()->sw(A1, Address(SP, 0 * kWordSize));

  // Generate throw new TypeError() if the type is malformed or malbounded.
  if (dst_type.IsMalformedOrMalbounded()) {
    __ addiu(SP, SP, Immediate(-4 * kWordSize));
    __ LoadObject(TMP, Object::null_object());
    __ sw(TMP, Address(SP, 3 * kWordSize));  // Make room for the result.
    __ sw(A0, Address(SP, 2 * kWordSize));  // Push the source object.
    __ LoadObject(TMP, dst_name);
    __ sw(TMP, Address(SP, 1 * kWordSize));  // Push the destination name.
    __ LoadObject(TMP, dst_type);
    __ sw(TMP, Address(SP, 0 * kWordSize));  // Push the destination type.

    GenerateRuntimeCall(token_pos,
                        deopt_id,
                        kBadTypeErrorRuntimeEntry,
                        3,
                        locs);
    // We should never return here.
    __ break_(0);

    __ Bind(&is_assignable);  // For a null object.
    // Restore instantiator and its type arguments.
    __ lw(A1, Address(SP, 0 * kWordSize));
    __ lw(A2, Address(SP, 1 * kWordSize));
    __ addiu(SP, SP, Immediate(2 * kWordSize));
    return;
  }

  // Generate inline type check, linking to runtime call if not assignable.
  SubtypeTestCache& test_cache = SubtypeTestCache::ZoneHandle();
  test_cache = GenerateInlineInstanceof(token_pos, dst_type,
                                        &is_assignable, &runtime_call);

  __ Bind(&runtime_call);
  // Load instantiator (A2) and its type arguments (A1).
  __ lw(A1, Address(SP, 0 * kWordSize));
  __ lw(A2, Address(SP, 1 * kWordSize));

  __ addiu(SP, SP, Immediate(-7 * kWordSize));
  __ LoadObject(TMP, Object::null_object());
  __ sw(TMP, Address(SP, 6 * kWordSize));  // Make room for the result.
  __ sw(A0, Address(SP, 5 * kWordSize));  // Push the source object.
  __ LoadObject(TMP, dst_type);
  __ sw(TMP, Address(SP, 4 * kWordSize));  // Push the type of the destination.
  __ sw(A2, Address(SP, 3 * kWordSize));  // Push instantiator.
  __ sw(A1, Address(SP, 2 * kWordSize));  // Push type arguments.
  __ LoadObject(TMP, dst_name);
  __ sw(TMP, Address(SP, 1 * kWordSize));  // Push the name of the destination.
  __ LoadObject(T0, test_cache);
  __ sw(T0, Address(SP, 0 * kWordSize));

  GenerateRuntimeCall(token_pos, deopt_id, kTypeCheckRuntimeEntry, 6, locs);
  // Pop the parameters supplied to the runtime entry. The result of the
  // type check runtime call is the checked value.
  __ lw(A0, Address(SP, 6 * kWordSize));
  __ addiu(SP, SP, Immediate(7 * kWordSize));

  __ Bind(&is_assignable);
  // Restore instantiator and its type arguments.
  __ lw(A1, Address(SP, 0 * kWordSize));
  __ lw(A2, Address(SP, 1 * kWordSize));
  __ addiu(SP, SP, Immediate(2 * kWordSize));
}


void FlowGraphCompiler::EmitInstructionEpilogue(Instruction* instr) {
  if (is_optimizing()) return;
  Definition* defn = instr->AsDefinition();
  if ((defn != NULL) && defn->HasTemp()) {
    __ Push(defn->locs()->out(0).reg());
  }
}


// Input parameters:
//   S4: arguments descriptor array.
void FlowGraphCompiler::CopyParameters() {
  __ TraceSimMsg("CopyParameters");
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

  __ lw(T2, FieldAddress(S4, ArgumentsDescriptor::positional_count_offset()));
  // Check that min_num_pos_args <= num_pos_args.
  Label wrong_num_arguments;
  __ BranchSignedLess(T2, Immediate(Smi::RawValue(min_num_pos_args)),
                      &wrong_num_arguments);

  // Check that num_pos_args <= max_num_pos_args.
  __ BranchSignedGreater(T2, Immediate(Smi::RawValue(max_num_pos_args)),
                         &wrong_num_arguments);

  // Copy positional arguments.
  // Argument i passed at fp[kParamEndSlotFromFp + num_args - i] is copied
  // to fp[kFirstLocalSlotFromFp - i].

  __ lw(T1, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
  // Since T1 and T2 are Smi, use sll 1 instead of sll 2.
  // Let T1 point to the last passed positional argument, i.e. to
  // fp[kParamEndSlotFromFp + num_args - (num_pos_args - 1)].
  __ subu(T1, T1, T2);
  __ sll(T1, T1, 1);
  __ addu(T1, FP, T1);
  __ AddImmediate(T1, (kParamEndSlotFromFp + 1) * kWordSize);

  // Let T0 point to the last copied positional argument, i.e. to
  // fp[kFirstLocalSlotFromFp - (num_pos_args - 1)].
  __ AddImmediate(T0, FP, (kFirstLocalSlotFromFp + 1) * kWordSize);
  __ sll(T2, T2, 1);  // T2 is a Smi.

  __ Comment("Argument Copy Loop");
  Label loop, loop_exit;
  __ blez(T2, &loop_exit);
  __ delay_slot()->subu(T0, T0, T2);
  __ Bind(&loop);
  __ addu(T4, T1, T2);
  __ lw(T3, Address(T4, -kWordSize));
  __ addiu(T2, T2, Immediate(-kWordSize));
  __ addu(T5, T0, T2);
  __ bgtz(T2, &loop);
  __ delay_slot()->sw(T3, Address(T5));
  __ Bind(&loop_exit);

  // Copy or initialize optional named arguments.
  Label all_arguments_processed;
#ifdef DEBUG
    const bool check_correct_named_args = true;
#else
    const bool check_correct_named_args = function.IsClosureFunction();
#endif
  if (num_opt_named_params > 0) {
    __ Comment("There are named parameters");
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
    __ lw(T1, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
    __ lw(T2, FieldAddress(S4, ArgumentsDescriptor::positional_count_offset()));
    __ SmiUntag(T2);
    // Let T1 point to the first passed argument, i.e. to
    // fp[kParamEndSlotFromFp + num_args - 0]; num_args (T1) is Smi.
    __ sll(T3, T1, 1);
    __ addu(T1, FP, T3);
    __ AddImmediate(T1, kParamEndSlotFromFp * kWordSize);
    // Let T0 point to the entry of the first named argument.
    __ AddImmediate(T0, S4,
        ArgumentsDescriptor::first_named_entry_offset() - kHeapObjectTag);
    for (int i = 0; i < num_opt_named_params; i++) {
      Label load_default_value, assign_optional_parameter;
      const int param_pos = opt_param_position[i];
      // Check if this named parameter was passed in.
      // Load T3 with the name of the argument.
      __ lw(T3, Address(T0, ArgumentsDescriptor::name_offset()));
      ASSERT(opt_param[i]->name().IsSymbol());
      __ BranchNotEqual(T3, opt_param[i]->name(), &load_default_value);

      // Load T3 with passed-in argument at provided arg_pos, i.e. at
      // fp[kParamEndSlotFromFp + num_args - arg_pos].
      __ lw(T3, Address(T0, ArgumentsDescriptor::position_offset()));
      // T3 is arg_pos as Smi.
      // Point to next named entry.
      __ AddImmediate(T0, ArgumentsDescriptor::named_entry_size());
      __ subu(T3, ZR, T3);
      __ sll(T3, T3, 1);
      __ addu(T3, T1, T3);
      __ b(&assign_optional_parameter);
      __ delay_slot()->lw(T3, Address(T3));

      __ Bind(&load_default_value);
      // Load T3 with default argument.
      const Object& value = Object::ZoneHandle(
          parsed_function().default_parameter_values().At(
              param_pos - num_fixed_params));
      __ LoadObject(T3, value);
      __ Bind(&assign_optional_parameter);
      // Assign T3 to fp[kFirstLocalSlotFromFp - param_pos].
      // We do not use the final allocation index of the variable here, i.e.
      // scope->VariableAt(i)->index(), because captured variables still need
      // to be copied to the context that is not yet allocated.
      const intptr_t computed_param_pos = kFirstLocalSlotFromFp - param_pos;
      __ sw(T3, Address(FP, computed_param_pos * kWordSize));
    }
    delete[] opt_param;
    delete[] opt_param_position;
    if (check_correct_named_args) {
      // Check that T0 now points to the null terminator in the arguments
      // descriptor.
      __ lw(T3, Address(T0));
      __ BranchEqual(T3, Object::null_object(), &all_arguments_processed);
    }
  } else {
    ASSERT(num_opt_pos_params > 0);
    __ Comment("There are optional positional parameters");
    __ lw(T2,
          FieldAddress(S4, ArgumentsDescriptor::positional_count_offset()));
    __ SmiUntag(T2);
    for (int i = 0; i < num_opt_pos_params; i++) {
      Label next_parameter;
      // Handle this optional positional parameter only if k or fewer positional
      // arguments have been passed, where k is param_pos, the position of this
      // optional parameter in the formal parameter list.
      const int param_pos = num_fixed_params + i;
      __ BranchSignedGreater(T2, Immediate(param_pos), &next_parameter);
      // Load T3 with default argument.
      const Object& value = Object::ZoneHandle(
          parsed_function().default_parameter_values().At(i));
      __ LoadObject(T3, value);
      // Assign T3 to fp[kFirstLocalSlotFromFp - param_pos].
      // We do not use the final allocation index of the variable here, i.e.
      // scope->VariableAt(i)->index(), because captured variables still need
      // to be copied to the context that is not yet allocated.
      const intptr_t computed_param_pos = kFirstLocalSlotFromFp - param_pos;
      __ sw(T3, Address(FP, computed_param_pos * kWordSize));
      __ Bind(&next_parameter);
    }
    if (check_correct_named_args) {
      __ lw(T1, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
      __ SmiUntag(T1);
      // Check that T2 equals T1, i.e. no named arguments passed.
      __ beq(T2, T1, &all_arguments_processed);
    }
  }

  __ Bind(&wrong_num_arguments);
  if (function.IsClosureFunction()) {
    __ LeaveDartFrame();  // The arguments are still on the stack.
    __ Branch(&isolate()->stub_code()->CallClosureNoSuchMethodLabel());
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

  // S4 : arguments descriptor array.
  __ lw(T2, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
  __ sll(T2, T2, 1);  // T2 is a Smi.

  __ Comment("Null arguments loop");
  Label null_args_loop, null_args_loop_exit;
  __ blez(T2, &null_args_loop_exit);
  __ delay_slot()->addiu(T1, FP,
                         Immediate((kParamEndSlotFromFp + 1) * kWordSize));
  __ Bind(&null_args_loop);
  __ addiu(T2, T2, Immediate(-kWordSize));
  __ addu(T3, T1, T2);
  __ LoadImmediate(T5, reinterpret_cast<int32_t>(Object::null()));
  __ bgtz(T2, &null_args_loop);
  __ delay_slot()->sw(T5, Address(T3));
  __ Bind(&null_args_loop_exit);
}


void FlowGraphCompiler::GenerateInlinedGetter(intptr_t offset) {
  // RA: return address.
  // SP: receiver.
  // Sequence node has one return node, its input is load field node.
  __ Comment("Inlined Getter");
  __ lw(V0, Address(SP, 0 * kWordSize));
  __ lw(V0, Address(V0, offset - kHeapObjectTag));
  __ Ret();
}


void FlowGraphCompiler::GenerateInlinedSetter(intptr_t offset) {
  // RA: return address.
  // SP+1: receiver.
  // SP+0: value.
  // Sequence node has one store node and one return NULL node.
  __ Comment("Inlined Setter");
  __ lw(T0, Address(SP, 1 * kWordSize));  // Receiver.
  __ lw(T1, Address(SP, 0 * kWordSize));  // Value.
  __ StoreIntoObjectOffset(T0, offset, T1);
  __ LoadImmediate(V0, reinterpret_cast<int32_t>(Object::null()));
  __ Ret();
}


void FlowGraphCompiler::EmitFrameEntry() {
  const Function& function = parsed_function().function();
  if (CanOptimizeFunction() &&
      function.IsOptimizable() &&
      (!is_optimizing() || may_reoptimize())) {
    const Register function_reg = T0;
    StubCode* stub_code = isolate()->stub_code();

    __ GetNextPC(T2, TMP);

    // Calculate offset of pool pointer from the PC.
    const intptr_t object_pool_pc_dist =
       Instructions::HeaderSize() - Instructions::object_pool_offset() +
       assembler()->CodeSize() - 1 * Instr::kInstrSize;

    // Preserve PP of caller.
    __ mov(T1, PP);
    // Temporarily setup pool pointer for this dart function.
    __ lw(PP, Address(T2, -object_pool_pc_dist));
    // Load function object from object pool.
    __ LoadObject(function_reg, function);  // Uses PP.
    // Restore PP of caller.
    __ mov(PP, T1);

    // Patch point is after the eventually inlined function object.
    entry_patch_pc_offset_ = assembler()->CodeSize();

    __ lw(T1, FieldAddress(function_reg, Function::usage_counter_offset()));
    // Reoptimization of an optimized function is triggered by counting in
    // IC stubs, but not at the entry of the function.
    if (!is_optimizing()) {
      __ addiu(T1, T1, Immediate(1));
      __ sw(T1, FieldAddress(function_reg, Function::usage_counter_offset()));
    }

    // Skip Branch if T1 is less than the threshold.
    Label dont_branch;
    __ BranchSignedLess(
        T1, Immediate(GetOptimizationThreshold()), &dont_branch);

    ASSERT(function_reg == T0);
    __ Branch(&stub_code->OptimizeFunctionLabel());

    __ Bind(&dont_branch);

  } else if (!flow_graph().IsCompiledForOsr()) {
    entry_patch_pc_offset_ = assembler()->CodeSize();
  }
  __ Comment("Enter frame");
  if (flow_graph().IsCompiledForOsr()) {
    intptr_t extra_slots = StackSize()
        - flow_graph().num_stack_locals()
        - flow_graph().num_copied_params();
    ASSERT(extra_slots >= 0);
    __ EnterOsrFrame(extra_slots * kWordSize);
  } else {
    ASSERT(StackSize() >= 0);
    __ EnterDartFrame(StackSize() * kWordSize);
  }
}


// Input parameters:
//   RA: return address.
//   SP: address of last argument.
//   FP: caller's frame pointer.
//   PP: caller's pool pointer.
//   S5: ic-data.
//   S4: arguments descriptor array.
void FlowGraphCompiler::CompileGraph() {
  InitCompiler();

  TryIntrinsify();

  EmitFrameEntry();

  const Function& function = parsed_function().function();

  const int num_fixed_params = function.num_fixed_parameters();
  const int num_copied_params = parsed_function().num_copied_params();
  const int num_locals = parsed_function().num_stack_locals();
  StubCode* stub_code = isolate()->stub_code();

  // We check the number of passed arguments when we have to copy them due to
  // the presence of optional parameters.
  // No such checking code is generated if only fixed parameters are declared,
  // unless we are in debug mode or unless we are compiling a closure.
  if (num_copied_params == 0) {
#ifdef DEBUG
    ASSERT(!parsed_function().function().HasOptionalParameters());
    const bool check_arguments = !flow_graph().IsCompiledForOsr();
#else
    const bool check_arguments =
        function.IsClosureFunction() && !flow_graph().IsCompiledForOsr();
#endif
    if (check_arguments) {
      __ TraceSimMsg("Check argument count");
      __ Comment("Check argument count");
      // Check that exactly num_fixed arguments are passed in.
      Label correct_num_arguments, wrong_num_arguments;
      __ lw(T0, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
      __ BranchNotEqual(T0, Immediate(Smi::RawValue(num_fixed_params)),
                        &wrong_num_arguments);

      __ lw(T1, FieldAddress(S4,
                             ArgumentsDescriptor::positional_count_offset()));
      __ beq(T0, T1, &correct_num_arguments);
      __ Bind(&wrong_num_arguments);
      if (function.IsClosureFunction()) {
        __ LeaveDartFrame();  // The arguments are still on the stack.
        __ Branch(&isolate()->stub_code()->CallClosureNoSuchMethodLabel());
        // The noSuchMethod call may return to the caller, but not here.
      } else {
        __ Stop("Wrong number of arguments");
      }
      __ Bind(&correct_num_arguments);
    }
  } else if (!flow_graph().IsCompiledForOsr()) {
    CopyParameters();
  }

  if (function.IsClosureFunction() && !flow_graph().IsCompiledForOsr()) {
    // Load context from the closure object (first argument).
    LocalScope* scope = parsed_function().node_sequence()->scope();
    LocalVariable* closure_parameter = scope->VariableAt(0);
    __ lw(CTX, Address(FP, closure_parameter->index() * kWordSize));
    __ lw(CTX, FieldAddress(CTX, Closure::context_offset()));
  }

  // In unoptimized code, initialize (non-argument) stack allocated slots to
  // null.
  if (!is_optimizing()) {
    ASSERT(num_locals > 0);  // There is always at least context_var.
    __ TraceSimMsg("Initialize spill slots");
    __ Comment("Initialize spill slots");
    const intptr_t slot_base = parsed_function().first_stack_local_index();
    const intptr_t context_index =
        parsed_function().current_context_var()->index();
    if (num_locals > 1) {
      __ LoadImmediate(V0, reinterpret_cast<int32_t>(Object::null()));
    }
    for (intptr_t i = 0; i < num_locals; ++i) {
      // Subtract index i (locals lie at lower addresses than FP).
      if (((slot_base - i) == context_index)) {
        if (function.IsClosureFunction()) {
          __ sw(CTX, Address(FP, (slot_base - i) * kWordSize));
        } else {
          const Context& empty_context = Context::ZoneHandle(
              isolate(), isolate()->object_store()->empty_context());
          __ LoadObject(V1, empty_context);
          __ sw(V1, Address(FP, (slot_base - i) * kWordSize));
        }
      } else {
        ASSERT(num_locals > 1);
        __ sw(V0, Address(FP, (slot_base - i) * kWordSize));
      }
    }
  }

  VisitBlocks();

  __ break_(0);
  GenerateDeferredCode();
  // Emit function patching code. This will be swapped with the first 5 bytes
  // at entry point.
  patch_code_pc_offset_ = assembler()->CodeSize();
  __ BranchPatchable(&stub_code->FixCallersTargetLabel());

  if (is_optimizing()) {
    lazy_deopt_pc_offset_ = assembler()->CodeSize();
    __ Branch(&stub_code->DeoptimizeLazyLabel());
  }
}


void FlowGraphCompiler::GenerateCall(intptr_t token_pos,
                                     const ExternalLabel* label,
                                     RawPcDescriptors::Kind kind,
                                     LocationSummary* locs) {
  __ BranchLinkPatchable(label);
  AddCurrentDescriptor(kind, Isolate::kNoDeoptId, token_pos);
  RecordSafepoint(locs);
}


void FlowGraphCompiler::GenerateDartCall(intptr_t deopt_id,
                                         intptr_t token_pos,
                                         const ExternalLabel* label,
                                         RawPcDescriptors::Kind kind,
                                         LocationSummary* locs) {
  __ BranchLinkPatchable(label);
  AddCurrentDescriptor(kind, deopt_id, token_pos);
  RecordSafepoint(locs);
  // Marks either the continuation point in unoptimized code or the
  // deoptimization point in optimized code, after call.
  const intptr_t deopt_id_after = Isolate::ToDeoptAfter(deopt_id);
  if (is_optimizing()) {
    AddDeoptIndexAtCall(deopt_id_after, token_pos);
  } else {
    // Add deoptimization continuation point after the call and before the
    // arguments are removed.
    AddCurrentDescriptor(RawPcDescriptors::kDeopt,
                         deopt_id_after,
                         token_pos);
  }
}


void FlowGraphCompiler::GenerateRuntimeCall(intptr_t token_pos,
                                            intptr_t deopt_id,
                                            const RuntimeEntry& entry,
                                            intptr_t argument_count,
                                            LocationSummary* locs) {
  __ CallRuntime(entry, argument_count);
  AddCurrentDescriptor(RawPcDescriptors::kOther, deopt_id, token_pos);
  RecordSafepoint(locs);
  if (deopt_id != Isolate::kNoDeoptId) {
    // Marks either the continuation point in unoptimized code or the
    // deoptimization point in optimized code, after call.
    const intptr_t deopt_id_after = Isolate::ToDeoptAfter(deopt_id);
    if (is_optimizing()) {
      AddDeoptIndexAtCall(deopt_id_after, token_pos);
    } else {
      // Add deoptimization continuation point after the call and before the
      // arguments are removed.
      AddCurrentDescriptor(RawPcDescriptors::kDeopt,
                           deopt_id_after,
                           token_pos);
    }
  }
}


void FlowGraphCompiler::EmitEdgeCounter() {
  // We do not check for overflow when incrementing the edge counter.  The
  // function should normally be optimized long before the counter can
  // overflow; and though we do not reset the counters when we optimize or
  // deoptimize, there is a bound on the number of
  // optimization/deoptimization cycles we will attempt.
  const Array& counter = Array::ZoneHandle(Array::New(1, Heap::kOld));
  counter.SetAt(0, Smi::Handle(Smi::New(0)));
  __ Comment("Edge counter");
  __ LoadObject(T0, counter);
  __ lw(T1, FieldAddress(T0, Array::element_offset(0)));
  __ AddImmediate(T1, T1, Smi::RawValue(1));
  __ sw(T1, FieldAddress(T0, Array::element_offset(0)));
}


void FlowGraphCompiler::EmitOptimizedInstanceCall(
    ExternalLabel* target_label,
    const ICData& ic_data,
    intptr_t argument_count,
    intptr_t deopt_id,
    intptr_t token_pos,
    LocationSummary* locs) {
  ASSERT(Array::Handle(ic_data.arguments_descriptor()).Length() > 0);
  // Each ICData propagated from unoptimized to optimized code contains the
  // function that corresponds to the Dart function of that IC call. Due
  // to inlining in optimized code, that function may not correspond to the
  // top-level function (parsed_function().function()) which could be
  // reoptimized and which counter needs to be incremented.
  // Pass the function explicitly, it is used in IC stub.
  __ TraceSimMsg("OptimizedInstanceCall");
  __ LoadObject(T0, parsed_function().function());
  __ LoadObject(S5, ic_data);
  GenerateDartCall(deopt_id,
                   token_pos,
                   target_label,
                   RawPcDescriptors::kIcCall,
                   locs);
  __ Drop(argument_count);
}


void FlowGraphCompiler::EmitInstanceCall(ExternalLabel* target_label,
                                         const ICData& ic_data,
                                         intptr_t argument_count,
                                         intptr_t deopt_id,
                                         intptr_t token_pos,
                                         LocationSummary* locs) {
  ASSERT(Array::Handle(ic_data.arguments_descriptor()).Length() > 0);
  __ TraceSimMsg("InstanceCall");
  __ LoadObject(S5, ic_data);
  GenerateDartCall(deopt_id,
                   token_pos,
                   target_label,
                   RawPcDescriptors::kIcCall,
                   locs);
  __ TraceSimMsg("InstanceCall return");
  __ Drop(argument_count);
#if defined(DEBUG)
  __ LoadImmediate(S4, kInvalidObjectPointer);
#endif
}


void FlowGraphCompiler::EmitMegamorphicInstanceCall(
    const ICData& ic_data,
    intptr_t argument_count,
    intptr_t deopt_id,
    intptr_t token_pos,
    LocationSummary* locs) {
  MegamorphicCacheTable* table = Isolate::Current()->megamorphic_cache_table();
  const String& name = String::Handle(ic_data.target_name());
  const Array& arguments_descriptor =
      Array::ZoneHandle(ic_data.arguments_descriptor());
  ASSERT(!arguments_descriptor.IsNull() && (arguments_descriptor.Length() > 0));
  const MegamorphicCache& cache =
      MegamorphicCache::ZoneHandle(table->Lookup(name, arguments_descriptor));
  __ TraceSimMsg("MegamorphicInstanceCall");
  __ lw(T0, Address(SP, (argument_count - 1) * kWordSize));
  __ LoadTaggedClassIdMayBeSmi(T0, T0);

  // T0: class ID of the receiver (smi).
  __ LoadObject(T1, cache);
  __ lw(T2, FieldAddress(T1, MegamorphicCache::buckets_offset()));
  __ lw(T1, FieldAddress(T1, MegamorphicCache::mask_offset()));
  // T2: cache buckets array.
  // T1: mask.
  __ mov(T3, T0);

  Label loop, update, call_target_function;
  __ b(&loop);

  __ Bind(&update);
  __ addiu(T3, T3, Immediate(Smi::RawValue(1)));
  __ Bind(&loop);
  __ and_(T3, T3, T1);
  const intptr_t base = Array::data_offset();
  // T3 is smi tagged, but table entries are two words, so LSL 2.
  __ sll(TMP, T3, 2);
  __ addu(TMP, T2, TMP);
  __ lw(T4, FieldAddress(TMP, base));

  ASSERT(kIllegalCid == 0);
  __ beq(T4, ZR, &call_target_function);
  __ bne(T4, T0, &update);

  __ Bind(&call_target_function);
  // Call the target found in the cache.  For a class id match, this is a
  // proper target for the given name and arguments descriptor.  If the
  // illegal class id was found, the target is a cache miss handler that can
  // be invoked as a normal Dart function.
  __ sll(T1, T3, 2);
  __ addu(T1, T2, T1);
  __ lw(T0, FieldAddress(T1, base + kWordSize));

  __ lw(T1, FieldAddress(T0, Function::instructions_offset()));
  __ LoadObject(S5, ic_data);
  __ LoadObject(S4, arguments_descriptor);
  __ AddImmediate(T1, Instructions::HeaderSize() - kHeapObjectTag);
  __ jalr(T1);
  AddCurrentDescriptor(RawPcDescriptors::kOther,
      Isolate::kNoDeoptId, token_pos);
  RecordSafepoint(locs);
  AddDeoptIndexAtCall(Isolate::ToDeoptAfter(deopt_id), token_pos);
  __ Drop(argument_count);
}


void FlowGraphCompiler::EmitUnoptimizedStaticCall(
    intptr_t argument_count,
    intptr_t deopt_id,
    intptr_t token_pos,
    LocationSummary* locs,
    const ICData& ic_data) {
  StubCode* stub_code = isolate()->stub_code();
  const uword label_address =
      stub_code->UnoptimizedStaticCallEntryPoint(ic_data.NumArgsTested());
  ExternalLabel target_label(label_address);
  __ LoadObject(S5, ic_data);
  GenerateDartCall(deopt_id,
                   token_pos,
                   &target_label,
                   RawPcDescriptors::kUnoptStaticCall,
                   locs);
#if defined(DEBUG)
  __ LoadImmediate(S4, kInvalidObjectPointer);
  __ LoadImmediate(S5, kInvalidObjectPointer);
#endif
  __ Drop(argument_count);
}


void FlowGraphCompiler::EmitOptimizedStaticCall(
    const Function& function,
    const Array& arguments_descriptor,
    intptr_t argument_count,
    intptr_t deopt_id,
    intptr_t token_pos,
    LocationSummary* locs) {
  StubCode* stub_code = isolate()->stub_code();
  __ TraceSimMsg("StaticCall");
  __ LoadObject(S4, arguments_descriptor);
  // Do not use the code from the function, but let the code be patched so that
  // we can record the outgoing edges to other code.
  GenerateDartCall(deopt_id,
                   token_pos,
                   &stub_code->CallStaticFunctionLabel(),
                   RawPcDescriptors::kOptStaticCall,
                   locs);
  AddStaticCallTarget(function);
  __ Drop(argument_count);
}


Condition FlowGraphCompiler::EmitEqualityRegConstCompare(
    Register reg,
    const Object& obj,
    bool needs_number_check,
    intptr_t token_pos) {
  __ TraceSimMsg("EqualityRegConstCompare");
  if (needs_number_check) {
    StubCode* stub_code = isolate()->stub_code();
    ASSERT(!obj.IsMint() && !obj.IsDouble() && !obj.IsBigint());
    __ addiu(SP, SP, Immediate(-2 * kWordSize));
    __ sw(reg, Address(SP, 1 * kWordSize));
    __ LoadObject(TMP, obj);
    __ sw(TMP, Address(SP, 0 * kWordSize));
    if (is_optimizing()) {
      __ BranchLinkPatchable(
          &stub_code->OptimizedIdenticalWithNumberCheckLabel());
    } else {
      __ BranchLinkPatchable(
          &stub_code->UnoptimizedIdenticalWithNumberCheckLabel());
    }
    if (token_pos != Scanner::kNoSourcePos) {
      AddCurrentDescriptor(RawPcDescriptors::kRuntimeCall,
                           Isolate::kNoDeoptId,
                           token_pos);
    }
    __ TraceSimMsg("EqualityRegConstCompare return");
    // Stub returns result in CMPRES1 (if it is 0, then reg and obj are
    // equal) and always sets CMPRES2 to 0.
    __ lw(reg, Address(SP, 1 * kWordSize));  // Restore 'reg'.
    __ addiu(SP, SP, Immediate(2 * kWordSize));  // Discard constant.
  } else {
    __ CompareObject(CMPRES1, CMPRES2, reg, obj);
  }
  return EQ;
}


Condition FlowGraphCompiler::EmitEqualityRegRegCompare(Register left,
                                                       Register right,
                                                       bool needs_number_check,
                                                       intptr_t token_pos) {
  __ TraceSimMsg("EqualityRegRegCompare");
  __ Comment("EqualityRegRegCompare");
  if (needs_number_check) {
    StubCode* stub_code = isolate()->stub_code();
    __ addiu(SP, SP, Immediate(-2 * kWordSize));
    __ sw(left, Address(SP, 1 * kWordSize));
    __ sw(right, Address(SP, 0 * kWordSize));
    if (is_optimizing()) {
      __ BranchLinkPatchable(
          &stub_code->OptimizedIdenticalWithNumberCheckLabel());
    } else {
      __ BranchLinkPatchable(
          &stub_code->UnoptimizedIdenticalWithNumberCheckLabel());
    }
    if (token_pos != Scanner::kNoSourcePos) {
      AddCurrentDescriptor(RawPcDescriptors::kRuntimeCall,
                           Isolate::kNoDeoptId,
                           token_pos);
    }
#if defined(DEBUG)
    if (!is_optimizing()) {
      // Do this *after* adding the pc descriptor!
      __ LoadImmediate(S4, kInvalidObjectPointer);
      __ LoadImmediate(S5, kInvalidObjectPointer);
    }
#endif
    __ TraceSimMsg("EqualityRegRegCompare return");
    // Stub returns result in CMPRES1 (if it is 0, then left and right are
    // equal) and always sets CMPRES2 to 0.
    __ lw(right, Address(SP, 0 * kWordSize));
    __ lw(left, Address(SP, 1 * kWordSize));
    __ addiu(SP, SP, Immediate(2 * kWordSize));
  } else {
    __ slt(CMPRES1, left, right);
    __ slt(CMPRES2, right, left);
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

  __ TraceSimMsg("SaveLiveRegisters");
  // TODO(vegorov): consider saving only caller save (volatile) registers.
  const intptr_t fpu_regs_count = locs->live_registers()->FpuRegisterCount();
  if (fpu_regs_count > 0) {
    __ AddImmediate(SP, -(fpu_regs_count * kFpuRegisterSize));
    // Store fpu registers with the lowest register number at the lowest
    // address.
    intptr_t offset = 0;
    for (intptr_t reg_idx = 0; reg_idx < kNumberOfFpuRegisters; ++reg_idx) {
      DRegister fpu_reg = static_cast<DRegister>(reg_idx);
      if (locs->live_registers()->ContainsFpuRegister(fpu_reg)) {
        __ StoreDToOffset(fpu_reg, SP, offset);
        offset += kFpuRegisterSize;
      }
    }
    ASSERT(offset == (fpu_regs_count * kFpuRegisterSize));
  }

  // Store general purpose registers with the highest register number at the
  // lowest address. The order in which the registers are pushed must match the
  // order in which the registers are encoded in the safe point's stack map.
  const intptr_t cpu_registers = locs->live_registers()->cpu_registers();
  ASSERT((cpu_registers & ~kAllCpuRegistersList) == 0);
  const int register_count = Utils::CountOneBits(cpu_registers);
  if (register_count > 0) {
    __ addiu(SP, SP, Immediate(-register_count * kWordSize));
    intptr_t offset = register_count * kWordSize;
    for (int i = 0; i < kNumberOfCpuRegisters; i++) {
      Register r = static_cast<Register>(i);
      if (locs->live_registers()->ContainsRegister(r)) {
        offset -= kWordSize;
        __ sw(r, Address(SP, offset));
      }
    }
    ASSERT(offset == 0);
  }
}


void FlowGraphCompiler::RestoreLiveRegisters(LocationSummary* locs) {
#if defined(DEBUG)
  ClobberDeadTempRegisters(locs);
#endif
  // General purpose registers have the highest register number at the
  // lowest address.
  __ TraceSimMsg("RestoreLiveRegisters");
  const intptr_t cpu_registers = locs->live_registers()->cpu_registers();
  ASSERT((cpu_registers & ~kAllCpuRegistersList) == 0);
  const int register_count = Utils::CountOneBits(cpu_registers);
  if (register_count > 0) {
    intptr_t offset = register_count * kWordSize;
    for (int i = 0; i < kNumberOfCpuRegisters; i++) {
      Register r = static_cast<Register>(i);
      if (locs->live_registers()->ContainsRegister(r)) {
        offset -= kWordSize;
        __ lw(r, Address(SP, offset));
      }
    }
    ASSERT(offset == 0);
    __ addiu(SP, SP, Immediate(register_count * kWordSize));
  }

  const intptr_t fpu_regs_count = locs->live_registers()->FpuRegisterCount();
  if (fpu_regs_count > 0) {
    // Fpu registers have the lowest register number at the lowest address.
    intptr_t offset = 0;
    for (intptr_t reg_idx = 0; reg_idx < kNumberOfFpuRegisters; ++reg_idx) {
      DRegister fpu_reg = static_cast<DRegister>(reg_idx);
      if (locs->live_registers()->ContainsFpuRegister(fpu_reg)) {
        __ LoadDFromOffset(fpu_reg, SP, offset);
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
      __ LoadImmediate(tmp.reg(), 0xf7);
    }
  }
}
#endif


void FlowGraphCompiler::EmitTestAndCall(const ICData& ic_data,
                                        Register class_id_reg,
                                        intptr_t argument_count,
                                        const Array& argument_names,
                                        Label* deopt,
                                        intptr_t deopt_id,
                                        intptr_t token_index,
                                        LocationSummary* locs) {
  ASSERT(is_optimizing());
  ASSERT(!ic_data.IsNull() && (ic_data.NumberOfUsedChecks() > 0));
  Label match_found;
  const intptr_t len = ic_data.NumberOfChecks();
  GrowableArray<CidTarget> sorted(len);
  SortICDataByCount(ic_data, &sorted);
  ASSERT(class_id_reg != S4);
  ASSERT(len > 0);  // Why bother otherwise.
  const Array& arguments_descriptor =
      Array::ZoneHandle(ArgumentsDescriptor::New(argument_count,
                                                 argument_names));
  StubCode* stub_code = isolate()->stub_code();

  __ TraceSimMsg("EmitTestAndCall");
  __ Comment("EmitTestAndCall");
  __ LoadObject(S4, arguments_descriptor);
  for (intptr_t i = 0; i < len; i++) {
    const bool is_last_check = (i == (len - 1));
    Label next_test;
    if (is_last_check) {
      __ BranchNotEqual(class_id_reg, Immediate(sorted[i].cid), deopt);
    } else {
      __ BranchNotEqual(class_id_reg, Immediate(sorted[i].cid), &next_test);
    }
    // Do not use the code from the function, but let the code be patched so
    // that we can record the outgoing edges to other code.
    GenerateDartCall(deopt_id,
                     token_index,
                     &stub_code->CallStaticFunctionLabel(),
                     RawPcDescriptors::kOptStaticCall,
                     locs);
    const Function& function = *sorted[i].target;
    AddStaticCallTarget(function);
    __ Drop(argument_count);
    if (!is_last_check) {
      __ b(&match_found);
    }
    __ Bind(&next_test);
  }
  __ Bind(&match_found);
}


#undef __
#define __ compiler_->assembler()->


void ParallelMoveResolver::EmitMove(int index) {
  MoveOperands* move = moves_[index];
  const Location source = move->src();
  const Location destination = move->dest();
  __ TraceSimMsg("ParallelMoveResolver::EmitMove");

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
    } else {
      ASSERT(destination.IsStackSlot());
      const intptr_t source_offset = source.ToStackSlotOffset();
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      ScratchRegisterScope tmp(this, kNoRegister);
      __ LoadFromOffset(tmp.reg(), source.base_reg(), source_offset);
      __ StoreToOffset(tmp.reg(), destination.base_reg(), dest_offset);
    }
  } else if (source.IsFpuRegister()) {
    if (destination.IsFpuRegister()) {
      DRegister dst = destination.fpu_reg();
      DRegister src = source.fpu_reg();
      __ movd(dst, src);
    } else {
      ASSERT(destination.IsDoubleStackSlot());
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      DRegister src = source.fpu_reg();
      __ StoreDToOffset(src, destination.base_reg(), dest_offset);
    }
  } else if (source.IsDoubleStackSlot()) {
    if (destination.IsFpuRegister()) {
      const intptr_t source_offset = source.ToStackSlotOffset();
      DRegister dst = destination.fpu_reg();
      __ LoadDFromOffset(dst, source.base_reg(), source_offset);
    } else {
      ASSERT(destination.IsDoubleStackSlot());
      const intptr_t source_offset = source.ToStackSlotOffset();
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      __ LoadDFromOffset(DTMP, source.base_reg(), source_offset);
      __ StoreDToOffset(DTMP, destination.base_reg(), dest_offset);
    }
  } else {
    ASSERT(source.IsConstant());
    const Object& constant = source.constant();
    if (destination.IsRegister()) {
      if (constant.IsSmi() &&
          (source.constant_instruction()->representation() == kUnboxedInt32)) {
        __ LoadImmediate(destination.reg(), Smi::Cast(constant).Value());
      } else {
        __ LoadObject(destination.reg(), constant);
      }
    } else if (destination.IsFpuRegister()) {
      __ LoadObject(TMP, constant);
      __ LoadDFromOffset(destination.fpu_reg(), TMP,
          Double::value_offset() - kHeapObjectTag);
    } else if (destination.IsDoubleStackSlot()) {
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      __ LoadObject(TMP, constant);
      __ LoadDFromOffset(DTMP, TMP, Double::value_offset() - kHeapObjectTag);
      __ StoreDToOffset(DTMP, destination.base_reg(), dest_offset);
    } else {
      ASSERT(destination.IsStackSlot());
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      ScratchRegisterScope tmp(this, kNoRegister);
      if (constant.IsSmi() &&
          (source.constant_instruction()->representation() == kUnboxedInt32)) {
        __ LoadImmediate(tmp.reg(), Smi::Cast(constant).Value());
      } else {
        __ LoadObject(tmp.reg(), constant);
      }
      __ StoreToOffset(tmp.reg(), destination.base_reg(), dest_offset);
    }
  }

  move->Eliminate();
}


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
    Exchange(source.reg(),
             destination.base_reg(), destination.ToStackSlotOffset());
  } else if (source.IsStackSlot() && destination.IsRegister()) {
    Exchange(destination.reg(),
             source.base_reg(), source.ToStackSlotOffset());
  } else if (source.IsStackSlot() && destination.IsStackSlot()) {
    Exchange(source.base_reg(), source.ToStackSlotOffset(),
             destination.base_reg(), destination.ToStackSlotOffset());
  } else if (source.IsFpuRegister() && destination.IsFpuRegister()) {
    DRegister dst = destination.fpu_reg();
    DRegister src = source.fpu_reg();
    __ movd(DTMP, src);
    __ movd(src, dst);
    __ movd(dst, DTMP);
  } else if (source.IsFpuRegister() || destination.IsFpuRegister()) {
    ASSERT(destination.IsDoubleStackSlot() || source.IsDoubleStackSlot());
    DRegister reg = source.IsFpuRegister() ? source.fpu_reg()
                                           : destination.fpu_reg();
    Register base_reg = source.IsFpuRegister()
        ? destination.base_reg()
        : source.base_reg();
    const intptr_t slot_offset = source.IsFpuRegister()
        ? destination.ToStackSlotOffset()
        : source.ToStackSlotOffset();
    __ LoadDFromOffset(DTMP, base_reg, slot_offset);
    __ StoreDToOffset(reg, base_reg, slot_offset);
    __ movd(reg, DTMP);
  } else if (source.IsDoubleStackSlot() && destination.IsDoubleStackSlot()) {
    const intptr_t source_offset = source.ToStackSlotOffset();
    const intptr_t dest_offset = destination.ToStackSlotOffset();

    ScratchFpuRegisterScope ensure_scratch(this, DTMP);
    DRegister scratch = ensure_scratch.reg();
    __ LoadDFromOffset(DTMP, source.base_reg(), source_offset);
    __ LoadDFromOffset(scratch, destination.base_reg(), dest_offset);
    __ StoreDToOffset(DTMP, destination.base_reg(), dest_offset);
    __ StoreDToOffset(scratch, source.base_reg(), source_offset);
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
  __ TraceSimMsg("ParallelMoveResolver::MoveMemoryToMemory");
  __ lw(TMP, src);
  __ sw(TMP, dst);
}


void ParallelMoveResolver::StoreObject(const Address& dst, const Object& obj) {
  __ TraceSimMsg("ParallelMoveResolver::StoreObject");
  __ LoadObject(TMP, obj);
  __ sw(TMP, dst);
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
  __ StoreToOffset(tmp1.reg(), base_reg1, stack_offset2);
  __ StoreToOffset(tmp2.reg(), base_reg2, stack_offset1);
}


void ParallelMoveResolver::SpillScratch(Register reg) {
  __ TraceSimMsg("ParallelMoveResolver::SpillScratch");
  __ Push(reg);
}


void ParallelMoveResolver::RestoreScratch(Register reg) {
  __ TraceSimMsg("ParallelMoveResolver::RestoreScratch");
  __ Pop(reg);
}


void ParallelMoveResolver::SpillFpuScratch(FpuRegister reg) {
  __ TraceSimMsg("ParallelMoveResolver::SpillFpuScratch");
  __ AddImmediate(SP, -kDoubleSize);
  __ StoreDToOffset(reg, SP, 0);
}


void ParallelMoveResolver::RestoreFpuScratch(FpuRegister reg) {
  __ TraceSimMsg("ParallelMoveResolver::RestoreFpuScratch");
  __ LoadDFromOffset(reg, SP, 0);
  __ AddImmediate(SP, kDoubleSize);
}


#undef __


}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS

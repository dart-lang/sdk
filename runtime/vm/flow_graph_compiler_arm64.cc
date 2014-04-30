// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM64.
#if defined(TARGET_ARCH_ARM64)

#include "vm/flow_graph_compiler.h"

#include "vm/ast_printer.h"
#include "vm/compiler.h"
#include "vm/cpu.h"
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

DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(int, reoptimization_counter_threshold);
DECLARE_FLAG(bool, eliminate_type_checks);

FlowGraphCompiler::~FlowGraphCompiler() {
  // BlockInfos are zone-allocated, so their destructors are not called.
  // Verify the labels explicitly here.
  for (int i = 0; i < block_info_.length(); ++i) {
    ASSERT(!block_info_[i]->jump_label()->IsLinked());
  }
}


bool FlowGraphCompiler::SupportsUnboxedMints() {
  return false;
}


bool FlowGraphCompiler::SupportsUnboxedSimd128() {
  return false;
}


bool FlowGraphCompiler::SupportsSinCos() {
  return false;
}


RawDeoptInfo* CompilerDeoptInfo::CreateDeoptInfo(FlowGraphCompiler* compiler,
                                                 DeoptInfoBuilder* builder,
                                                 const Array& deopt_table) {
  UNIMPLEMENTED();
  return NULL;
}


void CompilerDeoptInfoWithStub::GenerateCode(FlowGraphCompiler* compiler,
                                             intptr_t stub_ix) {
  UNIMPLEMENTED();
}


#define __ assembler()->


// Fall through if bool_register contains null.
void FlowGraphCompiler::GenerateBoolToJump(Register bool_register,
                                           Label* is_true,
                                           Label* is_false) {
  Label fall_through;
  __ CompareObject(bool_register, Object::null_object(), PP);
  __ b(&fall_through, EQ);
  __ CompareObject(bool_register, Bool::True(), PP);
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
      SubtypeTestCache::ZoneHandle(SubtypeTestCache::New());
  __ LoadObject(R2, type_test_cache, PP);
  if (test_kind == kTestTypeOneArg) {
    ASSERT(type_arguments_reg == kNoRegister);
    __ LoadObject(R1, Object::null_object(), PP);
    __ BranchLink(&StubCode::Subtype1TestCacheLabel(), PP);
  } else if (test_kind == kTestTypeTwoArgs) {
    ASSERT(type_arguments_reg == kNoRegister);
    __ LoadObject(R1, Object::null_object(), PP);
    __ BranchLink(&StubCode::Subtype2TestCacheLabel(), PP);
  } else if (test_kind == kTestTypeThreeArgs) {
    ASSERT(type_arguments_reg == R1);
    __ BranchLink(&StubCode::Subtype3TestCacheLabel(), PP);
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
    intptr_t token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  __ Comment("InstantiatedTypeWithArgumentsTest");
  ASSERT(type.IsInstantiated());
  const Class& type_class = Class::ZoneHandle(type.type_class());
  ASSERT((type_class.NumTypeArguments() > 0) || type_class.IsSignatureClass());
  const Register kInstanceReg = R0;
  Error& malformed_error = Error::Handle();
  const Type& int_type = Type::Handle(Type::IntType());
  const bool smi_is_ok = int_type.IsSubtypeOf(type, &malformed_error);
  // Malformed type should have been handled at graph construction time.
  ASSERT(smi_is_ok || malformed_error.IsNull());
  __ tsti(kInstanceReg, kSmiTagMask);
  if (smi_is_ok) {
    __ b(is_instance_lbl, EQ);
  } else {
    __ b(is_not_instance_lbl, EQ);
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
      const Register kClassIdReg = R2;
      // dynamic type argument, check only classes.
      __ LoadClassId(kClassIdReg, kInstanceReg);
      __ CompareImmediate(kClassIdReg, type_class.id(), PP);
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
  // R0: instance (must be preserved).
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
  for (intptr_t i = 0; i < class_ids.length(); i++) {
    __ CompareImmediate(class_id_reg, class_ids[i], PP);
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
    intptr_t token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  __ Comment("InstantiatedTypeNoArgumentsTest");
  ASSERT(type.IsInstantiated());
  const Class& type_class = Class::Handle(type.type_class());
  ASSERT(type_class.NumTypeArguments() == 0);

  const Register kInstanceReg = R0;
  __ tsti(kInstanceReg, kSmiTagMask);
  // If instance is Smi, check directly.
  const Class& smi_class = Class::Handle(Smi::Class());
  if (smi_class.IsSubtypeOf(TypeArguments::Handle(),
                            type_class,
                            TypeArguments::Handle(),
                            NULL)) {
    __ b(is_instance_lbl, EQ);
  } else {
    __ b(is_not_instance_lbl, EQ);
  }
  // Compare if the classes are equal.
  const Register kClassIdReg = R2;
  __ LoadClassId(kClassIdReg, kInstanceReg);
  __ CompareImmediate(kClassIdReg, type_class.id(), PP);
  __ b(is_instance_lbl, EQ);
  // See ClassFinalizer::ResolveSuperTypeAndInterfaces for list of restricted
  // interfaces.
  // Bool interface can be implemented only by core class Bool.
  if (type.IsBoolType()) {
    __ CompareImmediate(kClassIdReg, kBoolCid, PP);
    __ b(is_instance_lbl, EQ);
    __ b(is_not_instance_lbl);
    return false;
  }
  if (type.IsFunctionType()) {
    // Check if instance is a closure.
    __ LoadClassById(R3, kClassIdReg);
    __ LoadFieldFromOffset(R3, R3, Class::signature_function_offset());
    __ CompareObject(R3, Object::null_object(), PP);
    __ b(is_instance_lbl, NE);
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
// R0: instance to test.
// Clobbers R1-R5.
// Immediate class test already done.
// TODO(srdjan): Implement a quicker subtype check, as type test
// arrays can grow too high, but they may be useful when optimizing
// code (type-feedback).
RawSubtypeTestCache* FlowGraphCompiler::GenerateSubtype1TestCacheLookup(
    intptr_t token_pos,
    const Class& type_class,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  __ Comment("Subtype1TestCacheLookup");
  const Register kInstanceReg = R0;
  __ LoadClass(R1, kInstanceReg);
  // R1: instance class.
  // Check immediate superclass equality.
  __ LoadFieldFromOffset(R2, R1, Class::super_type_offset());
  __ LoadFieldFromOffset(R2, R2, Type::type_class_offset());
  __ CompareObject(R2, type_class, PP);
  __ b(is_instance_lbl, EQ);

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
// R0: instance (preserved).
RawSubtypeTestCache* FlowGraphCompiler::GenerateUninstantiatedTypeTest(
    intptr_t token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  __ Comment("UninstantiatedTypeTest");
  ASSERT(!type.IsInstantiated());
  // Skip check if destination is a dynamic type.
  if (type.IsTypeParameter()) {
    const TypeParameter& type_param = TypeParameter::Cast(type);
    // Load instantiator (or null) and instantiator type arguments on stack.
    __ ldr(R1, Address(SP));  // Get instantiator type arguments.
    // R1: instantiator type arguments.
    // Check if type arguments are null, i.e. equivalent to vector of dynamic.
    __ CompareObject(R1, Object::null_object(), PP);
    __ b(is_instance_lbl, EQ);
    __ LoadFieldFromOffset(
        R2, R1, TypeArguments::type_at_offset(type_param.index()));
    // R2: concrete type of type.
    // Check if type argument is dynamic.
    __ CompareObject(R2, Type::ZoneHandle(Type::DynamicType()), PP);
    __ b(is_instance_lbl, EQ);
    __ CompareObject(R2, Type::ZoneHandle(Type::ObjectType()), PP);
    __ b(is_instance_lbl, EQ);

    // For Smi check quickly against int and num interfaces.
    Label not_smi;
    __ tsti(R0, kSmiTagMask);  // Value is Smi?
    __ b(&not_smi, NE);
    __ CompareObject(R2, Type::ZoneHandle(Type::IntType()), PP);
    __ b(is_instance_lbl, EQ);
    __ CompareObject(R2, Type::ZoneHandle(Type::Number()), PP);
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
    const Register kInstanceReg = R0;
    const Register kTypeArgumentsReg = R1;
    __ tsti(kInstanceReg, kSmiTagMask);  // Is instance Smi?
    __ b(is_not_instance_lbl, EQ);
    __ ldr(kTypeArgumentsReg, Address(SP));  // Instantiator type args.
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
// - R0: instance being type checked (preserved).
// - R1: optional instantiator type arguments (preserved).
// Clobbers R2, R3.
// Returns:
// - preserved instance in R0 and optional instantiator type arguments in R1.
// Note that this inlined code must be followed by the runtime_call code, as it
// may fall through to it. Otherwise, this inline code will jump to the label
// is_instance or to the label is_not_instance.
RawSubtypeTestCache* FlowGraphCompiler::GenerateInlineInstanceof(
    intptr_t token_pos,
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


void FlowGraphCompiler::GenerateInstanceOf(intptr_t token_pos,
                                           intptr_t deopt_id,
                                           const AbstractType& type,
                                           bool negate_result,
                                           LocationSummary* locs) {
  UNIMPLEMENTED();
}


// Optimize assignable type check by adding inlined tests for:
// - NULL -> return NULL.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs:
// - R0: instance being type checked.
// - R1: instantiator type arguments or raw_null.
// - R2: instantiator or raw_null.
// Returns:
// - object in R0 for successful assignable check (or throws TypeError).
// Performance notes: positive checks must be quick, negative checks can be slow
// as they throw an exception.
void FlowGraphCompiler::GenerateAssertAssignable(intptr_t token_pos,
                                                 intptr_t deopt_id,
                                                 const AbstractType& dst_type,
                                                 const String& dst_name,
                                                 LocationSummary* locs) {
  ASSERT(token_pos >= 0);
  ASSERT(!dst_type.IsNull());
  ASSERT(dst_type.IsFinalized());
  // Assignable check is skipped in FlowGraphBuilder, not here.
  ASSERT(dst_type.IsMalformedOrMalbounded() ||
         (!dst_type.IsDynamicType() && !dst_type.IsObjectType()));
  // Preserve instantiator (R2) and its type arguments (R1).
  __ Push(R2);
  __ Push(R1);
  // A null object is always assignable and is returned as result.
  Label is_assignable, runtime_call;
  __ CompareObject(R0, Object::null_object(), PP);
  __ b(&is_assignable, EQ);

  if (!FLAG_eliminate_type_checks || dst_type.IsMalformed()) {
    // If type checks are not eliminated during the graph building then
    // a transition sentinel can be seen here.
    __ CompareObject(R0, Object::transition_sentinel(), PP);
    __ b(&is_assignable, EQ);
  }

  // Generate throw new TypeError() if the type is malformed or malbounded.
  if (dst_type.IsMalformedOrMalbounded()) {
    __ PushObject(Object::ZoneHandle(), PP);  // Make room for the result.
    __ Push(R0);  // Push the source object.
    __ PushObject(dst_name, PP);  // Push the name of the destination.
    __ PushObject(dst_type, PP);  // Push the type of the destination.
    GenerateRuntimeCall(token_pos,
                        deopt_id,
                        kBadTypeErrorRuntimeEntry,
                        3,
                        locs);
    // We should never return here.
    __ hlt(0);

    __ Bind(&is_assignable);  // For a null object.
    // Restore instantiator (R2) and its type arguments (R1).
    __ Pop(R1);
    __ Pop(R2);
    return;
  }

  // Generate inline type check, linking to runtime call if not assignable.
  SubtypeTestCache& test_cache = SubtypeTestCache::ZoneHandle();
  test_cache = GenerateInlineInstanceof(token_pos, dst_type,
                                        &is_assignable, &runtime_call);

  __ Bind(&runtime_call);
  // Load instantiator (R2) and its type arguments (R1).
  __ ldr(R1, Address(SP));
  __ ldr(R2, Address(SP, 1 * kWordSize));
  __ PushObject(Object::ZoneHandle(), PP);  // Make room for the result.
  __ Push(R0);  // Push the source object.
  __ PushObject(dst_type, PP);  // Push the type of the destination.
  // Push instantiator (R2) and its type arguments (R1).
  __ Push(R2);
  __ Push(R1);
  __ PushObject(dst_name, PP);  // Push the name of the destination.
  __ LoadObject(R0, test_cache, PP);
  __ Push(R0);
  GenerateRuntimeCall(token_pos, deopt_id, kTypeCheckRuntimeEntry, 6, locs);
  // Pop the parameters supplied to the runtime entry. The result of the
  // type check runtime call is the checked value.
  __ Drop(6);
  __ Pop(R0);

  __ Bind(&is_assignable);
  // Restore instantiator (R2) and its type arguments (R1).
  __ Pop(R1);
  __ Pop(R2);
}


void FlowGraphCompiler::EmitInstructionEpilogue(Instruction* instr) {
  if (is_optimizing()) {
    return;
  }
  Definition* defn = instr->AsDefinition();
  if ((defn != NULL) && defn->is_used()) {
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

  __ LoadFieldFromOffset(
      R8, R4, ArgumentsDescriptor::positional_count_offset());
  // Check that min_num_pos_args <= num_pos_args.
  Label wrong_num_arguments;
  __ CompareImmediate(R8, Smi::RawValue(min_num_pos_args), PP);
  __ b(&wrong_num_arguments, LT);
  // Check that num_pos_args <= max_num_pos_args.
  __ CompareImmediate(R8, Smi::RawValue(max_num_pos_args), PP);
  __ b(&wrong_num_arguments, GT);

  // Copy positional arguments.
  // Argument i passed at fp[kParamEndSlotFromFp + num_args - i] is copied
  // to fp[kFirstLocalSlotFromFp - i].

  __ LoadFieldFromOffset(R7, R4, ArgumentsDescriptor::count_offset());
  // Since R7 and R8 are Smi, use LSL 2 instead of LSL 3.
  // Let R7 point to the last passed positional argument, i.e. to
  // fp[kParamEndSlotFromFp + num_args - (num_pos_args - 1)].
  __ sub(R7, R7, Operand(R8));
  __ add(R7, FP, Operand(R7, LSL, 2));
  __ add(R7, R7, Operand((kParamEndSlotFromFp + 1) * kWordSize));

  // Let R6 point to the last copied positional argument, i.e. to
  // fp[kFirstLocalSlotFromFp - (num_pos_args - 1)].
  __ AddImmediate(R6, FP, (kFirstLocalSlotFromFp + 1) * kWordSize, PP);
  __ sub(R6, R6, Operand(R8, LSL, 2));  // R8 is a Smi.
  __ SmiUntag(R8);
  Label loop, loop_condition;
  __ b(&loop_condition);
  // We do not use the final allocation index of the variable here, i.e.
  // scope->VariableAt(i)->index(), because captured variables still need
  // to be copied to the context that is not yet allocated.
  const Address argument_addr(R7, R8, UXTX, Address::Scaled);
  const Address copy_addr(R6, R8, UXTX, Address::Scaled);
  __ Bind(&loop);
  __ ldr(TMP, argument_addr);
  __ str(TMP, copy_addr);
  __ Bind(&loop_condition);
  __ subs(R8, R8, Operand(1));
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
    __ LoadFieldFromOffset(R7, R4, ArgumentsDescriptor::count_offset());
    __ LoadFieldFromOffset(
        R8, R4, ArgumentsDescriptor::positional_count_offset());
    __ SmiUntag(R8);
    // Let R7 point to the first passed argument, i.e. to
    // fp[kParamEndSlotFromFp + num_args - 0]; num_args (R7) is Smi.
    __ add(R7, FP, Operand(R7, LSL, 2));
    __ AddImmediate(R7, R7, kParamEndSlotFromFp * kWordSize, PP);
    // Let R6 point to the entry of the first named argument.
    __ add(R6, R4, Operand(
        ArgumentsDescriptor::first_named_entry_offset() - kHeapObjectTag));
    for (int i = 0; i < num_opt_named_params; i++) {
      Label load_default_value, assign_optional_parameter;
      const int param_pos = opt_param_position[i];
      // Check if this named parameter was passed in.
      // Load R5 with the name of the argument.
      __ LoadFromOffset(R5, R6, ArgumentsDescriptor::name_offset());
      ASSERT(opt_param[i]->name().IsSymbol());
      __ CompareObject(R5, opt_param[i]->name(), PP);
      __ b(&load_default_value, NE);
      // Load R5 with passed-in argument at provided arg_pos, i.e. at
      // fp[kParamEndSlotFromFp + num_args - arg_pos].
      __ LoadFromOffset(R5, R6, ArgumentsDescriptor::position_offset());
      // R5 is arg_pos as Smi.
      // Point to next named entry.
      __ add(R6, R6, Operand(ArgumentsDescriptor::named_entry_size()));
      // Negate and untag R5 so we can use in scaled address mode.
      __ subs(R5, ZR, Operand(R5, ASR, 1));
      Address argument_addr(R7, R5, UXTX, Address::Scaled);  // R5 is untagged.
      __ ldr(R5, argument_addr);
      __ b(&assign_optional_parameter);
      __ Bind(&load_default_value);
      // Load R5 with default argument.
      const Object& value = Object::ZoneHandle(
          parsed_function().default_parameter_values().At(
              param_pos - num_fixed_params));
      __ LoadObject(R5, value, PP);
      __ Bind(&assign_optional_parameter);
      // Assign R5 to fp[kFirstLocalSlotFromFp - param_pos].
      // We do not use the final allocation index of the variable here, i.e.
      // scope->VariableAt(i)->index(), because captured variables still need
      // to be copied to the context that is not yet allocated.
      const intptr_t computed_param_pos = kFirstLocalSlotFromFp - param_pos;
      __ StoreToOffset(R5, FP, computed_param_pos * kWordSize);
    }
    delete[] opt_param;
    delete[] opt_param_position;
    if (check_correct_named_args) {
      // Check that R6 now points to the null terminator in the arguments
      // descriptor.
      __ ldr(R5, Address(R6));
      __ CompareObject(R5, Object::null_object(), PP);
      __ b(&all_arguments_processed, EQ);
    }
  } else {
    ASSERT(num_opt_pos_params > 0);
    __ LoadFieldFromOffset(
        R8, R4, ArgumentsDescriptor::positional_count_offset());
    __ SmiUntag(R8);
    for (int i = 0; i < num_opt_pos_params; i++) {
      Label next_parameter;
      // Handle this optional positional parameter only if k or fewer positional
      // arguments have been passed, where k is param_pos, the position of this
      // optional parameter in the formal parameter list.
      const int param_pos = num_fixed_params + i;
      __ CompareImmediate(R8, param_pos, PP);
      __ b(&next_parameter, GT);
      // Load R5 with default argument.
      const Object& value = Object::ZoneHandle(
          parsed_function().default_parameter_values().At(i));
      __ LoadObject(R5, value, PP);
      // Assign R5 to fp[kFirstLocalSlotFromFp - param_pos].
      // We do not use the final allocation index of the variable here, i.e.
      // scope->VariableAt(i)->index(), because captured variables still need
      // to be copied to the context that is not yet allocated.
      const intptr_t computed_param_pos = kFirstLocalSlotFromFp - param_pos;
      __ StoreToOffset(R5, FP, computed_param_pos * kWordSize);
      __ Bind(&next_parameter);
    }
    if (check_correct_named_args) {
      __ LoadFieldFromOffset(R7, R4, ArgumentsDescriptor::count_offset());
      __ SmiUntag(R7);
      // Check that R8 equals R7, i.e. no named arguments passed.
      __ CompareRegisters(R8, R7);
      __ b(&all_arguments_processed, EQ);
    }
  }

  __ Bind(&wrong_num_arguments);
  if (function.IsClosureFunction()) {
    // Invoke noSuchMethod function passing "call" as the original name.
    const int kNumArgsChecked = 1;
    const ICData& ic_data = ICData::ZoneHandle(
        ICData::New(function, Symbols::Call(), Object::empty_array(),
                    Isolate::kNoDeoptId, kNumArgsChecked));
    __ LoadObject(R5, ic_data, PP);
    __ LeaveDartFrame();  // The arguments are still on the stack.
    __ Branch(&StubCode::CallNoSuchMethodFunctionLabel(), PP);
    // The noSuchMethod call may return to the caller, but not here.
    __ hlt(0);
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
  __ LoadFieldFromOffset(R8, R4, ArgumentsDescriptor::count_offset());
  __ SmiUntag(R8);
  __ add(R7, FP, Operand((kParamEndSlotFromFp + 1) * kWordSize));
  const Address original_argument_addr(R7, R8, UXTX, Address::Scaled);
  __ LoadObject(TMP, Object::null_object(), PP);
  Label null_args_loop, null_args_loop_condition;
  __ b(&null_args_loop_condition);
  __ Bind(&null_args_loop);
  __ str(TMP, original_argument_addr);
  __ Bind(&null_args_loop_condition);
  __ subs(R8, R8, Operand(1));
  __ b(&null_args_loop, PL);
}


void FlowGraphCompiler::GenerateInlinedGetter(intptr_t offset) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::GenerateInlinedSetter(intptr_t offset) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitFrameEntry() {
  const Function& function = parsed_function().function();
  Register new_pp = kNoPP;
  if (CanOptimizeFunction() &&
      function.IsOptimizable() &&
      (!is_optimizing() || may_reoptimize())) {
    const Register function_reg = R6;
    new_pp = R13;

    // Set up pool pointer in new_pp.
    __ LoadPoolPointer(new_pp);

    // Load function object using the callee's pool pointer.
    __ LoadObject(function_reg, function, new_pp);

    // Patch point is after the eventually inlined function object.
    AddCurrentDescriptor(PcDescriptors::kEntryPatch,
                         Isolate::kNoDeoptId,
                         0);  // No token position.
    intptr_t threshold = FLAG_optimization_counter_threshold;
    __ LoadFieldFromOffset(R7, function_reg, Function::usage_counter_offset());
    if (is_optimizing()) {
      // Reoptimization of an optimized function is triggered by counting in
      // IC stubs, but not at the entry of the function.
      threshold = FLAG_reoptimization_counter_threshold;
    } else {
      __ add(R7, R7, Operand(1));
      __ StoreFieldToOffset(R7, function_reg, Function::usage_counter_offset());
    }
    __ CompareImmediate(R7, threshold, new_pp);
    ASSERT(function_reg == R6);
    Label dont_optimize;
    __ b(&dont_optimize, LT);
    __ Branch(&StubCode::OptimizeFunctionLabel(), new_pp);
    __ Bind(&dont_optimize);
  } else if (!flow_graph().IsCompiledForOsr()) {
    // We have to load the PP here too because a load of an external label
    // may be patched at the AddCurrentDescriptor below.
    new_pp = R13;

    __ LoadPoolPointer(new_pp);

    AddCurrentDescriptor(PcDescriptors::kEntryPatch,
                         Isolate::kNoDeoptId,
                         0);  // No token position.
  }
  __ Comment("Enter frame");
  if (flow_graph().IsCompiledForOsr()) {
    intptr_t extra_slots = StackSize()
        - flow_graph().num_stack_locals()
        - flow_graph().num_copied_params();
    ASSERT(extra_slots >= 0);
    __ EnterOsrFrame(extra_slots * kWordSize, new_pp);
  } else {
    ASSERT(StackSize() >= 0);
    __ EnterDartFrameWithInfo(StackSize() * kWordSize, new_pp);
  }
}


// Input parameters:
//   LR: return address.
//   SP: address of last argument.
//   FP: caller's frame pointer.
//   PP: caller's pool pointer.
//   R5: ic-data.
//   R4: arguments descriptor array.
void FlowGraphCompiler::CompileGraph() {
  InitCompiler();

  TryIntrinsify();

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
#ifdef DEBUG
    ASSERT(!parsed_function().function().HasOptionalParameters());
    const bool check_arguments = !flow_graph().IsCompiledForOsr();
#else
    const bool check_arguments =
        function.IsClosureFunction() && !flow_graph().IsCompiledForOsr();
#endif
    if (check_arguments) {
      __ Comment("Check argument count");
      // Check that exactly num_fixed arguments are passed in.
      Label correct_num_arguments, wrong_num_arguments;
      __ LoadFieldFromOffset(R0, R4, ArgumentsDescriptor::count_offset());
      __ CompareImmediate(R0, Smi::RawValue(num_fixed_params), PP);
      __ b(&wrong_num_arguments, NE);
      __ LoadFieldFromOffset(R1, R4,
            ArgumentsDescriptor::positional_count_offset());
      __ CompareRegisters(R0, R1);
      __ b(&correct_num_arguments, EQ);
      __ Bind(&wrong_num_arguments);
      if (function.IsClosureFunction()) {
        // Invoke noSuchMethod function passing the original function name.
        // For closure functions, use "call" as the original name.
        const String& name =
            String::Handle(function.IsClosureFunction()
                             ? Symbols::Call().raw()
                             : function.name());
        const int kNumArgsChecked = 1;
        const ICData& ic_data = ICData::ZoneHandle(
            ICData::New(function, name, Object::empty_array(),
                        Isolate::kNoDeoptId, kNumArgsChecked));
        __ LoadObject(R5, ic_data, PP);
        __ LeaveDartFrame();  // The arguments are still on the stack.
        __ Branch(&StubCode::CallNoSuchMethodFunctionLabel(), PP);
        // The noSuchMethod call may return to the caller, but not here.
        __ hlt(0);
      } else {
        __ Stop("Wrong number of arguments");
      }
      __ Bind(&correct_num_arguments);
    }
  } else if (!flow_graph().IsCompiledForOsr()) {
    CopyParameters();
  }

  // In unoptimized code, initialize (non-argument) stack allocated slots to
  // null.
  if (!is_optimizing() && (num_locals > 0)) {
    __ Comment("Initialize spill slots");
    const intptr_t slot_base = parsed_function().first_stack_local_index();
    __ LoadObject(R0, Object::null_object(), PP);
    for (intptr_t i = 0; i < num_locals; ++i) {
      // Subtract index i (locals lie at lower addresses than FP).
      __ StoreToOffset(R0, FP, (slot_base - i) * kWordSize);
    }
  }

  VisitBlocks();

  __ hlt(0);
  GenerateDeferredCode();
  // Emit function patching code. This will be swapped with the first 3
  // instructions at entry point.
  AddCurrentDescriptor(PcDescriptors::kPatchCode,
                       Isolate::kNoDeoptId,
                       0);  // No token position.
  // This is patched up to a point in FrameEntry where the PP for the
  // current function is in R13 instead of PP.
  __ BranchPatchable(&StubCode::FixCallersTargetLabel(), R13);

  AddCurrentDescriptor(PcDescriptors::kLazyDeoptJump,
                       Isolate::kNoDeoptId,
                       0);  // No token position.
  // TODO(zra): Can I use a normal BranchPatchable here? Probably have to change
  // the CodePatcher.
  __ BranchFixed(&StubCode::DeoptimizeLazyLabel());
}


void FlowGraphCompiler::GenerateCall(intptr_t token_pos,
                                     const ExternalLabel* label,
                                     PcDescriptors::Kind kind,
                                     LocationSummary* locs) {
  __ BranchLinkPatchable(label);
  AddCurrentDescriptor(kind, Isolate::kNoDeoptId, token_pos);
  RecordSafepoint(locs);
}


void FlowGraphCompiler::GenerateDartCall(intptr_t deopt_id,
                                         intptr_t token_pos,
                                         const ExternalLabel* label,
                                         PcDescriptors::Kind kind,
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
    AddCurrentDescriptor(PcDescriptors::kDeopt, deopt_id_after, token_pos);
  }
}


void FlowGraphCompiler::GenerateRuntimeCall(intptr_t token_pos,
                                            intptr_t deopt_id,
                                            const RuntimeEntry& entry,
                                            intptr_t argument_count,
                                            LocationSummary* locs) {
  __ CallRuntime(entry, argument_count);
  AddCurrentDescriptor(PcDescriptors::kOther, deopt_id, token_pos);
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
      AddCurrentDescriptor(PcDescriptors::kDeopt, deopt_id_after, token_pos);
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
  __ LoadObject(R0, counter, PP);
  __ LoadFieldFromOffset(TMP, R0, Array::element_offset(0));
  __ add(TMP, TMP, Operand(Smi::RawValue(1)));
  __ StoreFieldToOffset(TMP, R0, Array::element_offset(0));
}


void FlowGraphCompiler::EmitOptimizedInstanceCall(
    ExternalLabel* target_label,
    const ICData& ic_data,
    intptr_t argument_count,
    intptr_t deopt_id,
    intptr_t token_pos,
    LocationSummary* locs) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitInstanceCall(ExternalLabel* target_label,
                                         const ICData& ic_data,
                                         intptr_t argument_count,
                                         intptr_t deopt_id,
                                         intptr_t token_pos,
                                         LocationSummary* locs) {
  ASSERT(Array::Handle(ic_data.arguments_descriptor()).Length() > 0);
  __ LoadObject(R5, ic_data, PP);
  GenerateDartCall(deopt_id,
                   token_pos,
                   target_label,
                   PcDescriptors::kIcCall,
                   locs);
  __ Drop(argument_count);
}


void FlowGraphCompiler::EmitMegamorphicInstanceCall(
    const ICData& ic_data,
    intptr_t argument_count,
    intptr_t deopt_id,
    intptr_t token_pos,
    LocationSummary* locs) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitUnoptimizedStaticCall(
    const Function& target_function,
    const Array& arguments_descriptor,
    intptr_t argument_count,
    intptr_t deopt_id,
    intptr_t token_pos,
    LocationSummary* locs) {
  // TODO(srdjan): Improve performance of function recognition.
  MethodRecognizer::Kind recognized_kind =
      MethodRecognizer::RecognizeKind(target_function);
  int num_args_checked = 0;
  if ((recognized_kind == MethodRecognizer::kMathMin) ||
      (recognized_kind == MethodRecognizer::kMathMax)) {
    num_args_checked = 2;
  }
  const ICData& ic_data = ICData::ZoneHandle(
      ICData::New(parsed_function().function(),  // Caller function.
                  String::Handle(target_function.name()),
                  arguments_descriptor,
                  deopt_id,
                  num_args_checked));  // No arguments checked.
  ic_data.AddTarget(target_function);
  uword label_address = 0;
  if (ic_data.NumArgsTested() == 0) {
    label_address = StubCode::ZeroArgsUnoptimizedStaticCallEntryPoint();
  } else if (ic_data.NumArgsTested() == 2) {
    label_address = StubCode::TwoArgsUnoptimizedStaticCallEntryPoint();
  } else {
    UNIMPLEMENTED();
  }
  ExternalLabel target_label("StaticCallICStub", label_address);
  __ LoadObject(R5, ic_data, PP);
  GenerateDartCall(deopt_id,
                   token_pos,
                   &target_label,
                   PcDescriptors::kUnoptStaticCall,
                   locs);
  __ Drop(argument_count);
}


void FlowGraphCompiler::EmitOptimizedStaticCall(
    const Function& function,
    const Array& arguments_descriptor,
    intptr_t argument_count,
    intptr_t deopt_id,
    intptr_t token_pos,
    LocationSummary* locs) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitEqualityRegConstCompare(Register reg,
                                                    const Object& obj,
                                                    bool needs_number_check,
                                                    intptr_t token_pos) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitEqualityRegRegCompare(Register left,
                                                  Register right,
                                                  bool needs_number_check,
                                                  intptr_t token_pos) {
  if (needs_number_check) {
    __ Push(left);
    __ Push(right);
    if (is_optimizing()) {
      __ BranchLinkPatchable(
          &StubCode::OptimizedIdenticalWithNumberCheckLabel());
    } else {
      __ BranchLinkPatchable(
          &StubCode::UnoptimizedIdenticalWithNumberCheckLabel());
    }
    if (token_pos != Scanner::kNoSourcePos) {
      AddCurrentDescriptor(PcDescriptors::kRuntimeCall,
                           Isolate::kNoDeoptId,
                           token_pos);
    }
    // Stub returns result in flags (result of a cmpl, we need ZF computed).
    __ Pop(right);
    __ Pop(left);
  } else {
    __ CompareRegisters(left, right);
  }
}


// This function must be in sync with FlowGraphCompiler::RecordSafepoint and
// FlowGraphCompiler::SlowPathEnvironmentFor.
void FlowGraphCompiler::SaveLiveRegisters(LocationSummary* locs) {
  // TODO(zra): Save live FPU Registers.

  // Store general purpose registers with the highest register number at the
  // lowest address.
  for (intptr_t reg_idx = 0; reg_idx < kNumberOfCpuRegisters; ++reg_idx) {
    Register reg = static_cast<Register>(reg_idx);
    if (locs->live_registers()->ContainsRegister(reg)) {
      __ Push(reg);
    }
  }
}


void FlowGraphCompiler::RestoreLiveRegisters(LocationSummary* locs) {
  // General purpose registers have the highest register number at the
  // lowest address.
  for (intptr_t reg_idx = kNumberOfCpuRegisters - 1; reg_idx >= 0; --reg_idx) {
    Register reg = static_cast<Register>(reg_idx);
    if (locs->live_registers()->ContainsRegister(reg)) {
      __ Pop(reg);
    }
  }

  // TODO(zra): Restore live FPU registers.
}


void FlowGraphCompiler::EmitTestAndCall(const ICData& ic_data,
                                        Register class_id_reg,
                                        intptr_t argument_count,
                                        const Array& argument_names,
                                        Label* deopt,
                                        intptr_t deopt_id,
                                        intptr_t token_index,
                                        LocationSummary* locs) {
  UNIMPLEMENTED();
}


// Do not implement or use this function.
FieldAddress FlowGraphCompiler::ElementAddressForIntIndex(intptr_t cid,
                                                          intptr_t index_scale,
                                                          Register array,
                                                          intptr_t index) {
  UNREACHABLE();
  return FieldAddress(array, index);
}


// Do not implement or use this function.
FieldAddress FlowGraphCompiler::ElementAddressForRegIndex(intptr_t cid,
                                                          intptr_t index_scale,
                                                          Register array,
                                                          Register index) {
  UNREACHABLE();  // No register indexed with offset addressing mode on ARM.
  return FieldAddress(array, index);
}


Address FlowGraphCompiler::ExternalElementAddressForIntIndex(
    intptr_t index_scale,
    Register array,
    intptr_t index) {
  UNREACHABLE();
  return FieldAddress(array, index);
}


Address FlowGraphCompiler::ExternalElementAddressForRegIndex(
    intptr_t index_scale,
    Register array,
    Register index) {
  UNREACHABLE();
  return FieldAddress(array, index);
}


#undef __
#define __ compiler_->assembler()->


void ParallelMoveResolver::EmitMove(int index) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::EmitSwap(int index) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::MoveMemoryToMemory(const Address& dst,
                                              const Address& src) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::StoreObject(const Address& dst, const Object& obj) {
  UNIMPLEMENTED();
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


void ParallelMoveResolver::Exchange(Register reg, intptr_t stack_offset) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::Exchange(intptr_t stack_offset1,
                                    intptr_t stack_offset2) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::SpillScratch(Register reg) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::RestoreScratch(Register reg) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::SpillFpuScratch(FpuRegister reg) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::RestoreFpuScratch(FpuRegister reg) {
  UNIMPLEMENTED();
}


#undef __

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64

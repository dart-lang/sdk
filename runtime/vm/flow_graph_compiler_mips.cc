// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_MIPS.
#if defined(TARGET_ARCH_MIPS)

#include "vm/flow_graph_compiler.h"

#include "lib/error.h"
#include "vm/ast_printer.h"
#include "vm/dart_entry.h"
#include "vm/il_printer.h"
#include "vm/locations.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool, trap_on_deoptimization, false, "Trap on deoptimization.");
DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(bool, print_ast);
DECLARE_FLAG(bool, print_scopes);
DECLARE_FLAG(bool, enable_type_checks);
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


void CompilerDeoptInfoWithStub::GenerateCode(FlowGraphCompiler* compiler,
                                             intptr_t stub_ix) {
  // Calls do not need stubs, they share a deoptimization trampoline.
  ASSERT(reason() != kDeoptAtCall);
  Assembler* assem = compiler->assembler();
#define __ assem->
  __ Comment("Deopt stub for id %"Pd"", deopt_id());
  __ Bind(entry_label());
  if (FLAG_trap_on_deoptimization) __ break_(0);

  ASSERT(deoptimization_env() != NULL);

  __ BranchLink(&StubCode::DeoptimizeLabel());
  set_pc_offset(assem->CodeSize());
#undef __
}


#define __ assembler()->


// Fall through if bool_register contains null.
void FlowGraphCompiler::GenerateBoolToJump(Register bool_register,
                                           Label* is_true,
                                           Label* is_false) {
  Label fall_through;
  __ BranchEqual(bool_register, reinterpret_cast<intptr_t>(Object::null()),
                 &fall_through);
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
  ASSERT(instance_reg == A0);
  ASSERT(temp_reg == kNoRegister);  // Unused on MIPS.
  const SubtypeTestCache& type_test_cache =
      SubtypeTestCache::ZoneHandle(SubtypeTestCache::New());
  __ LoadObject(A2, type_test_cache);
  if (test_kind == kTestTypeOneArg) {
    ASSERT(type_arguments_reg == kNoRegister);
    __ LoadImmediate(A1, reinterpret_cast<intptr_t>(Object::null()));
    __ BranchLink(&StubCode::Subtype1TestCacheLabel());
  } else if (test_kind == kTestTypeTwoArgs) {
    ASSERT(type_arguments_reg == kNoRegister);
    __ LoadImmediate(A1, reinterpret_cast<intptr_t>(Object::null()));
    __ BranchLink(&StubCode::Subtype2TestCacheLabel());
  } else if (test_kind == kTestTypeThreeArgs) {
    ASSERT(type_arguments_reg == A1);
    __ BranchLink(&StubCode::Subtype3TestCacheLabel());
  } else {
    UNREACHABLE();
  }
  // Result is in V0: null -> not found, otherwise Bool::True or Bool::False.
  GenerateBoolToJump(V0, is_instance_lbl, is_not_instance_lbl);
  return type_test_cache.raw();
}


RawSubtypeTestCache*
FlowGraphCompiler::GenerateInstantiatedTypeWithArgumentsTest(
    intptr_t token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  UNIMPLEMENTED();
  return NULL;
}


void FlowGraphCompiler::CheckClassIds(Register class_id_reg,
                                      const GrowableArray<intptr_t>& class_ids,
                                      Label* is_equal_lbl,
                                      Label* is_not_equal_lbl) {
  for (intptr_t i = 0; i < class_ids.length(); i++) {
    __ BranchEqual(class_id_reg, class_ids[i], is_equal_lbl);
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
  __ Comment("InstantiatedTypeNoArgumentsTest");
  ASSERT(type.IsInstantiated());
  const Class& type_class = Class::Handle(type.type_class());
  ASSERT(!type_class.HasTypeArguments());

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
  __ BranchEqual(kClassIdReg, type_class.id(), is_instance_lbl);

  // See ClassFinalizer::ResolveSuperTypeAndInterfaces for list of restricted
  // interfaces.
  // Bool interface can be implemented only by core class Bool.
  if (type.IsBoolType()) {
    __ BranchEqual(kClassIdReg, kBoolCid, is_instance_lbl);
    __ b(is_not_instance_lbl);
    return false;
  }
  if (type.IsFunctionType()) {
    // Check if instance is a closure.
    __ LoadClassById(T1, kClassIdReg);
    __ lw(T1, FieldAddress(T1, Class::signature_function_offset()));
    __ BranchNotEqual(T1, reinterpret_cast<int32_t>(Object::null()),
                      is_instance_lbl);
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


RawSubtypeTestCache* FlowGraphCompiler::GenerateUninstantiatedTypeTest(
    intptr_t token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  UNIMPLEMENTED();
  return NULL;
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
  __ Comment("InlineInstanceof");
  if (type.IsVoidType()) {
    // A non-null value is returned from a void function, which will result in a
    // type error. A null value is handled prior to executing this inline code.
    return SubtypeTestCache::null();
  }
  if (TypeCheckAsClassEquality(type)) {
    const intptr_t type_cid = Class::Handle(type.type_class()).id();
    const Register kInstanceReg = A0;
    __ andi(T0, kInstanceReg, Immediate(kSmiTagMask));
    if (type_cid == kSmiCid) {
      __ beq(T0, ZR, is_instance_lbl);
    } else {
      __ beq(T0, ZR, is_not_instance_lbl);
      __ LoadClassId(T0, kInstanceReg);
      __ BranchEqual(T0, type_cid, is_instance_lbl);
    }
    __ b(is_not_instance_lbl);
    return SubtypeTestCache::null();
  }
  if (type.IsInstantiated()) {
    const Class& type_class = Class::ZoneHandle(type.type_class());
    // A Smi object cannot be the instance of a parameterized class.
    // A class equality check is only applicable with a dst type of a
    // non-parameterized class or with a raw dst type of a parameterized class.
    if (type_class.HasTypeArguments()) {
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
  ASSERT(token_pos >= 0);
  ASSERT(!dst_type.IsNull());
  ASSERT(dst_type.IsFinalized());
  // Assignable check is skipped in FlowGraphBuilder, not here.
  ASSERT(dst_type.IsMalformed() ||
         (!dst_type.IsDynamicType() && !dst_type.IsObjectType()));
  // Preserve instantiator and its type arguments.
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(A2, Address(SP, 1 * kWordSize));
  __ sw(A1, Address(SP, 0 * kWordSize));
  // A null object is always assignable and is returned as result.
  Label is_assignable, runtime_call;
  __ BranchEqual(A0, reinterpret_cast<int32_t>(Object::null()), &is_assignable);

  if (!FLAG_eliminate_type_checks) {
    // If type checks are not eliminated during the graph building then
    // a transition sentinel can be seen here.
    __ BranchEqual(A0, Object::transition_sentinel(), &is_assignable);
  }

  // Generate throw new TypeError() if the type is malformed.
  if (dst_type.IsMalformed()) {
    const Error& error = Error::Handle(dst_type.malformed_error());
    const String& error_message = String::ZoneHandle(
        Symbols::New(error.ToErrorCString()));
    __ PushObject(Object::ZoneHandle());  // Make room for the result.
    __ Push(A0);  // Push the source object.
    __ PushObject(dst_name);  // Push the name of the destination.
    __ PushObject(error_message);
    GenerateCallRuntime(token_pos,
                        deopt_id,
                        kMalformedTypeErrorRuntimeEntry,
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
  // Load instantiator and its type arguments.
  __ lw(A1, Address(SP, 0 * kWordSize));
  __ lw(A2, Address(SP, 1 * kWordSize));
  __ addiu(SP, SP, Immediate(2 * kWordSize));
  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  __ Push(A0);  // Push the source object.
  __ PushObject(dst_type);  // Push the type of the destination.
  // Push instantiator and its type arguments.
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(A2, Address(SP, 1 * kWordSize));
  __ sw(A1, Address(SP, 0 * kWordSize));
  __ PushObject(dst_name);  // Push the name of the destination.
  __ LoadObject(T0, test_cache);
  __ Push(T0);
  GenerateCallRuntime(token_pos, deopt_id, kTypeCheckRuntimeEntry, locs);
  // Pop the parameters supplied to the runtime entry. The result of the
  // type check runtime call is the checked value.
  __ Drop(6);
  __ Pop(A0);

  __ Bind(&is_assignable);
  // Restore instantiator and its type arguments.
  __ lw(A1, Address(SP, 0 * kWordSize));
  __ lw(A2, Address(SP, 1 * kWordSize));
  __ addiu(SP, SP, Immediate(2 * kWordSize));
}


void FlowGraphCompiler::EmitInstructionPrologue(Instruction* instr) {
  if (!is_optimizing()) {
    if (FLAG_enable_type_checks && instr->IsAssertAssignable()) {
      AssertAssignableInstr* assert = instr->AsAssertAssignable();
      AddCurrentDescriptor(PcDescriptors::kDeopt,
                           assert->deopt_id(),
                           assert->token_pos());
    } else if (instr->IsGuardField()) {
      GuardFieldInstr* guard = instr->AsGuardField();
      AddCurrentDescriptor(PcDescriptors::kDeopt,
                           guard->deopt_id(),
                           Scanner::kDummyTokenIndex);
    } else if (instr->CanBeDeoptimizationTarget()) {
      AddCurrentDescriptor(PcDescriptors::kDeopt,
                           instr->deopt_id(),
                           Scanner::kDummyTokenIndex);
    }
    AllocateRegistersLocally(instr);
  }
}


void FlowGraphCompiler::EmitInstructionEpilogue(Instruction* instr) {
  if (is_optimizing()) return;
  Definition* defn = instr->AsDefinition();
  if ((defn != NULL) && defn->is_used()) {
    __ Push(defn->locs()->out().reg());
  }
}


// Input parameters:
//   S4: arguments descriptor array.
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
  ASSERT(parsed_function().first_parameter_index() == kFirstLocalSlotIndex);

  // Check that min_num_pos_args <= num_pos_args <= max_num_pos_args,
  // where num_pos_args is the number of positional arguments passed in.
  const int min_num_pos_args = num_fixed_params;
  const int max_num_pos_args = num_fixed_params + num_opt_pos_params;

  __ lw(T2, FieldAddress(S4, ArgumentsDescriptor::positional_count_offset()));
  // Check that min_num_pos_args <= num_pos_args.
  Label wrong_num_arguments;
  __ BranchLess(T2, Smi::RawValue(min_num_pos_args), &wrong_num_arguments);

  // Check that num_pos_args <= max_num_pos_args.
  __ BranchGreater(T2, Smi::RawValue(max_num_pos_args), &wrong_num_arguments);

  // Copy positional arguments.
  // Argument i passed at fp[kLastParamSlotIndex + num_args - 1 - i] is copied
  // to fp[kFirstLocalSlotIndex - i].

  __ lw(T1, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
  // Since T1 and T2 are Smi, use sll 1 instead of sll 2.
  // Let T1 point to the last passed positional argument, i.e. to
  // fp[kLastParamSlotIndex + num_args - 1 - (num_pos_args - 1)].
  __ subu(T1, T1, T2);
  __ sll(T1, T1, 1);
  __ addu(T1, FP, T1);
  __ AddImmediate(T1, kLastParamSlotIndex * kWordSize);

  // Let T0 point to the last copied positional argument, i.e. to
  // fp[kFirstLocalSlotIndex - (num_pos_args - 1)].
  __ AddImmediate(T0, FP, (kFirstLocalSlotIndex + 1) * kWordSize);
  __ sll(T3, T2, 1);  // T2 is a Smi.
  __ subu(T0, T0, T3);

  Label loop, loop_condition;
  __ b(&loop_condition);
  __ delay_slot()->SmiUntag(T2);
  // We do not use the final allocation index of the variable here, i.e.
  // scope->VariableAt(i)->index(), because captured variables still need
  // to be copied to the context that is not yet allocated.
  __ Bind(&loop);
  __ addu(T4, T1, T2);
  __ addu(T5, T0, T2);
  __ lw(T3, Address(T4));
  __ sw(T3, Address(T5));
  __ Bind(&loop_condition);
  __ addiu(T2, T2, Immediate(-kWordSize));
  __ bgez(T2, &loop);

  // Copy or initialize optional named arguments.
  Label all_arguments_processed;
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
    __ lw(T1, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
    __ lw(T2, FieldAddress(S4, ArgumentsDescriptor::positional_count_offset()));
    __ SmiUntag(T2);
    // Let T1 point to the first passed argument, i.e. to
    // fp[kLastParamSlotIndex + num_args - 1 - 0]; num_args (T1) is Smi.
    __ sll(T3, T1, 1);
    __ addu(T1, FP, T3);
    __ AddImmediate(T1, (kLastParamSlotIndex - 1) * kWordSize);
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
      // fp[kLastParamSlotIndex + num_args - 1 - arg_pos].
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
      // Assign T3 to fp[kFirstLocalSlotIndex - param_pos].
      // We do not use the final allocation index of the variable here, i.e.
      // scope->VariableAt(i)->index(), because captured variables still need
      // to be copied to the context that is not yet allocated.
      const intptr_t computed_param_pos = kFirstLocalSlotIndex - param_pos;
      __ sw(T3, Address(FP, computed_param_pos * kWordSize));
    }
    delete[] opt_param;
    delete[] opt_param_position;
    // Check that T0 now points to the null terminator in the array descriptor.
    __ lw(T3, Address(T0));
    __ BranchEqual(T3, reinterpret_cast<int32_t>(Object::null()),
                &all_arguments_processed);
  } else {
    ASSERT(num_opt_pos_params > 0);
    __ lw(T2,
          FieldAddress(S4, ArgumentsDescriptor::positional_count_offset()));
    __ SmiUntag(T2);
    for (int i = 0; i < num_opt_pos_params; i++) {
      Label next_parameter;
      // Handle this optional positional parameter only if k or fewer positional
      // arguments have been passed, where k is param_pos, the position of this
      // optional parameter in the formal parameter list.
      const int param_pos = num_fixed_params + i;
      __ BranchGreater(T2, param_pos, &next_parameter);
      // Load T3 with default argument.
      const Object& value = Object::ZoneHandle(
          parsed_function().default_parameter_values().At(i));
      __ LoadObject(T3, value);
      // Assign T3 to fp[kFirstLocalSlotIndex - param_pos].
      // We do not use the final allocation index of the variable here, i.e.
      // scope->VariableAt(i)->index(), because captured variables still need
      // to be copied to the context that is not yet allocated.
      const intptr_t computed_param_pos = kFirstLocalSlotIndex - param_pos;
      __ sw(T3, Address(FP, computed_param_pos * kWordSize));
      __ Bind(&next_parameter);
    }
    __ lw(T1, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
    __ SmiUntag(T1);
    // Check that T2 equals T1, i.e. no named arguments passed.
    __ beq(T2, T1, &all_arguments_processed);
  }

  __ Bind(&wrong_num_arguments);
  if (StackSize() != 0) {
    // We need to unwind the space we reserved for locals and copied parameters.
    // The NoSuchMethodFunction stub does not expect to see that area on the
    // stack.
    __ AddImmediate(SP, StackSize() * kWordSize);
  }
  // The call below has an empty stackmap because we have just
  // dropped the spill slots.
  BitmapBuilder* empty_stack_bitmap = new BitmapBuilder();

  // Invoke noSuchMethod function passing the original name of the function.
  // If the function is a closure function, use "call" as the original name.
  const String& name = String::Handle(
      function.IsClosureFunction() ? Symbols::Call().raw() : function.name());
  const int kNumArgsChecked = 1;
  const ICData& ic_data = ICData::ZoneHandle(
      ICData::New(function, name, Isolate::kNoDeoptId, kNumArgsChecked));
  __ LoadObject(S5, ic_data);
  // FP - 4 : saved PP, object pool pointer of caller.
  // FP + 0 : previous frame pointer.
  // FP + 4 : return address.
  // FP + 8 : PC marker, for easy identification of RawInstruction obj.
  // FP + 12: last argument (arg n-1).
  // SP + 0 : saved PP.
  // SP + 16 + 4*(n-1) : first argument (arg 0).
  // S5 : ic-data.
  // S4 : arguments descriptor array.
  __ BranchLink(&StubCode::CallNoSuchMethodFunctionLabel());
  if (is_optimizing()) {
    stackmap_table_builder_->AddEntry(assembler()->CodeSize(),
                                      empty_stack_bitmap,
                                      0);  // No registers.
  }
  // The noSuchMethod call may return.
  __ LeaveDartFrame();
  __ Ret();

  __ Bind(&all_arguments_processed);
  // Nullify originally passed arguments only after they have been copied and
  // checked, otherwise noSuchMethod would not see their original values.
  // This step can be skipped in case we decide that formal parameters are
  // implicitly final, since garbage collecting the unmodified value is not
  // an issue anymore.

  // S4 : arguments descriptor array.
  __ lw(T2, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
  __ SmiUntag(T2);

  __ LoadImmediate(T0, reinterpret_cast<intptr_t>(Object::null()));
  Label null_args_loop, null_args_loop_condition;
  __ b(&null_args_loop_condition);
  __ delay_slot()->addiu(T1, FP, Immediate(kLastParamSlotIndex * kWordSize));
  __ Bind(&null_args_loop);
  __ addu(T3, T1, T2);
  __ sw(T0, Address(T3));
  __ Bind(&null_args_loop_condition);
  __ addiu(T2, T2, Immediate(-kWordSize));
  __ bgez(T2, &null_args_loop);
}


void FlowGraphCompiler::GenerateInlinedGetter(intptr_t offset) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::GenerateInlinedSetter(intptr_t offset) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitFrameEntry() {
  const Function& function = parsed_function().function();
  if (CanOptimizeFunction() && function.is_optimizable()) {
    const bool can_optimize = !is_optimizing() || may_reoptimize();
    const Register function_reg = T0;
    if (can_optimize) {
      Label next;
      // The pool pointer is not setup before entering the Dart frame.

      __ mov(TMP1, RA);  // Save RA.
      __ bal(&next);  // Branch and link to next instruction to get PC in RA.
      __ delay_slot()->mov(T2, RA);  // Save PC of the following mov.

      // Calculate offset of pool pointer from the PC.
      const intptr_t object_pool_pc_dist =
         Instructions::HeaderSize() - Instructions::object_pool_offset() +
         assembler()->CodeSize();

      __ Bind(&next);
      __ mov(RA, TMP1);  // Restore RA.

      // Preserve PP of caller.
      __ mov(T1, PP);

      // Temporarily setup pool pointer for this dart function.
      __ lw(PP, Address(T2, -object_pool_pc_dist));

      // Load function object from object pool.
      __ LoadObject(function_reg, function);  // Uses PP.

      // Restore PP of caller.
      __ mov(PP, T1);
    }
    // Patch point is after the eventually inlined function object.
    AddCurrentDescriptor(PcDescriptors::kEntryPatch,
                         Isolate::kNoDeoptId,
                         0);  // No token position.
    if (can_optimize) {
      // Reoptimization of optimized function is triggered by counting in
      // IC stubs, but not at the entry of the function.
      if (!is_optimizing()) {
        __ lw(T1, FieldAddress(function_reg,
                               Function::usage_counter_offset()));
        __ addiu(T1, T1, Immediate(1));
        __ sw(T1, FieldAddress(function_reg,
                               Function::usage_counter_offset()));
      } else {
        __ lw(T1, FieldAddress(function_reg,
                               Function::usage_counter_offset()));
      }

      // Skip Branch if T1 is less than the threshold.
      Label dont_branch;
      __ BranchLess(T1, FLAG_optimization_counter_threshold, &dont_branch);

      ASSERT(function_reg == T0);
      __ Branch(&StubCode::OptimizeFunctionLabel());

      __ Bind(&dont_branch);
    }
  } else {
    AddCurrentDescriptor(PcDescriptors::kEntryPatch,
                         Isolate::kNoDeoptId,
                         0);  // No token position.
  }
  __ Comment("Enter frame");
  __ EnterDartFrame((StackSize() * kWordSize));
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
  if (TryIntrinsify()) {
    // Although this intrinsified code will never be patched, it must satisfy
    // CodePatcher::CodeIsPatchable, which verifies that this code has a minimum
    // code size.
    __ break_(0);
    __ Branch(&StubCode::FixCallersTargetLabel());
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
  LocalVariable* saved_args_desc_var =
      parsed_function().GetSavedArgumentsDescriptorVar();
  if (num_copied_params == 0) {
#ifdef DEBUG
    ASSERT(!parsed_function().function().HasOptionalParameters());
    const bool check_arguments = true;
#else
    const bool check_arguments = function.IsClosureFunction();
#endif
    if (check_arguments) {
      __ Comment("Check argument count");
      // Check that exactly num_fixed arguments are passed in.
      Label correct_num_arguments, wrong_num_arguments;
      __ lw(T0, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
      __ BranchNotEqual(T0, Smi::RawValue(num_fixed_params),
                        &wrong_num_arguments);

      __ lw(T1, FieldAddress(S4,
                             ArgumentsDescriptor::positional_count_offset()));
      __ beq(T0, T1, &correct_num_arguments);
      __ Bind(&wrong_num_arguments);
      if (function.IsClosureFunction()) {
        if (StackSize() != 0) {
          // We need to unwind the space we reserved for locals and copied
          // parameters. The NoSuchMethodFunction stub does not expect to see
          // that area on the stack.
          __ AddImmediate(SP, StackSize() * kWordSize);
        }
        // The call below has an empty stackmap because we have just
        // dropped the spill slots.
        BitmapBuilder* empty_stack_bitmap = new BitmapBuilder();

        // Invoke noSuchMethod function passing "call" as the function name.
        const int kNumArgsChecked = 1;
        const ICData& ic_data = ICData::ZoneHandle(
            ICData::New(function, Symbols::Call(),
                        Isolate::kNoDeoptId, kNumArgsChecked));
        __ LoadObject(S5, ic_data);
        // FP - 4 : saved PP, object pool pointer of caller.
        // FP + 0 : previous frame pointer.
        // FP + 4 : return address.
        // FP + 8 : PC marker, for easy identification of RawInstruction obj.
        // FP + 12: last argument (arg n-1).
        // SP + 0 : saved PP.
        // SP + 16 + 4*(n-1) : first argument (arg 0).
        // S5 : ic-data.
        // S4 : arguments descriptor array.
        __ BranchLink(&StubCode::CallNoSuchMethodFunctionLabel());
        if (is_optimizing()) {
          stackmap_table_builder_->AddEntry(assembler()->CodeSize(),
                                            empty_stack_bitmap,
                                            0);  // No registers.
        }
        // The noSuchMethod call may return.
        __ LeaveDartFrame();
        __ Ret();
      } else {
        __ Stop("Wrong number of arguments");
      }
      __ Bind(&correct_num_arguments);
    }
    // The arguments descriptor is never saved in the absence of optional
    // parameters, since any argument definition test would always yield true.
    ASSERT(saved_args_desc_var == NULL);
  } else {
    if (saved_args_desc_var != NULL) {
      __ Comment("Save arguments descriptor");
      const Register kArgumentsDescriptorReg = S4;
      // The saved_args_desc_var is allocated one slot before the first local.
      const intptr_t slot = parsed_function().first_stack_local_index() + 1;
      // If the saved_args_desc_var is captured, it is first moved to the stack
      // and later to the context, once the context is allocated.
      ASSERT(saved_args_desc_var->is_captured() ||
             (saved_args_desc_var->index() == slot));
      __ sw(kArgumentsDescriptorReg, Address(FP, slot * kWordSize));
    }
    CopyParameters();
  }

  // In unoptimized code, initialize (non-argument) stack allocated slots to
  // null. This does not cover the saved_args_desc_var slot.
  if (!is_optimizing() && (num_locals > 0)) {
    __ Comment("Initialize spill slots");
    const intptr_t slot_base = parsed_function().first_stack_local_index();
    __ LoadImmediate(T0, reinterpret_cast<intptr_t>(Object::null()));
    for (intptr_t i = 0; i < num_locals; ++i) {
      // Subtract index i (locals lie at lower addresses than FP).
      __ sw(T0, Address(FP, (slot_base - i) * kWordSize));
    }
  }

  if (FLAG_print_scopes) {
    // Print the function scope (again) after generating the prologue in order
    // to see annotations such as allocation indices of locals.
    if (FLAG_print_ast) {
      // Second printing.
      OS::Print("Annotated ");
    }
    AstPrinter::PrintFunctionScope(parsed_function());
  }

  VisitBlocks();

  __ break_(0);
  GenerateDeferredCode();
  // Emit function patching code. This will be swapped with the first 5 bytes
  // at entry point.
  AddCurrentDescriptor(PcDescriptors::kPatchCode,
                       Isolate::kNoDeoptId,
                       0);  // No token position.
  __ Branch(&StubCode::FixCallersTargetLabel());
  AddCurrentDescriptor(PcDescriptors::kLazyDeoptJump,
                       Isolate::kNoDeoptId,
                       0);  // No token position.
  __ Branch(&StubCode::DeoptimizeLazyLabel());
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
    AddCurrentDescriptor(PcDescriptors::kDeopt,
                         deopt_id_after,
                         token_pos);
  }
}


void FlowGraphCompiler::GenerateCallRuntime(intptr_t token_pos,
                                            intptr_t deopt_id,
                                            const RuntimeEntry& entry,
                                            LocationSummary* locs) {
  __ CallRuntime(entry);
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
      AddCurrentDescriptor(PcDescriptors::kDeopt,
                           deopt_id_after,
                           token_pos);
    }
  }
}


void FlowGraphCompiler::EmitOptimizedInstanceCall(
    ExternalLabel* target_label,
    const ICData& ic_data,
    const Array& arguments_descriptor,
    intptr_t argument_count,
    intptr_t deopt_id,
    intptr_t token_pos,
    LocationSummary* locs) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitInstanceCall(ExternalLabel* target_label,
                                         const ICData& ic_data,
                                         const Array& arguments_descriptor,
                                         intptr_t argument_count,
                                         intptr_t deopt_id,
                                         intptr_t token_pos,
                                         LocationSummary* locs) {
  __ LoadObject(S4, arguments_descriptor);
  __ LoadObject(S5, ic_data);
  GenerateDartCall(deopt_id,
                   token_pos,
                   target_label,
                   PcDescriptors::kIcCall,
                   locs);
  __ Drop(argument_count);
}


void FlowGraphCompiler::EmitMegamorphicInstanceCall(
    const ICData& ic_data,
    const Array& arguments_descriptor,
    intptr_t argument_count,
    intptr_t deopt_id,
    intptr_t token_pos,
    LocationSummary* locs) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitStaticCall(const Function& function,
                                       const Array& arguments_descriptor,
                                       intptr_t argument_count,
                                       intptr_t deopt_id,
                                       intptr_t token_pos,
                                       LocationSummary* locs) {
  __ LoadObject(S4, arguments_descriptor);
  // Do not use the code from the function, but let the code be patched so that
  // we can record the outgoing edges to other code.
  GenerateDartCall(deopt_id,
                   token_pos,
                   &StubCode::CallStaticFunctionLabel(),
                   PcDescriptors::kFuncCall,
                   locs);
  AddStaticCallTarget(function);
  __ Drop(argument_count);
}


void FlowGraphCompiler::EmitEqualityRegConstCompare(Register reg,
                                                    const Object& obj,
                                                    bool needs_number_check) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitEqualityRegRegCompare(Register left,
                                                  Register right,
                                                  bool needs_number_check) {
  if (needs_number_check) {
    __ Push(left);
    __ Push(right);
    __ BranchLink(&StubCode::IdenticalWithNumberCheckLabel());
    // Stub returns result in CMPRES. If it is 0, then left and right are equal.
    __ Pop(right);
    __ Pop(left);
  } else {
    __ subu(CMPRES, left, right);
  }
}


void FlowGraphCompiler::EmitSuperEqualityCallPrologue(Register result,
                                                      Label* skip_call) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::SaveLiveRegisters(LocationSummary* locs) {
  // TODO(vegorov): consider saving only caller save (volatile) registers.
  const intptr_t fpu_registers = locs->live_registers()->fpu_registers();
  if (fpu_registers > 0) {
    UNIMPLEMENTED();
  }

  // Store general purpose registers with the lowest register number at the
  // lowest address.
  const intptr_t cpu_registers = locs->live_registers()->cpu_registers();
  ASSERT((cpu_registers & ~kAllCpuRegistersList) == 0);
  const int register_count = Utils::CountOneBits(cpu_registers);
  int registers_pushed = 0;

  __ addiu(SP, SP, Immediate(-register_count * kWordSize));
  for (int i = 0; i < kNumberOfCpuRegisters; i++) {
    Register r = static_cast<Register>(i);
    if (locs->live_registers()->ContainsRegister(r)) {
      __ sw(r, Address(SP, registers_pushed * kWordSize));
      registers_pushed++;
    }
  }
}


void FlowGraphCompiler::RestoreLiveRegisters(LocationSummary* locs) {
  // General purpose registers have the lowest register number at the
  // lowest address.
  const intptr_t cpu_registers = locs->live_registers()->cpu_registers();
  ASSERT((cpu_registers & ~kAllCpuRegistersList) == 0);
  const int register_count = Utils::CountOneBits(cpu_registers);
  int registers_popped = 0;

  for (int i = 0; i < kNumberOfCpuRegisters; i++) {
    Register r = static_cast<Register>(i);
    if (locs->live_registers()->ContainsRegister(r)) {
      __ lw(r, Address(SP, registers_popped * kWordSize));
      registers_popped++;
    }
  }
  __ addiu(SP, SP, Immediate(register_count * kWordSize));

  const intptr_t fpu_registers = locs->live_registers()->fpu_registers();
  if (fpu_registers > 0) {
    UNIMPLEMENTED();
  }
}


void FlowGraphCompiler::EmitTestAndCall(const ICData& ic_data,
                                        Register class_id_reg,
                                        intptr_t arg_count,
                                        const Array& arg_names,
                                        Label* deopt,
                                        intptr_t deopt_id,
                                        intptr_t token_index,
                                        LocationSummary* locs) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitDoubleCompareBranch(Condition true_condition,
                                                FpuRegister left,
                                                FpuRegister right,
                                                BranchInstr* branch) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitDoubleCompareBool(Condition true_condition,
                                              FpuRegister left,
                                              FpuRegister right,
                                              Register result) {
  UNIMPLEMENTED();
}


Condition FlowGraphCompiler::FlipCondition(Condition condition) {
  UNIMPLEMENTED();
  return condition;
}


bool FlowGraphCompiler::EvaluateCondition(Condition condition,
                                          intptr_t left,
                                          intptr_t right) {
  UNIMPLEMENTED();
  return false;
}


FieldAddress FlowGraphCompiler::ElementAddressForIntIndex(intptr_t cid,
                                                          intptr_t index_scale,
                                                          Register array,
                                                          intptr_t index) {
  UNIMPLEMENTED();
  return FieldAddress(array, index);
}


FieldAddress FlowGraphCompiler::ElementAddressForRegIndex(intptr_t cid,
                                                          intptr_t index_scale,
                                                          Register array,
                                                          Register index) {
  UNIMPLEMENTED();
  return FieldAddress(array, index);
}


Address FlowGraphCompiler::ExternalElementAddressForIntIndex(
    intptr_t index_scale,
    Register array,
    intptr_t index) {
  UNIMPLEMENTED();
  return FieldAddress(array, index);
}


Address FlowGraphCompiler::ExternalElementAddressForRegIndex(
    intptr_t index_scale,
    Register array,
    Register index) {
  UNIMPLEMENTED();
  return FieldAddress(array, index);
}


#undef __
#define __ compiler_->assembler()->


void ParallelMoveResolver::EmitMove(int index) {
  MoveOperands* move = moves_[index];
  const Location source = move->src();
  const Location destination = move->dest();

  if (source.IsRegister()) {
    if (destination.IsRegister()) {
      __ mov(destination.reg(), source.reg());
    } else {
      ASSERT(destination.IsStackSlot());
      __ sw(source.reg(), destination.ToStackSlotAddress());
    }
  } else if (source.IsStackSlot()) {
    if (destination.IsRegister()) {
      __ lw(destination.reg(), source.ToStackSlotAddress());
    } else {
      ASSERT(destination.IsStackSlot());
      MoveMemoryToMemory(destination.ToStackSlotAddress(),
                         source.ToStackSlotAddress());
    }
  } else if (source.IsFpuRegister()) {
    if (destination.IsFpuRegister()) {
      __ movd(destination.fpu_reg(), source.fpu_reg());
    } else {
      if (destination.IsDoubleStackSlot()) {
        __ sdc1(source.fpu_reg(), destination.ToStackSlotAddress());
      } else {
        ASSERT(destination.IsQuadStackSlot());
        UNIMPLEMENTED();
      }
    }
  } else if (source.IsDoubleStackSlot()) {
    if (destination.IsFpuRegister()) {
      __ ldc1(destination.fpu_reg(), source.ToStackSlotAddress());
    } else {
      ASSERT(destination.IsDoubleStackSlot());
      __ ldc1(FpuTMP, source.ToStackSlotAddress());
      __ sdc1(FpuTMP, destination.ToStackSlotAddress());
    }
  } else if (source.IsQuadStackSlot()) {
    UNIMPLEMENTED();
  } else {
    ASSERT(source.IsConstant());
    if (destination.IsRegister()) {
      const Object& constant = source.constant();
      __ LoadObject(destination.reg(), constant);
    } else {
      ASSERT(destination.IsStackSlot());
      StoreObject(destination.ToStackSlotAddress(), source.constant());
    }
  }

  move->Eliminate();
}


void ParallelMoveResolver::EmitSwap(int index) {
  MoveOperands* move = moves_[index];
  const Location source = move->src();
  const Location destination = move->dest();

  if (source.IsRegister() && destination.IsRegister()) {
    ASSERT(source.reg() != TMP1);
    ASSERT(destination.reg() != TMP1);
    __ mov(TMP1, source.reg());
    __ mov(source.reg(), destination.reg());
    __ mov(destination.reg(), TMP1);
  } else if (source.IsRegister() && destination.IsStackSlot()) {
    Exchange(source.reg(), destination.ToStackSlotAddress());
  } else if (source.IsStackSlot() && destination.IsRegister()) {
    Exchange(destination.reg(), source.ToStackSlotAddress());
  } else if (source.IsStackSlot() && destination.IsStackSlot()) {
    Exchange(destination.ToStackSlotAddress(), source.ToStackSlotAddress());
  } else if (source.IsFpuRegister() && destination.IsFpuRegister()) {
    __ movd(FpuTMP, source.fpu_reg());
    __ movd(source.fpu_reg(), destination.fpu_reg());
    __ movd(destination.fpu_reg(), FpuTMP);
  } else if (source.IsFpuRegister() || destination.IsFpuRegister()) {
    ASSERT(destination.IsDoubleStackSlot() ||
           destination.IsQuadStackSlot() ||
           source.IsDoubleStackSlot() ||
           source.IsQuadStackSlot());
    bool double_width = destination.IsDoubleStackSlot() ||
                        source.IsDoubleStackSlot();
    FRegister reg = source.IsFpuRegister() ? source.fpu_reg()
                                           : destination.fpu_reg();
    const Address& slot_address = source.IsFpuRegister()
        ? destination.ToStackSlotAddress()
        : source.ToStackSlotAddress();

    if (double_width) {
      __ ldc1(FpuTMP, slot_address);
      __ sdc1(reg, slot_address);
      __ movd(reg, FpuTMP);
    } else {
      UNIMPLEMENTED();
    }
  } else if (source.IsDoubleStackSlot() && destination.IsDoubleStackSlot()) {
    const Address& source_slot_address = source.ToStackSlotAddress();
    const Address& destination_slot_address = destination.ToStackSlotAddress();

    ScratchFpuRegisterScope ensure_scratch(this, FpuTMP);
    __ ldc1(FpuTMP, source_slot_address);
    __ ldc1(ensure_scratch.reg(), destination_slot_address);
    __ sdc1(FpuTMP, destination_slot_address);
    __ sdc1(ensure_scratch.reg(), source_slot_address);
  } else if (source.IsQuadStackSlot() && destination.IsQuadStackSlot()) {
    UNIMPLEMENTED();
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
  __ lw(TMP1, src);
  __ sw(TMP1, dst);
}


void ParallelMoveResolver::StoreObject(const Address& dst, const Object& obj) {
  __ LoadObject(TMP1, obj);
  __ sw(TMP1, dst);
}


void ParallelMoveResolver::Exchange(Register reg, const Address& mem) {
  ASSERT(reg != TMP1);
  __ mov(TMP1, reg);
  __ lw(reg, mem);
  __ sw(TMP1, mem);
}


void ParallelMoveResolver::Exchange(const Address& mem1, const Address& mem2) {
  ScratchRegisterScope ensure_scratch(this, TMP1);
  __ lw(ensure_scratch.reg(), mem1);
  __ lw(TMP1, mem2);
  __ sw(ensure_scratch.reg(), mem2);
  __ sw(TMP1, mem1);
}


void ParallelMoveResolver::SpillScratch(Register reg) {
  __ Push(reg);
}


void ParallelMoveResolver::RestoreScratch(Register reg) {
  __ Pop(reg);
}


void ParallelMoveResolver::SpillFpuScratch(FpuRegister reg) {
  __ AddImmediate(SP, -kDoubleSize);
  __ sdc1(reg, Address(SP));
}


void ParallelMoveResolver::RestoreFpuScratch(FpuRegister reg) {
  __ ldc1(reg, Address(SP));
  __ AddImmediate(SP, kDoubleSize);
}


#undef __


}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS

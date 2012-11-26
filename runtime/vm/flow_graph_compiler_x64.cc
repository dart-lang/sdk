// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/flow_graph_compiler.h"

#include "lib/error.h"
#include "vm/ast_printer.h"
#include "vm/il_printer.h"
#include "vm/locations.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

namespace dart {

DECLARE_FLAG(bool, print_ast);
DECLARE_FLAG(bool, print_scopes);
DECLARE_FLAG(bool, use_sse41);
DEFINE_FLAG(bool, trap_on_deoptimization, false, "Trap on deoptimization.");


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
  if (FLAG_trap_on_deoptimization) __ int3();

  ASSERT(deoptimization_env() != NULL);

  __ call(&StubCode::DeoptimizeLabel());
  set_pc_offset(assem->CodeSize());
  __ int3();
#undef __
}


#define __ assembler()->


// Fall through if bool_register contains null.
void FlowGraphCompiler::GenerateBoolToJump(Register bool_register,
                                           Label* is_true,
                                           Label* is_false) {
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label fall_through;
  __ cmpq(bool_register, raw_null);
  __ j(EQUAL, &fall_through, Assembler::kNearJump);
  __ CompareObject(bool_register, bool_true());
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
      SubtypeTestCache::ZoneHandle(SubtypeTestCache::New());
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ LoadObject(temp_reg, type_test_cache);
  __ pushq(temp_reg);  // Subtype test cache.
  __ pushq(instance_reg);  // Instance.
  if (test_kind == kTestTypeOneArg) {
    ASSERT(type_arguments_reg == kNoRegister);
    __ pushq(raw_null);
    __ call(&StubCode::Subtype1TestCacheLabel());
  } else if (test_kind == kTestTypeTwoArgs) {
    ASSERT(type_arguments_reg == kNoRegister);
    __ pushq(raw_null);
    __ call(&StubCode::Subtype2TestCacheLabel());
  } else if (test_kind == kTestTypeThreeArgs) {
    __ pushq(type_arguments_reg);
    __ call(&StubCode::Subtype3TestCacheLabel());
  } else {
    UNREACHABLE();
  }
  // Result is in RCX: null -> not found, otherwise Bool::True or Bool::False.
  ASSERT(instance_reg != RCX);
  ASSERT(temp_reg != RCX);
  __ popq(instance_reg);  // Discard.
  __ popq(instance_reg);  // Restore receiver.
  __ popq(temp_reg);  // Discard.
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
    intptr_t token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  ASSERT(type.IsInstantiated());
  const Class& type_class = Class::ZoneHandle(type.type_class());
  ASSERT(type_class.HasTypeArguments());
  const Register kInstanceReg = RAX;
  // A Smi object cannot be the instance of a parameterized class.
  __ testq(kInstanceReg, Immediate(kSmiTagMask));
  __ j(ZERO, is_not_instance_lbl);
  const AbstractTypeArguments& type_arguments =
      AbstractTypeArguments::ZoneHandle(type.arguments());
  const bool is_raw_type = type_arguments.IsNull() ||
      type_arguments.IsRaw(type_arguments.Length());
  if (is_raw_type) {
    const Register kClassIdReg = R10;
    // dynamic type argument, check only classes.
    // List is a very common case.
    __ LoadClassId(kClassIdReg, kInstanceReg);
    if (!type_class.is_interface()) {
      __ cmpl(kClassIdReg, Immediate(type_class.id()));
      __ j(EQUAL, is_instance_lbl);
    }
    if (type_class.IsListClass()) {
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
  // Regular subtype test cache involving instance's type arguments.
  const Register kTypeArgumentsReg = kNoRegister;
  const Register kTempReg = R10;
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
    intptr_t token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  ASSERT(type.IsInstantiated());
  const Class& type_class = Class::Handle(type.type_class());
  ASSERT(!type_class.HasTypeArguments());

  const Register kInstanceReg = RAX;
  Label compare_classes;
  __ testq(kInstanceReg, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &compare_classes, Assembler::kNearJump);
  // Instance is Smi, check directly.
  const Class& smi_class = Class::Handle(Smi::Class());
  if (smi_class.IsSubtypeOf(TypeArguments::Handle(),
                            type_class,
                            TypeArguments::Handle(),
                            NULL)) {
    __ jmp(is_instance_lbl);
  } else {
    __ jmp(is_not_instance_lbl);
  }
  // Compare if the classes are equal.
  __ Bind(&compare_classes);
  const Register kClassIdReg = R10;
  __ LoadClassId(kClassIdReg, kInstanceReg);
  // If type is an interface, we can skip the class equality check.
  if (!type_class.is_interface()) {
    __ cmpl(kClassIdReg, Immediate(type_class.id()));
    __ j(EQUAL, is_instance_lbl);
  }
  // Bool interface can be implemented only by core class Bool.
  // (see ClassFinalizer::ResolveInterfaces for list of restricted interfaces).
  if (type.IsBoolType()) {
    __ cmpl(kClassIdReg, Immediate(kBoolCid));
    __ j(EQUAL, is_instance_lbl);
    __ jmp(is_not_instance_lbl);
    return false;
  }
  if (type.IsFunctionType()) {
    // Check if instance is a closure.
    const Immediate raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ LoadClassById(R13, kClassIdReg);
    __ movq(R13, FieldAddress(R13, Class::signature_function_offset()));
    __ cmpq(R13, raw_null);
    __ j(NOT_EQUAL, is_instance_lbl);
    __ jmp(is_not_instance_lbl);
    return false;
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
// RAX: instance to test.
// Clobbers R10, R13.
// Immediate class test already done.
// TODO(srdjan): Implement a quicker subtype check, as type test
// arrays can grow too high, but they may be useful when optimizing
// code (type-feedback).
RawSubtypeTestCache* FlowGraphCompiler::GenerateSubtype1TestCacheLookup(
    intptr_t token_pos,
    const Class& type_class,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  const Register kInstanceReg = RAX;
  __ LoadClass(R10, kInstanceReg);
  // R10: instance class.
  // Check immediate superclass equality.
  __ movq(R13, FieldAddress(R10, Class::super_type_offset()));
  __ movq(R13, FieldAddress(R13, Type::type_class_offset()));
  __ CompareObject(R13, type_class);
  __ j(EQUAL, is_instance_lbl);

  const Register kTypeArgumentsReg = kNoRegister;
  const Register kTempReg = R10;
  return GenerateCallSubtypeTestStub(kTestTypeOneArg,
                                     kInstanceReg,
                                     kTypeArgumentsReg,
                                     kTempReg,
                                     is_instance_lbl,
                                     is_not_instance_lbl);
}


// Generates inlined check if 'type' is a type parameter or type itsef
// RAX: instance (preserved).
// Clobbers RDI, RDX, R10.
RawSubtypeTestCache* FlowGraphCompiler::GenerateUninstantiatedTypeTest(
    intptr_t token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  ASSERT(!type.IsInstantiated());
  // Skip check if destination is a dynamic type.
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  if (type.IsTypeParameter()) {
    const TypeParameter& type_param = TypeParameter::Cast(type);
    // Load instantiator (or null) and instantiator type arguments on stack.
    __ movq(RDX, Address(RSP, 0));  // Get instantiator type arguments.
    // RDX: instantiator type arguments.
    // Check if type argument is dynamic.
    __ cmpq(RDX, raw_null);
    __ j(EQUAL, is_instance_lbl);
    // Can handle only type arguments that are instances of TypeArguments.
    // (runtime checks canonicalize type arguments).
    Label fall_through;
    __ CompareClassId(RDX, kTypeArgumentsCid);
    __ j(NOT_EQUAL, &fall_through);
    __ movq(RDI,
        FieldAddress(RDX, TypeArguments::type_at_offset(type_param.index())));
    // RDI: Concrete type of type.
    // Check if type argument is dynamic.
    __ CompareObject(RDI, Type::ZoneHandle(Type::DynamicType()));
    __ j(EQUAL,  is_instance_lbl);
    __ cmpq(RDI, raw_null);
    __ j(EQUAL,  is_instance_lbl);
    const Type& object_type = Type::ZoneHandle(Type::ObjectType());
    __ CompareObject(RDI, object_type);
    __ j(EQUAL,  is_instance_lbl);

    // For Smi check quickly against int and num interfaces.
    Label not_smi;
    __ testq(RAX, Immediate(kSmiTagMask));  // Value is Smi?
    __ j(NOT_ZERO, &not_smi, Assembler::kNearJump);
    __ CompareObject(RDI, Type::ZoneHandle(Type::IntType()));
    __ j(EQUAL,  is_instance_lbl);
    __ CompareObject(RDI, Type::ZoneHandle(Type::Number()));
    __ j(EQUAL,  is_instance_lbl);
    // Smi must be handled in runtime.
    __ jmp(&fall_through);

    __ Bind(&not_smi);
    // RDX: instantiator type arguments.
    // RAX: instance.
    const Register kInstanceReg = RAX;
    const Register kTypeArgumentsReg = RDX;
    const Register kTempReg = R10;
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
    const Register kInstanceReg = RAX;
    const Register kTypeArgumentsReg = RDX;
    __ testq(kInstanceReg, Immediate(kSmiTagMask));  // Is instance Smi?
    __ j(ZERO, is_not_instance_lbl);
    __ movq(kTypeArgumentsReg, Address(RSP, 0));  // Instantiator type args.
    // Uninstantiated type class is known at compile time, but the type
    // arguments are determined at runtime by the instantiator.
    const Register kTempReg = R10;
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
// - RAX: instance to test against (preserved).
// - RDX: optional instantiator type arguments (preserved).
// Clobbers R10, R13.
// Returns:
// - preserved instance in RAX and optional instantiator type arguments in RDX.
// Note that this inlined code must be followed by the runtime_call code, as it
// may fall through to it. Otherwise, this inline code will jump to the label
// is_instance or to the label is_not_instance.
RawSubtypeTestCache* FlowGraphCompiler::GenerateInlineInstanceof(
    intptr_t token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  if (type.IsVoidType()) {
    // A non-null value is returned from a void function, which will result in a
    // type error. A null value is handled prior to executing this inline code.
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


// If instanceof type test cannot be performed successfully at compile time and
// therefore eliminated, optimize it by adding inlined tests for:
// - NULL -> return false.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs:
// - RAX: object.
// - RDX: instantiator type arguments or raw_null.
// - RCX: instantiator or raw_null.
// Clobbers RCX and RDX.
// Returns:
// - true or false in RAX.
void FlowGraphCompiler::GenerateInstanceOf(intptr_t token_pos,
                                           const AbstractType& type,
                                           bool negate_result,
                                           LocationSummary* locs) {
  ASSERT(type.IsFinalized() && !type.IsMalformed());

  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label is_instance, is_not_instance;
  __ pushq(RCX);  // Store instantiator on stack.
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
    __ cmpq(RAX, raw_null);
    __ j(EQUAL, &is_not_instance);
  }

  // Generate inline instanceof test.
  SubtypeTestCache& test_cache = SubtypeTestCache::ZoneHandle();
  test_cache = GenerateInlineInstanceof(token_pos, type,
                                        &is_instance, &is_not_instance);

  // test_cache is null if there is no fall-through.
  Label done;
  if (!test_cache.IsNull()) {
    // Generate runtime call.
    __ movq(RDX, Address(RSP, 0));  // Get instantiator type arguments.
    __ movq(RCX, Address(RSP, kWordSize));  // Get instantiator.
    __ PushObject(Object::ZoneHandle());  // Make room for the result.
    __ pushq(RAX);  // Push the instance.
    __ PushObject(type);  // Push the type.
    __ pushq(RCX);  // TODO(srdjan): Pass instantiator instead of null.
    __ pushq(RDX);  // Instantiator type arguments.
    __ LoadObject(RAX, test_cache);
    __ pushq(RAX);
    GenerateCallRuntime(token_pos, kInstanceofRuntimeEntry, locs);
    // Pop the parameters supplied to the runtime entry. The result of the
    // instanceof runtime call will be left as the result of the operation.
    __ Drop(5);
    if (negate_result) {
      __ popq(RDX);
      __ LoadObject(RAX, bool_true());
      __ cmpq(RDX, RAX);
      __ j(NOT_EQUAL, &done, Assembler::kNearJump);
      __ LoadObject(RAX, bool_false());
    } else {
      __ popq(RAX);
    }
    __ jmp(&done, Assembler::kNearJump);
  }
  __ Bind(&is_not_instance);
  __ LoadObject(RAX, negate_result ? bool_true() : bool_false());
  __ jmp(&done, Assembler::kNearJump);

  __ Bind(&is_instance);
  __ LoadObject(RAX, negate_result ? bool_false() : bool_true());
  __ Bind(&done);
  __ popq(RDX);  // Remove pushed instantiator type arguments.
  __ popq(RCX);  // Remove pushed instantiator.
}


// Optimize assignable type check by adding inlined tests for:
// - NULL -> return NULL.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs:
// - RAX: object.
// - RDX: instantiator type arguments or raw_null.
// - RCX: instantiator or raw_null.
// Returns:
// - object in RAX for successful assignable check (or throws TypeError).
// Performance notes: positive checks must be quick, negative checks can be slow
// as they throw an exception.
void FlowGraphCompiler::GenerateAssertAssignable(intptr_t token_pos,
                                                 const AbstractType& dst_type,
                                                 const String& dst_name,
                                                 LocationSummary* locs) {
  ASSERT(token_pos >= 0);
  ASSERT(!dst_type.IsNull());
  ASSERT(dst_type.IsFinalized());
  // Assignable check is skipped in FlowGraphBuilder, not here.
  ASSERT(dst_type.IsMalformed() ||
         (!dst_type.IsDynamicType() && !dst_type.IsObjectType()));
  __ pushq(RCX);  // Store instantiator.
  __ pushq(RDX);  // Store instantiator type arguments.
  // A null object is always assignable and is returned as result.
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label is_assignable, runtime_call;
  __ cmpq(RAX, raw_null);
  __ j(EQUAL, &is_assignable);

  // Generate throw new TypeError() if the type is malformed.
  if (dst_type.IsMalformed()) {
    const Error& error = Error::Handle(dst_type.malformed_error());
    const String& error_message = String::ZoneHandle(
        Symbols::New(error.ToErrorCString()));
    __ PushObject(Object::ZoneHandle());  // Make room for the result.
    __ pushq(RAX);  // Push the source object.
    __ PushObject(dst_name);  // Push the name of the destination.
    __ PushObject(error_message);
    GenerateCallRuntime(token_pos,
                        kMalformedTypeErrorRuntimeEntry,
                        locs);
    // We should never return here.
    __ int3();

    __ Bind(&is_assignable);  // For a null object.
    __ popq(RDX);  // Remove pushed instantiator type arguments.
    __ popq(RCX);  // Remove pushed instantiator.
    return;
  }

  // Generate inline type check, linking to runtime call if not assignable.
  SubtypeTestCache& test_cache = SubtypeTestCache::ZoneHandle();
  test_cache = GenerateInlineInstanceof(token_pos, dst_type,
                                        &is_assignable, &runtime_call);

  __ Bind(&runtime_call);
  __ movq(RDX, Address(RSP, 0));  // Get instantiator type arguments.
  __ movq(RCX, Address(RSP, kWordSize));  // Get instantiator.
  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  __ pushq(RAX);  // Push the source object.
  __ PushObject(dst_type);  // Push the type of the destination.
  __ pushq(RCX);  // Instantiator.
  __ pushq(RDX);  // Instantiator type arguments.
  __ PushObject(dst_name);  // Push the name of the destination.
  __ LoadObject(RAX, test_cache);
  __ pushq(RAX);
  GenerateCallRuntime(token_pos, kTypeCheckRuntimeEntry, locs);
  // Pop the parameters supplied to the runtime entry. The result of the
  // type check runtime call is the checked value.
  __ Drop(6);
  __ popq(RAX);

  __ Bind(&is_assignable);
  __ popq(RDX);  // Remove pushed instantiator type arguments.
  __ popq(RCX);  // Remove pushed instantiator.
}


void FlowGraphCompiler::EmitInstructionPrologue(Instruction* instr) {
  if (!is_optimizing()) {
    AllocateRegistersLocally(instr);
  }
}


void FlowGraphCompiler::EmitInstructionEpilogue(Instruction* instr) {
  if (is_optimizing()) return;
  Definition* defn = instr->AsDefinition();
  if ((defn != NULL) && defn->is_used()) {
    __ pushq(defn->locs()->out().reg());
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
  ASSERT(parsed_function().first_parameter_index() ==
         ParsedFunction::kFirstLocalSlotIndex);

  // Check that min_num_pos_args <= num_pos_args <= max_num_pos_args,
  // where num_pos_args is the number of positional arguments passed in.
  const int min_num_pos_args = num_fixed_params;
  const int max_num_pos_args = num_fixed_params + num_opt_pos_params;

  // Number of positional args is the second Smi in descriptor array (R10).
  __ movq(RCX, FieldAddress(R10, Array::data_offset() + (1 * kWordSize)));
  // Check that min_num_pos_args <= num_pos_args.
  Label wrong_num_arguments;
  __ cmpq(RCX, Immediate(Smi::RawValue(min_num_pos_args)));
  __ j(LESS, &wrong_num_arguments);
  // Check that num_pos_args <= max_num_pos_args.
  __ cmpq(RCX, Immediate(Smi::RawValue(max_num_pos_args)));
  __ j(GREATER, &wrong_num_arguments);

  // Copy positional arguments.
  // Argument i passed at fp[1 + num_args - i] is copied
  // to fp[ParsedFunction::kFirstLocalSlotIndex - i].

  // Total number of args is the first Smi in args descriptor array (R10).
  __ movq(RBX, FieldAddress(R10, Array::data_offset()));
  // Since RBX and RCX are Smi, use TIMES_4 instead of TIMES_8.
  // Let RBX point to the last passed positional argument, i.e. to
  // fp[1 + num_args - (num_pos_args - 1)].
  __ subq(RBX, RCX);
  __ leaq(RBX, Address(RBP, RBX, TIMES_4, 2 * kWordSize));

  // Let RDI point to the last copied positional argument, i.e. to
  // fp[ParsedFunction::kFirstLocalSlotIndex - (num_pos_args - 1)].
  const int index = ParsedFunction::kFirstLocalSlotIndex + 1;
  __ SmiUntag(RCX);
  __ movq(RAX, RCX);
  __ negq(RAX);
  // -num_pos_args is in RAX.
  // (ParsedFunction::kFirstLocalSlotIndex + 1) is in index.
  __ leaq(RDI, Address(RBP, RAX, TIMES_8, (index * kWordSize)));
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
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
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
    // Total number of args is the first Smi in args descriptor array (R10).
    __ movq(RBX, FieldAddress(R10, Array::data_offset()));
    // Number of positional args is the second Smi in descriptor array (R10).
    __ movq(RCX, FieldAddress(R10, Array::data_offset() + (1 * kWordSize)));
    __ SmiUntag(RCX);
    // Let RBX point to the first passed argument, i.e. to fp[1 + argc - 0].
    __ leaq(RBX, Address(RBP, RBX, TIMES_4, kWordSize));  // RBX is Smi.
    // Let EDI point to the name/pos pair of the first named argument.
    __ leaq(RDI, FieldAddress(R10, Array::data_offset() + (2 * kWordSize)));
    for (int i = 0; i < num_opt_named_params; i++) {
      Label load_default_value, assign_optional_parameter, next_parameter;
      const int param_pos = opt_param_position[i];
      // Check if this named parameter was passed in.
      __ movq(RAX, Address(RDI, 0));  // Load RAX with the name of the argument.
      ASSERT(opt_param[i]->name().IsSymbol());
      __ CompareObject(RAX, opt_param[i]->name());
      __ j(NOT_EQUAL, &load_default_value, Assembler::kNearJump);
      // Load RAX with passed-in argument at provided arg_pos, i.e. at
      // fp[1 + argc - arg_pos].
      __ movq(RAX, Address(RDI, kWordSize));  // RAX is arg_pos as Smi.
      __ addq(RDI, Immediate(2 * kWordSize));  // Point to next name/pos pair.
      __ negq(RAX);
      Address argument_addr(RBX, RAX, TIMES_4, 0);  // RAX is a negative Smi.
      __ movq(RAX, argument_addr);
      __ jmp(&assign_optional_parameter, Assembler::kNearJump);
      __ Bind(&load_default_value);
      // Load RAX with default argument.
      const Object& value = Object::ZoneHandle(
          parsed_function().default_parameter_values().At(
              param_pos - num_fixed_params));
      __ LoadObject(RAX, value);
      __ Bind(&assign_optional_parameter);
      // Assign RAX to fp[ParsedFunction::kFirstLocalSlotIndex - param_pos].
      // We do not use the final allocation index of the variable here, i.e.
      // scope->VariableAt(i)->index(), because captured variables still need
      // to be copied to the context that is not yet allocated.
      const intptr_t computed_param_pos =
          ParsedFunction::kFirstLocalSlotIndex - param_pos;
      const Address param_addr(RBP, (computed_param_pos * kWordSize));
      __ movq(param_addr, RAX);
      __ Bind(&next_parameter);
    }
    delete[] opt_param;
    delete[] opt_param_position;
    // Check that RDI now points to the null terminator in the array descriptor.
    __ cmpq(Address(RDI, 0), raw_null);
    __ j(EQUAL, &all_arguments_processed, Assembler::kNearJump);
  } else {
    ASSERT(num_opt_pos_params > 0);
    // Number of positional args is the second Smi in descriptor array (R10).
    __ movq(RCX, FieldAddress(R10, Array::data_offset() + (1 * kWordSize)));
    __ SmiUntag(RCX);
    for (int i = 0; i < num_opt_pos_params; i++) {
      Label next_parameter;
      // Handle this optional positonal parameter only if k or fewer positional
      // arguments have been passed, where k is param_pos, the position of this
      // optional parameter in the formal parameter list.
      const int param_pos = num_fixed_params + i;
      __ cmpq(RCX, Immediate(param_pos));
      __ j(GREATER, &next_parameter, Assembler::kNearJump);
      // Load RAX with default argument.
      const Object& value = Object::ZoneHandle(
          parsed_function().default_parameter_values().At(i));
      __ LoadObject(RAX, value);
      // Assign RAX to fp[ParsedFunction::kFirstLocalSlotIndex - param_pos].
      // We do not use the final allocation index of the variable here, i.e.
      // scope->VariableAt(i)->index(), because captured variables still need
      // to be copied to the context that is not yet allocated.
      const intptr_t computed_param_pos =
          ParsedFunction::kFirstLocalSlotIndex - param_pos;
      const Address param_addr(RBP, (computed_param_pos * kWordSize));
      __ movq(param_addr, RAX);
      __ Bind(&next_parameter);
    }
    // Total number of args is the first Smi in args descriptor array (R10).
    __ movq(RBX, FieldAddress(R10, Array::data_offset()));
    __ SmiUntag(RBX);
    // Check that RCX equals RBX, i.e. no named arguments passed.
    __ cmpq(RCX, RBX);
    __ j(EQUAL, &all_arguments_processed, Assembler::kNearJump);
  }

  __ Bind(&wrong_num_arguments);
  if (StackSize() != 0) {
    // We need to unwind the space we reserved for locals and copied parameters.
    // The NoSuchMethodFunction stub does not expect to see that area on the
    // stack.
    __ addq(RSP, Immediate(StackSize() * kWordSize));
  }
  // The calls immediately below have empty stackmaps because we have just
  // dropped the spill slots.
  BitmapBuilder* empty_stack_bitmap = new BitmapBuilder();
  if (function.IsClosureFunction()) {
    // TODO(regis): Call NoSuchMethod with "call" as name of original function.
    // We do not use GenerateCallRuntime because of the non-standard (empty)
    // stackmap used here.
    __ CallRuntime(kClosureArgumentMismatchRuntimeEntry);
    AddCurrentDescriptor(PcDescriptors::kOther,
                         Isolate::kNoDeoptId,
                         0);  // No token position.
  } else {
    // Invoke noSuchMethod function.
    const int kNumArgsChecked = 1;
    ICData& ic_data = ICData::ZoneHandle();
    ic_data = ICData::New(function,
                          String::Handle(function.name()),
                          Isolate::kNoDeoptId,
                          kNumArgsChecked);
    __ LoadObject(RBX, ic_data);
    // RBP - 8 : PC marker, allows easy identification of RawInstruction obj.
    // RBP : points to previous frame pointer.
    // RBP + 8 : points to return address.
    // RBP + 16 : address of last argument (arg n-1).
    // RSP + 16 + 8*(n-1) : address of first argument (arg 0).
    // RBX : ic-data.
    // R10 : arguments descriptor array.
    __ call(&StubCode::CallNoSuchMethodFunctionLabel());
  }
  if (is_optimizing()) {
    stackmap_table_builder_->AddEntry(assembler()->CodeSize(),
                                      empty_stack_bitmap,
                                      0);  // No registers.
  }

  __ LeaveFrame();
  __ ret();

  __ Bind(&all_arguments_processed);
  // Nullify originally passed arguments only after they have been copied and
  // checked, otherwise noSuchMethod would not see their original values.
  // This step can be skipped in case we decide that formal parameters are
  // implicitly final, since garbage collecting the unmodified value is not
  // an issue anymore.

  // R10 : arguments descriptor array.
  // Total number of args is the first Smi in args descriptor array (R10).
  __ movq(RCX, FieldAddress(R10, Array::data_offset()));
  __ SmiUntag(RCX);
  Label null_args_loop, null_args_loop_condition;
  __ jmp(&null_args_loop_condition, Assembler::kNearJump);
  const Address original_argument_addr(RBP, RCX, TIMES_8, 2 * kWordSize);
  __ Bind(&null_args_loop);
  __ movq(original_argument_addr, raw_null);
  __ Bind(&null_args_loop_condition);
  __ decq(RCX);
  __ j(POSITIVE, &null_args_loop, Assembler::kNearJump);
}


void FlowGraphCompiler::GenerateInlinedGetter(intptr_t offset) {
  // TOS: return address.
  // +1 : receiver.
  // Sequence node has one return node, its input is load field node.
  __ movq(RAX, Address(RSP, 1 * kWordSize));
  __ movq(RAX, FieldAddress(RAX, offset));
  __ ret();
}


void FlowGraphCompiler::GenerateInlinedSetter(intptr_t offset) {
  // TOS: return address.
  // +1 : value
  // +2 : receiver.
  // Sequence node has one store node and one return NULL node.
  __ movq(RAX, Address(RSP, 2 * kWordSize));  // Receiver.
  __ movq(RBX, Address(RSP, 1 * kWordSize));  // Value.
  __ StoreIntoObject(RAX, FieldAddress(RAX, offset), RBX);
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movq(RAX, raw_null);
  __ ret();
}


void FlowGraphCompiler::CompileGraph() {
  InitCompiler();
  if (TryIntrinsify()) {
    // Although this intrinsified code will never be patched, it must satisfy
    // CodePatcher::CodeIsPatchable, which verifies that this code has a minimum
    // code size, and nop(2) increases the minimum code size appropriately.
    __ nop(2);
    __ int3();
    __ jmp(&StubCode::FixCallersTargetLabel());
    return;
  }
  // Specialized version of entry code from CodeGenerator::GenerateEntryCode.
  const Function& function = parsed_function().function();

  const int num_fixed_params = function.num_fixed_parameters();
  const int num_copied_params = parsed_function().num_copied_params();
  const int num_locals = parsed_function().num_stack_locals();
  __ Comment("Enter frame");
  AssemblerMacros::EnterDartFrame(assembler(), (StackSize() * kWordSize));

  // For optimized code, keep a bitmap of the frame in order to build
  // stackmaps for GC safepoints in the prologue.
  LocationSummary* prologue_locs = NULL;
  if (is_optimizing()) {
    // Spill slots are allocated but not initialized.
    prologue_locs = new LocationSummary(0, 0, LocationSummary::kCall);
    prologue_locs->stack_bitmap()->SetLength(StackSize());
  }

  // We check the number of passed arguments when we have to copy them due to
  // the presence of optional parameters.
  // No such checking code is generated if only fixed parameters are declared,
  // unless we are debug mode or unless we are compiling a closure.
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
      // Check that num_fixed <= argc <= num_params.
      Label argc_in_range;
      // Total number of args is the first Smi in args descriptor array (R10).
      __ movq(RAX, FieldAddress(R10, Array::data_offset()));
      __ cmpq(RAX, Immediate(Smi::RawValue(num_fixed_params)));
      __ j(EQUAL, &argc_in_range, Assembler::kNearJump);
      if (function.IsClosureFunction()) {
        // TODO(regis): Call NoSuchMethod with "call" as name of original
        // function.
        GenerateCallRuntime(function.token_pos(),
                            kClosureArgumentMismatchRuntimeEntry,
                            prologue_locs);
      } else {
        __ Stop("Wrong number of arguments");
      }
      __ Bind(&argc_in_range);
    }
    // The arguments descriptor is never saved in the absence of optional
    // parameters, since any argument definition test would always yield true.
    ASSERT(saved_args_desc_var == NULL);
  } else {
    if (saved_args_desc_var != NULL) {
      __ Comment("Save arguments descriptor");
      const Register kArgumentsDescriptorReg = R10;
      // The saved_args_desc_var is allocated one slot before the first local.
      const intptr_t slot = parsed_function().first_stack_local_index() + 1;
      // If the saved_args_desc_var is captured, it is first moved to the stack
      // and later to the context, once the context is allocated.
      ASSERT(saved_args_desc_var->is_captured() ||
             (saved_args_desc_var->index() == slot));
      __ movq(Address(RBP, slot * kWordSize), kArgumentsDescriptorReg);
    }
    CopyParameters();
  }

  // In unoptimized code, initialize (non-argument) stack allocated slots to
  // null. This does not cover the saved_args_desc_var slot.
  if (!is_optimizing() && (num_locals > 0)) {
    __ Comment("Initialize spill slots");
    const intptr_t slot_base = parsed_function().first_stack_local_index();
    const Immediate raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ movq(RAX, raw_null);
    for (intptr_t i = 0; i < num_locals; ++i) {
      // Subtract index i (locals lie at lower addresses than RBP).
      __ movq(Address(RBP, (slot_base - i) * kWordSize), RAX);
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

  ASSERT(!block_order().is_empty());
  VisitBlocks();

  __ int3();
  GenerateDeferredCode();
  // Emit function patching code. This will be swapped with the first 13 bytes
  // at entry point.
  AddCurrentDescriptor(PcDescriptors::kPatchCode,
                       Isolate::kNoDeoptId,
                       0);  // No token position.
  __ jmp(&StubCode::FixCallersTargetLabel());
  AddCurrentDescriptor(PcDescriptors::kLazyDeoptJump,
                       Isolate::kNoDeoptId,
                       0);  // No token position.
  __ jmp(&StubCode::DeoptimizeLazyLabel());
}


void FlowGraphCompiler::GenerateCall(intptr_t token_pos,
                                     const ExternalLabel* label,
                                     PcDescriptors::Kind kind,
                                     LocationSummary* locs) {
  __ call(label);
  AddCurrentDescriptor(kind, Isolate::kNoDeoptId, token_pos);
  RecordSafepoint(locs);
}


void FlowGraphCompiler::GenerateDartCall(intptr_t deopt_id,
                                         intptr_t token_pos,
                                         const ExternalLabel* label,
                                         PcDescriptors::Kind kind,
                                         LocationSummary* locs) {
  __ call(label);
  AddCurrentDescriptor(kind, deopt_id, token_pos);
  RecordSafepoint(locs);
  // Marks either the continuation point in unoptimized code or the
  // deoptimization point in optimized code, after call.
  if (is_optimizing()) {
    AddDeoptIndexAtCall(deopt_id, token_pos);
  } else {
    // Add deoptimization continuation point after the call and before the
    // arguments are removed.
    AddCurrentDescriptor(PcDescriptors::kDeoptAfter,
                         deopt_id,
                         token_pos);
  }
}


void FlowGraphCompiler::GenerateCallRuntime(intptr_t token_pos,
                                            const RuntimeEntry& entry,
                                            LocationSummary* locs) {
  __ CallRuntime(entry);
  AddCurrentDescriptor(PcDescriptors::kOther, Isolate::kNoDeoptId, token_pos);
  RecordSafepoint(locs);
}


void FlowGraphCompiler::EmitOptimizedInstanceCall(
    ExternalLabel* target_label,
    const ICData& ic_data,
    const Array& arguments_descriptor,
    intptr_t argument_count,
    intptr_t deopt_id,
    intptr_t token_pos,
    LocationSummary* locs) {
  // Each ICData propagated from unoptimized to optimized code contains the
  // function that corresponds to the Dart function of that IC call. Due
  // to inlining in optimized code, that function may not correspond to the
  // top-level function (parsed_function().function()) which could be
  // reoptimized and which counter needs to be incremented.
  // Pass the function explicitly.
  __ LoadObject(RDI, parsed_function().function());
  __ LoadObject(RBX, ic_data);
  __ LoadObject(R10, arguments_descriptor);
  GenerateDartCall(deopt_id,
                   token_pos,
                   target_label,
                   PcDescriptors::kIcCall,
                   locs);
  __ Drop(argument_count);
}


void FlowGraphCompiler::EmitInstanceCall(ExternalLabel* target_label,
                                         const ICData& ic_data,
                                         const Array& arguments_descriptor,
                                         intptr_t argument_count,
                                         intptr_t deopt_id,
                                         intptr_t token_pos,
                                         LocationSummary* locs) {
  __ LoadObject(RBX, ic_data);
  __ LoadObject(R10, arguments_descriptor);
  GenerateDartCall(deopt_id,
                   token_pos,
                   target_label,
                   PcDescriptors::kIcCall,
                   locs);
  __ Drop(argument_count);
}


void FlowGraphCompiler::EmitStaticCall(const Function& function,
                                       const Array& arguments_descriptor,
                                       intptr_t argument_count,
                                       intptr_t deopt_id,
                                       intptr_t token_pos,
                                       LocationSummary* locs) {
  __ LoadObject(R10, arguments_descriptor);
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
  if (needs_number_check) {
    if (!obj.IsMint() && !obj.IsDouble() && !obj.IsBigint()) {
      needs_number_check = false;
    }
  }

  if (obj.IsSmi() && (Smi::Cast(obj).Value() == 0)) {
    ASSERT(!needs_number_check);
    __ testq(reg, reg);
    return;
  }

  if (needs_number_check) {
    __ pushq(reg);
    __ PushObject(obj);
    __ call(&StubCode::IdenticalWithNumberCheckLabel());
    __ popq(reg);  // Discard constant.
    __ popq(reg);  // Restore 'reg'.
    return;
  }

  __ CompareObject(reg, obj);
}


void FlowGraphCompiler::EmitEqualityRegRegCompare(Register left,
                                                  Register right,
                                                  bool needs_number_check) {
  if (needs_number_check) {
    __ pushq(left);
    __ pushq(right);
    __ call(&StubCode::IdenticalWithNumberCheckLabel());
    // Stub returns result in flags (result of a cmpl, we need ZF computed).
    __ popq(right);
    __ popq(left);
  } else {
    __ cmpl(left, right);
  }
}


// Implement equality spec: if any of the arguments is null do identity check.
// Fallthrough calls super equality.
void FlowGraphCompiler::EmitSuperEqualityCallPrologue(Register result,
                                                      Label* skip_call) {
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label check_identity, fall_through;
  __ cmpq(Address(RSP, 0 * kWordSize), raw_null);
  __ j(EQUAL, &check_identity, Assembler::kNearJump);
  __ cmpq(Address(RSP, 1 * kWordSize), raw_null);
  __ j(NOT_EQUAL, &fall_through, Assembler::kNearJump);

  __ Bind(&check_identity);
  __ popq(result);
  __ cmpq(result, Address(RSP, 0 * kWordSize));
  Label is_false;
  __ j(NOT_EQUAL, &is_false, Assembler::kNearJump);
  __ LoadObject(result, bool_true());
  __ Drop(1);
  __ jmp(skip_call);
  __ Bind(&is_false);
  __ LoadObject(result, bool_false());
  __ Drop(1);
  __ jmp(skip_call);
  __ Bind(&fall_through);
}


void FlowGraphCompiler::LoadDoubleOrSmiToXmm(XmmRegister result,
                                             Register reg,
                                             Register temp,
                                             Label* not_double_or_smi) {
  Label is_smi, done;
  __ testq(reg, Immediate(kSmiTagMask));
  __ j(ZERO, &is_smi);
  __ CompareClassId(reg, kDoubleCid);
  __ j(NOT_EQUAL, not_double_or_smi);
  __ movsd(result, FieldAddress(reg, Double::value_offset()));
  __ jmp(&done);
  __ Bind(&is_smi);
  __ movq(temp, reg);
  __ SmiUntag(temp);
  __ cvtsi2sd(result, temp);
  __ Bind(&done);
}


void FlowGraphCompiler::SaveLiveRegisters(LocationSummary* locs) {
  // TODO(vegorov): consider saving only caller save (volatile) registers.
  const intptr_t xmm_regs_count = locs->live_registers()->xmm_regs_count();
  if (xmm_regs_count > 0) {
    __ subq(RSP, Immediate(xmm_regs_count * kDoubleSize));
    // Store XMM registers with the lowest register number at the lowest
    // address.
    intptr_t offset = 0;
    for (intptr_t reg_idx = 0; reg_idx < kNumberOfXmmRegisters; ++reg_idx) {
      XmmRegister xmm_reg = static_cast<XmmRegister>(reg_idx);
      if (locs->live_registers()->ContainsXmmRegister(xmm_reg)) {
        __ movsd(Address(RSP, offset), xmm_reg);
        offset += kDoubleSize;
      }
    }
    ASSERT(offset == (xmm_regs_count * kDoubleSize));
  }

  // Store general purpose registers with the highest register number at the
  // lowest address.
  for (intptr_t reg_idx = 0; reg_idx < kNumberOfCpuRegisters; ++reg_idx) {
    Register reg = static_cast<Register>(reg_idx);
    if (locs->live_registers()->ContainsRegister(reg)) {
      __ pushq(reg);
    }
  }
}


void FlowGraphCompiler::RestoreLiveRegisters(LocationSummary* locs) {
  // General purpose registers have the highest register number at the
  // lowest address.
  for (intptr_t reg_idx = kNumberOfCpuRegisters - 1; reg_idx >= 0; --reg_idx) {
    Register reg = static_cast<Register>(reg_idx);
    if (locs->live_registers()->ContainsRegister(reg)) {
      __ popq(reg);
    }
  }

  const intptr_t xmm_regs_count = locs->live_registers()->xmm_regs_count();
  if (xmm_regs_count > 0) {
    // XMM registers have the lowest register number at the lowest address.
    intptr_t offset = 0;
    for (intptr_t reg_idx = 0; reg_idx < kNumberOfXmmRegisters; ++reg_idx) {
      XmmRegister xmm_reg = static_cast<XmmRegister>(reg_idx);
      if (locs->live_registers()->ContainsXmmRegister(xmm_reg)) {
        __ movsd(xmm_reg, Address(RSP, offset));
        offset += kDoubleSize;
      }
    }
    ASSERT(offset == (xmm_regs_count * kDoubleSize));
    __ addq(RSP, Immediate(offset));
  }
}


#undef __
#define __ compiler_->assembler()->


static Address ToStackSlotAddress(Location loc) {
  const intptr_t index = loc.stack_index();
  if (index < 0) {
    const intptr_t offset = (1 - index)  * kWordSize;
    return Address(RBP, offset);
  } else {
    const intptr_t offset =
        (ParsedFunction::kFirstLocalSlotIndex - index) * kWordSize;
    return Address(RBP, offset);
  }
}


void ParallelMoveResolver::EmitMove(int index) {
  MoveOperands* move = moves_[index];
  const Location source = move->src();
  const Location destination = move->dest();

  if (source.IsRegister()) {
    if (destination.IsRegister()) {
      __ movq(destination.reg(), source.reg());
    } else {
      ASSERT(destination.IsStackSlot());
      __ movq(ToStackSlotAddress(destination), source.reg());
    }
  } else if (source.IsStackSlot()) {
    if (destination.IsRegister()) {
      __ movq(destination.reg(), ToStackSlotAddress(source));
    } else {
      ASSERT(destination.IsStackSlot());
      MoveMemoryToMemory(ToStackSlotAddress(destination),
                         ToStackSlotAddress(source));
    }
  } else if (source.IsXmmRegister()) {
    if (destination.IsXmmRegister()) {
      // Optimization manual recommends using MOVAPS for register
      // to register moves.
      __ movaps(destination.xmm_reg(), source.xmm_reg());
    } else {
      ASSERT(destination.IsDoubleStackSlot());
      __ movsd(ToStackSlotAddress(destination), source.xmm_reg());
    }
  } else if (source.IsDoubleStackSlot()) {
    if (destination.IsXmmRegister()) {
      __ movsd(destination.xmm_reg(), ToStackSlotAddress(source));
    } else {
      ASSERT(destination.IsDoubleStackSlot());
      __ movsd(XMM0, ToStackSlotAddress(source));
      __ movsd(ToStackSlotAddress(destination), XMM0);
    }
  } else {
    ASSERT(source.IsConstant());
    if (destination.IsRegister()) {
      const Object& constant = source.constant();
      if (constant.IsSmi() && (Smi::Cast(constant).Value() == 0)) {
        __ xorq(destination.reg(), destination.reg());
      } else {
        __ LoadObject(destination.reg(), constant);
      }
    } else {
      ASSERT(destination.IsStackSlot());
      StoreObject(ToStackSlotAddress(destination), source.constant());
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
    Exchange(source.reg(), ToStackSlotAddress(destination));
  } else if (source.IsStackSlot() && destination.IsRegister()) {
    Exchange(destination.reg(), ToStackSlotAddress(source));
  } else if (source.IsStackSlot() && destination.IsStackSlot()) {
    Exchange(ToStackSlotAddress(destination), ToStackSlotAddress(source));
  } else if (source.IsXmmRegister() && destination.IsXmmRegister()) {
    __ movaps(XMM0, source.xmm_reg());
    __ movaps(source.xmm_reg(), destination.xmm_reg());
    __ movaps(destination.xmm_reg(), XMM0);
  } else if (source.IsXmmRegister() || destination.IsXmmRegister()) {
    ASSERT(destination.IsDoubleStackSlot() || source.IsDoubleStackSlot());
    XmmRegister reg = source.IsXmmRegister() ? source.xmm_reg()
                                             : destination.xmm_reg();
    Address slot_address =
        ToStackSlotAddress(source.IsXmmRegister() ? destination : source);

    __ movsd(XMM0, slot_address);
    __ movsd(slot_address, reg);
    __ movaps(reg, XMM0);
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


#undef __

}  // namespace dart

#endif  // defined TARGET_ARCH_X64

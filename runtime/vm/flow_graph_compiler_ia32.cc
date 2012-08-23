// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

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

DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, print_ast);
DECLARE_FLAG(bool, print_scopes);
DECLARE_FLAG(bool, trace_functions);


void DeoptimizationStub::GenerateCode(FlowGraphCompiler* compiler,
                                      intptr_t stub_ix) {
  Assembler* assem = compiler->assembler();
#define __ assem->
  __ Comment("Deopt stub for id %d", deopt_id_);
  __ Bind(entry_label());

  ASSERT(deoptimization_env_ != NULL);

  if (compiler->IsLeaf()) {
    Label L;
    __ pushl(EAX);  // Preserve EAX.
    __ call(&L);
    const intptr_t offset = assem->CodeSize();
    __ Bind(&L);
    __ popl(EAX);
    __ subl(EAX,
        Immediate(offset - AssemblerMacros::kOffsetOfSavedPCfromEntrypoint));
    __ movl(Address(EBP, -kWordSize), EAX);
    __ popl(EAX);
  }
  __ call(&StubCode::DeoptimizeLabel());
  const intptr_t deopt_info_index = stub_ix;
  compiler->pc_descriptors_list()-> AddDeoptInfo(
      compiler->assembler()->CodeSize(),
      deopt_id_,
      reason_,
      deopt_info_index);
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
  __ cmpl(bool_register, raw_null);
  __ j(EQUAL, &fall_through, Assembler::kNearJump);
  __ CompareObject(bool_register, bool_true());
  __ j(EQUAL, is_true);
  __ jmp(is_false);
  __ Bind(&fall_through);
}


// Clobbers ECX.
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
  __ pushl(temp_reg);  // Subtype test cache.
  __ pushl(instance_reg);  // Instance.
  if (test_kind == kTestTypeOneArg) {
    ASSERT(type_arguments_reg == kNoRegister);
    __ pushl(raw_null);
    __ call(&StubCode::Subtype1TestCacheLabel());
  } else if (test_kind == kTestTypeTwoArgs) {
    ASSERT(type_arguments_reg == kNoRegister);
    __ pushl(raw_null);
    __ call(&StubCode::Subtype2TestCacheLabel());
  } else if (test_kind == kTestTypeThreeArgs) {
    __ pushl(type_arguments_reg);
    __ call(&StubCode::Subtype3TestCacheLabel());
  } else {
    UNREACHABLE();
  }
  // Result is in ECX: null -> not found, otherwise Bool::True or Bool::False.
  ASSERT(instance_reg != ECX);
  ASSERT(temp_reg != ECX);
  __ popl(instance_reg);  // Discard.
  __ popl(instance_reg);  // Restore receiver.
  __ popl(temp_reg);  // Discard.
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
    intptr_t token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  ASSERT(type.IsInstantiated());
  const Class& type_class = Class::ZoneHandle(type.type_class());
  ASSERT(type_class.HasTypeArguments());
  const Register kInstanceReg = EAX;
  // A Smi object cannot be the instance of a parameterized class.
  __ testl(kInstanceReg, Immediate(kSmiTagMask));
  __ j(ZERO, is_not_instance_lbl);
  const AbstractTypeArguments& type_arguments =
      AbstractTypeArguments::ZoneHandle(type.arguments());
  const bool is_raw_type = type_arguments.IsNull() ||
      type_arguments.IsRaw(type_arguments.Length());
  if (is_raw_type) {
    const Register kClassIdReg = ECX;
    // Dynamic type argument, check only classes.
    // List is a very common case.
    __ LoadClassId(kClassIdReg, kInstanceReg);
    if (!type_class.is_interface()) {
      __ cmpl(kClassIdReg, Immediate(type_class.id()));
      __ j(EQUAL, is_instance_lbl);
    }
    if (type.IsListInterface()) {
      GenerateListTypeCheck(kClassIdReg, is_instance_lbl);
    }
    return GenerateSubtype1TestCacheLookup(
        token_pos, type_class, is_instance_lbl, is_not_instance_lbl);
  }
  // If one type argument only, check if type argument is Object or Dynamic.
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
  const Register kTempReg = EDI;
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
// EAX: instance to test against (preserved).
// Clobbers ECX, EDI.
// Returns true if there is a fallthrough.
bool FlowGraphCompiler::GenerateInstantiatedTypeNoArgumentsTest(
    intptr_t token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  ASSERT(type.IsInstantiated());
  const Class& type_class = Class::Handle(type.type_class());
  ASSERT(!type_class.HasTypeArguments());

  const Register kInstanceReg = EAX;
  Label compare_classes;
  __ testl(kInstanceReg, Immediate(kSmiTagMask));
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
  const Register kClassIdReg = ECX;
  __ LoadClassId(kClassIdReg, kInstanceReg);
  // If type is an interface, we can skip the class equality check.
  if (!type_class.is_interface()) {
    __ cmpl(kClassIdReg, Immediate(type_class.id()));
    __ j(EQUAL, is_instance_lbl);
  }
  // Bool interface can be implemented only by core class Bool.
  // (see ClassFinalizer::ResolveInterfaces for list of restricted interfaces).
  if (type.IsBoolInterface()) {
    __ cmpl(kClassIdReg, Immediate(kBoolCid));
    __ j(EQUAL, is_instance_lbl);
    __ jmp(is_not_instance_lbl);
    return false;
  }
  if (type.IsFunctionInterface()) {
    // Check if instance is a closure.
    const Immediate raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ LoadClassById(EDI, kClassIdReg);
    __ movl(EDI, FieldAddress(EDI, Class::signature_function_offset()));
    __ cmpl(EDI, raw_null);
    __ j(NOT_EQUAL, is_instance_lbl);
    __ jmp(is_not_instance_lbl);
    return false;
  }
  // Custom checking for numbers (Smi, Mint, Bigint and Double).
  // Note that instance is not Smi (checked above).
  if (type.IsSubtypeOf(Type::Handle(Type::NumberInterface()), NULL)) {
    GenerateNumberTypeCheck(
        kClassIdReg, type, is_instance_lbl, is_not_instance_lbl);
    return false;
  }
  if (type.IsStringInterface()) {
    GenerateStringTypeCheck(kClassIdReg, is_instance_lbl, is_not_instance_lbl);
    return false;
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
    intptr_t token_pos,
    const Class& type_class,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  const Register kInstanceReg = EAX;
  __ LoadClass(ECX, kInstanceReg, EDI);
  // ECX: instance class.
  // Check immediate superclass equality.
  __ movl(EDI, FieldAddress(ECX, Class::super_type_offset()));
  __ movl(EDI, FieldAddress(EDI, Type::type_class_offset()));
  __ CompareObject(EDI, type_class);
  __ j(EQUAL, is_instance_lbl);

  const Register kTypeArgumentsReg = kNoRegister;
  const Register kTempReg = EDI;
  return GenerateCallSubtypeTestStub(kTestTypeOneArg,
                                     kInstanceReg,
                                     kTypeArgumentsReg,
                                     kTempReg,
                                     is_instance_lbl,
                                     is_not_instance_lbl);
}


// Generates inlined check if 'type' is a type parameter or type itsef
// EAX: instance (preserved).
// Clobbers EDX, EDI, ECX.
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
    __ movl(EDX, Address(ESP, 0));  // Get instantiator type arguments.
    // EDX: instantiator type arguments.
    // Check if type argument is Dynamic.
    __ cmpl(EDX, raw_null);
    __ j(EQUAL, is_instance_lbl);
    // Can handle only type arguments that are instances of TypeArguments.
    // (runtime checks canonicalize type arguments).
    Label fall_through;
    __ CompareClassId(EDX, kTypeArgumentsCid, EDI);
    __ j(NOT_EQUAL, &fall_through, Assembler::kNearJump);
    __ movl(EDI,
        FieldAddress(EDX, TypeArguments::type_at_offset(type_param.index())));
    // EDI: concrete type of type.
    // Check if type argument is dynamic.
    __ CompareObject(EDI, Type::ZoneHandle(Type::DynamicType()));
    __ j(EQUAL,  is_instance_lbl);
    __ cmpl(EDI, raw_null);
    __ j(EQUAL,  is_instance_lbl);
    const Type& object_type = Type::ZoneHandle(Type::ObjectType());
    __ CompareObject(EDI, object_type);
    __ j(EQUAL,  is_instance_lbl);

    // For Smi check quickly against int and num interfaces.
    Label not_smi;
    __ testl(EAX, Immediate(kSmiTagMask));  // Value is Smi?
    __ j(NOT_ZERO, &not_smi, Assembler::kNearJump);
    __ CompareObject(EDI, Type::ZoneHandle(Type::IntInterface()));
    __ j(EQUAL,  is_instance_lbl);
    __ CompareObject(EDI, Type::ZoneHandle(Type::NumberInterface()));
    __ j(EQUAL,  is_instance_lbl);
    // Smi must be handled in runtime.
    __ jmp(&fall_through);

    __ Bind(&not_smi);
    // EDX: instantiator type arguments.
    // EAX: instance.
    const Register kInstanceReg = EAX;
    const Register kTypeArgumentsReg = EDX;
    const Register kTempReg = EDI;
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
    const Register kInstanceReg = EAX;
    const Register kTypeArgumentsReg = EDX;
    __ testl(kInstanceReg, Immediate(kSmiTagMask));  // Is instance Smi?
    __ j(ZERO, is_not_instance_lbl);
    __ movl(kTypeArgumentsReg, Address(ESP, 0));  // Instantiator type args.
    // Uninstantiated type class is known at compile time, but the type
    // arguments are determined at runtime by the instantiator.
    const Register kTempReg = EDI;
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
// - EAX: instance to test against (preserved).
// - EDX: optional instantiator type arguments (preserved).
// Clobbers ECX, EDI.
// Returns:
// - preserved instance in EAX and optional instantiator type arguments in EDX.
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
// - EAX: object.
// - EDX: instantiator type arguments or raw_null.
// - ECX: instantiator or raw_null.
// Clobbers ECX and EDX.
// Returns:
// - true or false in EAX.
void FlowGraphCompiler::GenerateInstanceOf(intptr_t deopt_id,
                                           intptr_t token_pos,
                                           intptr_t try_index,
                                           const AbstractType& type,
                                           bool negate_result,
                                           BitmapBuilder* stack_bitmap) {
  ASSERT(type.IsFinalized() && !type.IsMalformed());

  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label is_instance, is_not_instance;
  __ pushl(ECX);  // Store instantiator on stack.
  __ pushl(EDX);  // Store instantiator type arguments.
  // If type is instantiated and non-parameterized, we can inline code
  // checking whether the tested instance is a Smi.
  if (type.IsInstantiated()) {
    // A null object is only an instance of Object and Dynamic, which has
    // already been checked above (if the type is instantiated). So we can
    // return false here if the instance is null (and if the type is
    // instantiated).
    // We can only inline this null check if the type is instantiated at compile
    // time, since an uninstantiated type at compile time could be Object or
    // Dynamic at run time.
    __ cmpl(EAX, raw_null);
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
    __ movl(EDX, Address(ESP, 0));  // Get instantiator type arguments.
    __ movl(ECX, Address(ESP, kWordSize));  // Get instantiator.
    __ PushObject(Object::ZoneHandle());  // Make room for the result.
    __ pushl(EAX);  // Push the instance.
    __ PushObject(type);  // Push the type.
    __ pushl(ECX);  // Instantiator.
    __ pushl(EDX);  // Instantiator type arguments.
    __ LoadObject(EAX, test_cache);
    __ pushl(EAX);
    GenerateCallRuntime(deopt_id, token_pos, try_index,
                        kInstanceofRuntimeEntry, stack_bitmap);
    // Pop the parameters supplied to the runtime entry. The result of the
    // instanceof runtime call will be left as the result of the operation.
    __ Drop(5);
    if (negate_result) {
      __ popl(EDX);
      __ LoadObject(EAX, bool_true());
      __ cmpl(EDX, EAX);
      __ j(NOT_EQUAL, &done, Assembler::kNearJump);
      __ LoadObject(EAX, bool_false());
    } else {
      __ popl(EAX);
    }
    __ jmp(&done, Assembler::kNearJump);
  }
  __ Bind(&is_not_instance);
  __ LoadObject(EAX, negate_result ? bool_true() : bool_false());
  __ jmp(&done, Assembler::kNearJump);

  __ Bind(&is_instance);
  __ LoadObject(EAX, negate_result ? bool_false() : bool_true());
  __ Bind(&done);
  __ popl(EDX);  // Remove pushed instantiator type arguments.
  __ popl(ECX);  // Remove pushed instantiator.
}


// Optimize assignable type check by adding inlined tests for:
// - NULL -> return NULL.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs:
// - EAX: object.
// - EDX: instantiator type arguments or raw_null.
// - ECX: instantiator or raw_null.
// Returns:
// - object in EAX for successful assignable check (or throws TypeError).
// Performance notes: positive checks must be quick, negative checks can be slow
// as they throw an exception.
void FlowGraphCompiler::GenerateAssertAssignable(intptr_t deopt_id,
                                                 intptr_t token_pos,
                                                 intptr_t try_index,
                                                 const AbstractType& dst_type,
                                                 const String& dst_name,
                                                 BitmapBuilder* stack_bitmap) {
  ASSERT(token_pos >= 0);
  ASSERT(!dst_type.IsNull());
  ASSERT(dst_type.IsFinalized());
  // Assignable check is skipped in FlowGraphBuilder, not here.
  ASSERT(dst_type.IsMalformed() ||
         (!dst_type.IsDynamicType() && !dst_type.IsObjectType()));
  __ pushl(ECX);  // Store instantiator.
  __ pushl(EDX);  // Store instantiator type arguments.
  // A null object is always assignable and is returned as result.
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label is_assignable, runtime_call;
  __ cmpl(EAX, raw_null);
  __ j(EQUAL, &is_assignable);

  // Generate throw new TypeError() if the type is malformed.
  if (dst_type.IsMalformed()) {
    const Error& error = Error::Handle(dst_type.malformed_error());
    const String& error_message = String::ZoneHandle(
        Symbols::New(error.ToErrorCString()));
    __ PushObject(Object::ZoneHandle());  // Make room for the result.
    __ pushl(EAX);  // Push the source object.
    __ PushObject(dst_name);  // Push the name of the destination.
    __ PushObject(error_message);
    GenerateCallRuntime(deopt_id,
                        token_pos,
                        try_index,
                        kMalformedTypeErrorRuntimeEntry,
                        stack_bitmap);
    // We should never return here.
    __ int3();

    __ Bind(&is_assignable);  // For a null object.
    __ popl(EDX);  // Remove pushed instantiator type arguments.
    __ popl(ECX);  // Remove pushed instantiator.
    return;
  }

  // Generate inline type check, linking to runtime call if not assignable.
  SubtypeTestCache& test_cache = SubtypeTestCache::ZoneHandle();
  test_cache = GenerateInlineInstanceof(token_pos, dst_type,
                                        &is_assignable, &runtime_call);

  __ Bind(&runtime_call);
  __ movl(EDX, Address(ESP, 0));  // Get instantiator type arguments.
  __ movl(ECX, Address(ESP, kWordSize));  // Get instantiator.
  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  __ pushl(EAX);  // Push the source object.
  __ PushObject(dst_type);  // Push the type of the destination.
  __ pushl(ECX);  // Instantiator.
  __ pushl(EDX);  // Instantiator type arguments.
  __ PushObject(dst_name);  // Push the name of the destination.
  __ LoadObject(EAX, test_cache);
  __ pushl(EAX);
  GenerateCallRuntime(deopt_id,
                      token_pos,
                      try_index,
                      kTypeCheckRuntimeEntry,
                      stack_bitmap);
  // Pop the parameters supplied to the runtime entry. The result of the
  // type check runtime call is the checked value.
  __ Drop(6);
  __ popl(EAX);

  __ Bind(&is_assignable);
  __ popl(EDX);  // Remove pushed instantiator type arguments.
  __ popl(ECX);  // Remove pushed instantiator.
}


void FlowGraphCompiler::EmitInstructionPrologue(Instruction* instr) {
  if (!is_optimizing()) {
    AllocateRegistersLocally(instr);
  }
}


void FlowGraphCompiler::CopyParameters() {
  __ Comment("Copy parameters");
  const Function& function = parsed_function().function();
  const bool is_native_instance_closure =
      function.is_native() && function.IsImplicitInstanceClosureFunction();
  LocalScope* scope = parsed_function().node_sequence()->scope();
  const int num_fixed_params = function.num_fixed_parameters();
  const int num_opt_params = function.num_optional_parameters();
  int implicit_this_param_pos = is_native_instance_closure ? -1 : 0;
  ASSERT(parsed_function().first_parameter_index() ==
         ParsedFunction::kFirstLocalSlotIndex + implicit_this_param_pos);
  // Copy positional arguments.
  // Check that no fewer than num_fixed_params positional arguments are passed
  // in and that no more than num_params arguments are passed in.
  // Passed argument i at fp[1 + argc - i]
  // copied to fp[ParsedFunction::kFirstLocalSlotIndex - i].
  const int num_params = num_fixed_params + num_opt_params;

  // Total number of args is the first Smi in args descriptor array (EDX).
  __ movl(EBX, FieldAddress(EDX, Array::data_offset()));
  // Check that num_args <= num_params.
  Label wrong_num_arguments;
  __ cmpl(EBX, Immediate(Smi::RawValue(num_params)));
  __ j(GREATER, &wrong_num_arguments);
  // Number of positional args is the second Smi in descriptor array (EDX).
  __ movl(ECX, FieldAddress(EDX, Array::data_offset() + (1 * kWordSize)));
  // Check that num_pos_args >= num_fixed_params.
  __ cmpl(ECX, Immediate(Smi::RawValue(num_fixed_params)));
  __ j(LESS, &wrong_num_arguments);

  // Since EBX and ECX are Smi, use TIMES_2 instead of TIMES_4.
  // Let EBX point to the last passed positional argument, i.e. to
  // fp[1 + num_args - (num_pos_args - 1)].
  __ subl(EBX, ECX);
  __ leal(EBX, Address(EBP, EBX, TIMES_2, 2 * kWordSize));

  // Let EDI point to the last copied positional argument, i.e. to
  // fp[ParsedFunction::kFirstLocalSlotIndex - (num_pos_args - 1)].
  const int index =
      ParsedFunction::kFirstLocalSlotIndex + 1 + implicit_this_param_pos;
  // First copy captured receiver if function is an implicit native closure.
  if (is_native_instance_closure) {
    __ movl(EAX, FieldAddress(CTX, Context::variable_offset(0)));
    __ movl(Address(EBP, (index * kWordSize)), EAX);
  }
  __ leal(EDI, Address(EBP, (index * kWordSize)));
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
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label all_arguments_processed;
  if (num_opt_params > 0) {
    // Start by alphabetically sorting the names of the optional parameters.
    LocalVariable** opt_param = new LocalVariable*[num_opt_params];
    int* opt_param_position = new int[num_opt_params];
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
    // Total number of args is the first Smi in args descriptor array (EDX).
    __ movl(EBX, FieldAddress(EDX, Array::data_offset()));
    // Number of positional args is the second Smi in descriptor array (EDX).
    __ movl(ECX, FieldAddress(EDX, Array::data_offset() + (1 * kWordSize)));
    __ SmiUntag(ECX);
    // Let EBX point to the first passed argument, i.e. to fp[1 + argc - 0].
    __ leal(EBX, Address(EBP, EBX, TIMES_2, kWordSize));  // EBX is Smi.
    // Let EDI point to the name/pos pair of the first named argument.
    __ leal(EDI, FieldAddress(EDX, Array::data_offset() + (2 * kWordSize)));
    for (int i = 0; i < num_opt_params; i++) {
      // Handle this optional parameter only if k or fewer positional arguments
      // have been passed, where k is the position of this optional parameter in
      // the formal parameter list.
      Label load_default_value, assign_optional_parameter, next_parameter;
      const int param_pos = opt_param_position[i];
      __ cmpl(ECX, Immediate(param_pos));
      __ j(GREATER, &next_parameter, Assembler::kNearJump);
      // Check if this named parameter was passed in.
      __ movl(EAX, Address(EDI, 0));  // Load EAX with the name of the argument.
      ASSERT(opt_param[i]->name().IsSymbol());
      __ CompareObject(EAX, opt_param[i]->name());
      __ j(NOT_EQUAL, &load_default_value, Assembler::kNearJump);
      // Load EAX with passed-in argument at provided arg_pos, i.e. at
      // fp[1 + argc - arg_pos].
      __ movl(EAX, Address(EDI, kWordSize));  // EAX is arg_pos as Smi.
      __ addl(EDI, Immediate(2 * kWordSize));  // Point to next name/pos pair.
      __ negl(EAX);
      Address argument_addr(EBX, EAX, TIMES_2, 0);  // EAX is a negative Smi.
      __ movl(EAX, argument_addr);
      __ jmp(&assign_optional_parameter, Assembler::kNearJump);
      __ Bind(&load_default_value);
      // Load EAX with default argument at pos.
      const Object& value = Object::ZoneHandle(
          parsed_function().default_parameter_values().At(
              param_pos - num_fixed_params));
      __ LoadObject(EAX, value);
      __ Bind(&assign_optional_parameter);
      // Assign EAX to fp[ParsedFunction::kFirstLocalSlotIndex - param_pos].
      // We do not use the final allocation index of the variable here, i.e.
      // scope->VariableAt(i)->index(), because captured variables still need
      // to be copied to the context that is not yet allocated.
      intptr_t computed_param_pos = (ParsedFunction::kFirstLocalSlotIndex -
                                     param_pos + implicit_this_param_pos);
      const Address param_addr(EBP, (computed_param_pos * kWordSize));
      __ movl(param_addr, EAX);
      __ Bind(&next_parameter);
    }
    delete[] opt_param;
    delete[] opt_param_position;
    // Check that EDI now points to the null terminator in the array descriptor.
    __ cmpl(Address(EDI, 0), raw_null);
    __ j(EQUAL, &all_arguments_processed, Assembler::kNearJump);
  } else {
    ASSERT(is_native_instance_closure);
    __ jmp(&all_arguments_processed, Assembler::kNearJump);
  }

  __ Bind(&wrong_num_arguments);
  if (StackSize() != 0) {
    // We need to unwind the space we reserved for locals and copied parameters.
    // The NoSuchMethodFunction stub does not expect to see that area on the
    // stack.
    __ addl(ESP, Immediate(StackSize() * kWordSize));
  }
  // The calls below have empty stackmaps because we have just dropped the
  // spill slots.
  BitmapBuilder* empty_stack_bitmap = new BitmapBuilder();
  if (function.IsClosureFunction()) {
    GenerateCallRuntime(Isolate::kNoDeoptId,
                        0,
                        CatchClauseNode::kInvalidTryIndex,
                        kClosureArgumentMismatchRuntimeEntry,
                        empty_stack_bitmap);
  } else {
    ASSERT(!IsLeaf());
    // Invoke noSuchMethod function.
    const int kNumArgsChecked = 1;
    ICData& ic_data = ICData::ZoneHandle();
    ic_data = ICData::New(function,
                          String::Handle(function.name()),
                          Isolate::kNoDeoptId,
                          kNumArgsChecked);
    __ LoadObject(ECX, ic_data);
    // EBP - 4 : PC marker, allows easy identification of RawInstruction obj.
    // EBP : points to previous frame pointer.
    // EBP + 4 : points to return address.
    // EBP + 8 : address of last argument (arg n-1).
    // ESP + 8 + 4*(n-1) : address of first argument (arg 0).
    // ECX : ic-data.
    // EDX : arguments descriptor array.
    __ call(&StubCode::CallNoSuchMethodFunctionLabel());
    if (is_optimizing()) {
      stackmap_table_builder_->AddEntry(assembler()->CodeSize(),
                                        empty_stack_bitmap);
    }
  }

  if (FLAG_trace_functions) {
    __ pushl(EAX);  // Preserve result.
    __ PushObject(Function::ZoneHandle(function.raw()));
    GenerateCallRuntime(Isolate::kNoDeoptId,
                        0,
                        CatchClauseNode::kInvalidTryIndex,
                        kTraceFunctionExitRuntimeEntry,
                        empty_stack_bitmap);
    __ popl(EAX);  // Remove argument.
    __ popl(EAX);  // Restore result.
  }
  __ LeaveFrame();
  __ ret();

  __ Bind(&all_arguments_processed);
  // Nullify originally passed arguments only after they have been copied and
  // checked, otherwise noSuchMethod would not see their original values.
  // This step can be skipped in case we decide that formal parameters are
  // implicitly final, since garbage collecting the unmodified value is not
  // an issue anymore.

  // EDX : arguments descriptor array.
  // Total number of args is the first Smi in args descriptor array (EDX).
  __ movl(ECX, FieldAddress(EDX, Array::data_offset()));
  __ SmiUntag(ECX);
  Label null_args_loop, null_args_loop_condition;
  __ jmp(&null_args_loop_condition, Assembler::kNearJump);
  const Address original_argument_addr(EBP, ECX, TIMES_4, 2 * kWordSize);
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
  __ movl(EAX, Address(ESP, 1 * kWordSize));
  __ movl(EAX, FieldAddress(EAX, offset));
  __ ret();
}


void FlowGraphCompiler::GenerateInlinedSetter(intptr_t offset) {
  // TOS: return address.
  // +1 : value
  // +2 : receiver.
  // Sequence node has one store node and one return NULL node.
  __ movl(EAX, Address(ESP, 2 * kWordSize));  // Receiver.
  __ movl(EBX, Address(ESP, 1 * kWordSize));  // Value.
  __ StoreIntoObject(EAX, FieldAddress(EAX, offset), EBX);
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movl(EAX, raw_null);
  __ ret();
}


void FlowGraphCompiler::GenerateInlinedMathSqrt(Label* done) {
  Label smi_to_double, double_op, call_method;
  __ movl(EAX, Address(ESP, 0));
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(ZERO, &smi_to_double);
  __ CompareClassId(EAX, kDoubleCid, EBX);
  __ j(NOT_EQUAL, &call_method);
  __ movsd(XMM1, FieldAddress(EAX, Double::value_offset()));
  __ Bind(&double_op);
  __ sqrtsd(XMM0, XMM1);
  AssemblerMacros::TryAllocate(assembler_,
                               double_class_,
                               &call_method,
                               EAX);  // Result register.
  __ movsd(FieldAddress(EAX, Double::value_offset()), XMM0);
  __ Drop(1);
  __ jmp(done);
  __ Bind(&smi_to_double);
  __ SmiUntag(EAX);
  __ cvtsi2sd(XMM1, EAX);
  __ jmp(&double_op);
  __ Bind(&call_method);
}


void FlowGraphCompiler::CompileGraph() {
  InitCompiler();
  if (TryIntrinsify()) {
    // Although this intrinsified code will never be patched, it must satisfy
    // CodePatcher::CodeIsPatchable, which verifies that this code has a minimum
    // code size.
    __ int3();
    __ jmp(&StubCode::FixCallersTargetLabel());
    return;
  }
  // Specialized version of entry code from CodeGenerator::GenerateEntryCode.
  const Function& function = parsed_function().function();

  const int parameter_count = function.num_fixed_parameters();
  const int copied_parameter_count = parsed_function().copied_parameter_count();
  const int local_count = parsed_function().stack_local_count();
  __ Comment("Enter frame");
  if (IsLeaf()) {
    AssemblerMacros::EnterDartLeafFrame(assembler(), (StackSize() * kWordSize));
  } else {
    AssemblerMacros::EnterDartFrame(assembler(), (StackSize() * kWordSize));
  }

  // For optimized code, keep a bitmap of the frame in order to build
  // stackmaps for GC safepoints in the prologue.
  BitmapBuilder* stack_bitmap = NULL;
  if (is_optimizing()) {
    // Spill slots are allocated but not initialized.
    stack_bitmap = new BitmapBuilder();
    stack_bitmap->SetLength(StackSize());
  }

  // We check the number of passed arguments when we have to copy them due to
  // the presence of optional named parameters.
  // No such checking code is generated if only fixed parameters are declared,
  // unless we are debug mode or unless we are compiling a closure.
  if (copied_parameter_count == 0) {
#ifdef DEBUG
    const bool check_arguments = true;
#else
    const bool check_arguments = function.IsClosureFunction();
#endif
    if (check_arguments) {
      __ Comment("Check argument count");
      // Check that num_fixed <= argc <= num_params.
      Label argc_in_range;
      // Total number of args is the first Smi in args descriptor array (EDX).
      __ movl(EAX, FieldAddress(EDX, Array::data_offset()));
      __ cmpl(EAX, Immediate(Smi::RawValue(parameter_count)));
      __ j(EQUAL, &argc_in_range, Assembler::kNearJump);
      if (function.IsClosureFunction()) {
        GenerateCallRuntime(Isolate::kNoDeoptId,
                            function.token_pos(),
                            CatchClauseNode::kInvalidTryIndex,
                            kClosureArgumentMismatchRuntimeEntry,
                            stack_bitmap);
      } else {
        __ Stop("Wrong number of arguments");
      }
      __ Bind(&argc_in_range);
    }
  } else {
    CopyParameters();
  }

  // In unoptimized code, initialize (non-argument) stack allocated slots to
  // null.
  if (!is_optimizing() && (local_count > 0)) {
    __ Comment("Initialize spill slots");
    const intptr_t slot_base = parsed_function().first_stack_local_index();
    const Immediate raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ movl(EAX, raw_null);
    for (intptr_t i = 0; i < local_count; ++i) {
      // Subtract index i (locals lie at lower addresses than EBP).
      __ movl(Address(EBP, (slot_base - i) * kWordSize), EAX);
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

  __ int3();
  GenerateDeferredCode();
  // Emit function patching code. This will be swapped with the first 5 bytes
  // at entry point.
  pc_descriptors_list()->AddDescriptor(PcDescriptors::kPatchCode,
                                       assembler()->CodeSize(),
                                       Isolate::kNoDeoptId,
                                       0,
                                       -1);
  __ jmp(&StubCode::FixCallersTargetLabel());
}


void FlowGraphCompiler::GenerateCall(intptr_t token_pos,
                                     intptr_t try_index,
                                     const ExternalLabel* label,
                                     PcDescriptors::Kind kind,
                                     BitmapBuilder* stack_bitmap) {
  ASSERT(!IsLeaf());
  __ call(label);
  if (is_optimizing() && (stack_bitmap != NULL)) {
    stackmap_table_builder_->AddEntry(assembler()->CodeSize(), stack_bitmap);
  }
  AddCurrentDescriptor(kind, Isolate::kNoDeoptId, token_pos, try_index);
}


void FlowGraphCompiler::GenerateCallRuntime(intptr_t deopt_id,
                                            intptr_t token_pos,
                                            intptr_t try_index,
                                            const RuntimeEntry& entry,
                                            BitmapBuilder* stack_bitmap) {
  ASSERT(!IsLeaf());
  ASSERT(!is_optimizing() || (stack_bitmap != NULL));
  __ CallRuntime(entry);
  if (is_optimizing()) {
    stackmap_table_builder_->AddEntry(assembler()->CodeSize(), stack_bitmap);
  }
  AddCurrentDescriptor(PcDescriptors::kOther, deopt_id, token_pos, try_index);
}


intptr_t FlowGraphCompiler::EmitInstanceCall(ExternalLabel* target_label,
                                             const ICData& ic_data,
                                             const Array& arguments_descriptor,
                                             intptr_t argument_count) {
  ASSERT(!IsLeaf());
  __ LoadObject(ECX, ic_data);
  __ LoadObject(EDX, arguments_descriptor);

  __ call(target_label);
  const intptr_t descr_offset = assembler()->CodeSize();
  __ Drop(argument_count);
  return descr_offset;
}


intptr_t FlowGraphCompiler::EmitStaticCall(const Function& function,
                                           const Array& arguments_descriptor,
                                           intptr_t argument_count) {
  ASSERT(!IsLeaf());
  __ LoadObject(ECX, function);
  __ LoadObject(EDX, arguments_descriptor);
  __ call(&StubCode::CallStaticFunctionLabel());
  const intptr_t descr_offset = assembler()->CodeSize();
  __ Drop(argument_count);
  return descr_offset;
}


// Checks class id of instance against all 'class_ids'. Jump to 'deopt' label
// if no match or instance is Smi.
void FlowGraphCompiler::EmitClassChecksNoSmi(const ICData& ic_data,
                                             Register instance_reg,
                                             Register temp_reg,
                                             Label* deopt) {
  Label ok;
  ASSERT(ic_data.GetReceiverClassIdAt(0) != kSmiCid);
  __ testl(instance_reg, Immediate(kSmiTagMask));
  __ j(ZERO, deopt);
  Label is_ok;
  const intptr_t num_checks = ic_data.NumberOfChecks();
  const bool use_near_jump = num_checks < 5;
  __ LoadClassId(temp_reg, instance_reg);
  for (intptr_t i = 0; i < num_checks; i++) {
    __ cmpl(temp_reg, Immediate(ic_data.GetReceiverClassIdAt(i)));
    if (i == (num_checks - 1)) {
      __ j(NOT_EQUAL, deopt);
    } else {
      if (use_near_jump) {
        __ j(EQUAL, &is_ok, Assembler::kNearJump);
      } else {
        __ j(EQUAL, &is_ok);
      }
    }
  }
  __ Bind(&is_ok);
}


void FlowGraphCompiler::LoadDoubleOrSmiToXmm(XmmRegister result,
                                             Register reg,
                                             Register temp,
                                             Label* not_double_or_smi) {
  Label is_smi, done;
  __ testl(reg, Immediate(kSmiTagMask));
  __ j(ZERO, &is_smi);
  __ CompareClassId(reg, kDoubleCid, temp);
  __ j(NOT_EQUAL, not_double_or_smi);
  __ movsd(result, FieldAddress(reg, Double::value_offset()));
  __ jmp(&done);
  __ Bind(&is_smi);
  __ movl(temp, reg);
  __ SmiUntag(temp);
  __ cvtsi2sd(result, temp);
  __ Bind(&done);
}


#undef __
#define __ compiler_->assembler()->


static Address ToStackSlotAddress(Location loc) {
  ASSERT(loc.IsStackSlot());
  const intptr_t index = loc.stack_index();
  if (index < 0) {
    const intptr_t offset = (1 - index)  * kWordSize;
    return Address(EBP, offset);
  } else {
    const intptr_t offset =
        (ParsedFunction::kFirstLocalSlotIndex - index) * kWordSize;
    return Address(EBP, offset);
  }
}


void ParallelMoveResolver::EmitMove(int index) {
  MoveOperands* move = moves_[index];
  const Location source = move->src();
  const Location destination = move->dest();

  if (source.IsRegister()) {
    if (destination.IsRegister()) {
      __ movl(destination.reg(), source.reg());
    } else {
      ASSERT(destination.IsStackSlot());
      __ movl(ToStackSlotAddress(destination), source.reg());
    }
  } else if (source.IsStackSlot()) {
    if (destination.IsRegister()) {
      __ movl(destination.reg(), ToStackSlotAddress(source));
    } else {
      ASSERT(destination.IsStackSlot());
      MoveMemoryToMemory(ToStackSlotAddress(destination),
                         ToStackSlotAddress(source));
    }
  } else {
    ASSERT(source.IsConstant());
    if (destination.IsRegister()) {
      __ LoadObject(destination.reg(), source.constant());
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
    __ xchgl(destination.reg(), source.reg());
  } else if (source.IsRegister() && destination.IsStackSlot()) {
    Exchange(source.reg(), ToStackSlotAddress(destination));
  } else if (source.IsStackSlot() && destination.IsRegister()) {
    Exchange(destination.reg(), ToStackSlotAddress(source));
  } else if (source.IsStackSlot() && destination.IsStackSlot()) {
    Exchange(ToStackSlotAddress(destination), ToStackSlotAddress(source));
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
  // TODO(vegorov): allocate temporary register for such moves.
  __ pushl(EAX);
  __ movl(EAX, src);
  __ movl(dst, EAX);
  __ popl(EAX);
}


void ParallelMoveResolver::StoreObject(const Address& dst, const Object& obj) {
  // TODO(vegorov): allocate temporary register for such moves.
  __ pushl(EAX);
  __ LoadObject(EAX, obj);
  __ movl(dst, EAX);
  __ popl(EAX);
}


void ParallelMoveResolver::Exchange(Register reg, const Address& mem) {
  // TODO(vegorov): allocate temporary register for such moves.
  Register scratch = (reg == EAX) ? ECX : EAX;
  __ pushl(scratch);
  __ movl(scratch, mem);
  __ xchgl(scratch, reg);
  __ movl(mem, scratch);
  __ popl(scratch);
}


void ParallelMoveResolver::Exchange(const Address& mem1, const Address& mem2) {
  // TODO(vegorov): allocate temporary registers for such moves.
  __ pushl(EAX);
  __ pushl(ECX);
  __ movl(EAX, mem1);
  __ movl(ECX, mem2);
  __ movl(mem1, ECX);
  __ movl(mem2, EAX);
  __ popl(ECX);
  __ popl(EAX);
}


#undef __

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32

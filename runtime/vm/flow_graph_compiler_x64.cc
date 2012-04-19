// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/flow_graph_compiler.h"

#include "lib/error.h"
#include "vm/ast_printer.h"
#include "vm/code_descriptors.h"
#include "vm/code_generator.h"
#include "vm/debugger.h"
#include "vm/disassembler.h"
#include "vm/intrinsifier.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/stub_code.h"

namespace dart {

DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, intrinsify);
DECLARE_FLAG(bool, optimization_counter_threshold);
DECLARE_FLAG(bool, print_ast);
DECLARE_FLAG(bool, print_scopes);
DECLARE_FLAG(bool, report_usage_count);
DECLARE_FLAG(bool, trace_functions);


FlowGraphCompiler::FlowGraphCompiler(
    Assembler* assembler,
    const ParsedFunction& parsed_function,
    const GrowableArray<BlockEntryInstr*>& block_order)
    : FlowGraphVisitor(block_order),
      assembler_(assembler),
      parsed_function_(parsed_function),
      block_info_(block_order.length()),
      current_block_(NULL),
      pc_descriptors_list_(new DescriptorList()),
      exception_handlers_list_(new ExceptionHandlerList()) {
  for (int i = 0; i < block_order.length(); ++i) {
    block_info_.Add(new BlockInfo());
  }
}


FlowGraphCompiler::~FlowGraphCompiler() {
  // BlockInfos are zone-allocated, so their destructors are not called.
  // Verify the labels explicitly here.
  for (int i = 0; i < block_info_.length(); ++i) {
    ASSERT(!block_info_[i]->label.IsLinked());
    ASSERT(!block_info_[i]->label.HasNear());
  }
}


intptr_t FlowGraphCompiler::StackSize() const {
  return parsed_function_.stack_local_count() +
      parsed_function_.copied_parameter_count();
}


void FlowGraphCompiler::Bailout(const char* reason) {
  const char* kFormat = "FlowGraphCompiler Bailout: %s %s.";
  const char* function_name = parsed_function_.function().ToCString();
  intptr_t len = OS::SNPrint(NULL, 0, kFormat, function_name, reason) + 1;
  char* chars = reinterpret_cast<char*>(
      Isolate::Current()->current_zone()->Allocate(len));
  OS::SNPrint(chars, len, kFormat, function_name, reason);
  const Error& error = Error::Handle(
      LanguageError::New(String::Handle(String::New(chars))));
  Isolate::Current()->long_jump_base()->Jump(1, error);
}


static const Class* CoreClass(const char* c_name) {
  const String& class_name = String::Handle(String::NewSymbol(c_name));
  const Class& cls = Class::ZoneHandle(Library::Handle(
      Library::CoreImplLibrary()).LookupClass(class_name));
  ASSERT(!cls.IsNull());
  return &cls;
}


#define __ assembler_->


// Inputs:
// - RAX: object (preserved).
// - RDX: optional instantiator type arguments (preserved).
// Destroys RCX.
// Returns:
// - unchanged object in RAX and optional instantiator type arguments in RDX.
// Note that this inlined code must be followed by the runtime_call code, as it
// may fall through to it. Otherwise, this inline code will jump to the label
// is_instance or to the label is_not_instance.
void FlowGraphCompiler::GenerateInlineInstanceof(const AbstractType& type,
                                                 Label* is_instance,
                                                 Label* is_not_instance) {
  Label runtime_call;
  if (type.IsInstantiated()) {
    const Class& type_class = Class::ZoneHandle(type.type_class());
    const bool requires_type_arguments = type_class.HasTypeArguments();
    // A Smi object cannot be the instance of a parameterized class.
    // A class equality check is only applicable with a dst type of a
    // non-parameterized class or with a raw dst type of a parameterized class.
    if (requires_type_arguments) {
      const AbstractTypeArguments& type_arguments =
          AbstractTypeArguments::Handle(type.arguments());
      const bool is_raw_type = type_arguments.IsNull() ||
          type_arguments.IsRaw(type_arguments.Length());
      __ testq(RAX, Immediate(kSmiTagMask));
      __ j(ZERO, &runtime_call);
      // Object not Smi.
      if (is_raw_type) {
        // Dynamic type argument, check only classes.
        if (type.IsListInterface()) {
          // TODO(srdjan) also accept List<Object>.
          __ movq(RCX, FieldAddress(RAX, Object::class_offset()));
          __ CompareObject(RCX, *CoreClass("ObjectArray"));
          __ j(EQUAL, is_instance);
          __ CompareObject(RCX, *CoreClass("GrowableObjectArray"));
          __ j(EQUAL, is_instance);
        } else if (!type_class.is_interface()) {
          __ movq(RCX, FieldAddress(RAX, Object::class_offset()));
          __ CompareObject(RCX, type_class);
          __ j(EQUAL, is_instance);
        }
        // Fall through to runtime call.
      }
    } else {  // type has NO type arguments.
      Label compare_classes;
      __ testq(RAX, Immediate(kSmiTagMask));
      __ j(NOT_ZERO, &compare_classes);
      // Object is Smi.
      const Class& smi_class = Class::Handle(Smi::Class());
      // TODO(regis): We should introduce a SmiType.
      Error& malformed_error = Error::Handle();
      if (smi_class.IsSubtypeOf(TypeArguments::Handle(),
                                type_class,
                                TypeArguments::Handle(),
                                &malformed_error)) {
        // Successful assignable type check: return object in RAX.
        __ jmp(is_instance);
      } else {
        // Failed assignable type check: call runtime to throw TypeError.
        __ jmp(&runtime_call);
      }
      // Compare if the classes are equal.
      __ Bind(&compare_classes);
      // If type is an interface, we can skip the class equality check,
      // because instances cannot be of an interface type.
      if (!type_class.is_interface()) {
        __ LoadObject(RCX, type_class);
        __ movq(R10, FieldAddress(RAX, Object::class_offset()));
        __ cmpq(R10, RCX);
        __ j(EQUAL, is_instance);
        // RAX, RCX, and RDX are preserved in stub, result is in RBX.
        __ call(&StubCode::IsRawSubTypeLabel());
        // Result in RBX: 1 is raw subtype.
        __ cmpq(RBX, Immediate(1));
        __ j(EQUAL, is_instance);
          // Otherwise fall through to runtime call.
      } else {
        // However, for specific core library interfaces, we can check for
        // specific core library classes.
        Error& malformed_error = Error::Handle();
        if (type.IsBoolInterface()) {
          __ movq(RCX, FieldAddress(RAX, Object::class_offset()));
          const Class& bool_class = Class::ZoneHandle(
              Isolate::Current()->object_store()->bool_class());
          __ CompareObject(RCX, bool_class);
          __ j(EQUAL, is_instance);
        } else if (type.IsSubtypeOf(
              Type::Handle(Type::NumberInterface()), &malformed_error)) {
          __ movq(RCX, FieldAddress(RAX, Object::class_offset()));
          if (type.IsIntInterface() || type.IsNumberInterface()) {
            // We already checked for Smi above.
            const Class& mint_class = Class::ZoneHandle(
                Isolate::Current()->object_store()->mint_class());
            __ CompareObject(RCX, mint_class);
            __ j(EQUAL, is_instance);
            const Class& bigint_class = Class::ZoneHandle(
                Isolate::Current()->object_store()->bigint_class());
            __ CompareObject(RCX, bigint_class);
            __ j(EQUAL, is_instance);
          }
          if (type.IsDoubleInterface() || type.IsNumberInterface()) {
            const Class& double_class = Class::ZoneHandle(
                Isolate::Current()->object_store()->double_class());
            __ CompareObject(RCX, double_class);
            __ j(EQUAL, is_instance);
          }
        } else if (type.IsStringInterface()) {
          __ movq(RCX, FieldAddress(RAX, Object::class_offset()));
          const Class& one_byte_string_class = Class::ZoneHandle(
              Isolate::Current()->object_store()->one_byte_string_class());
          __ CompareObject(RCX, one_byte_string_class);
          __ j(EQUAL, is_instance);
          const Class& two_byte_string_class = Class::ZoneHandle(
              Isolate::Current()->object_store()->two_byte_string_class());
          __ CompareObject(RCX, two_byte_string_class);
          __ j(EQUAL, is_instance);
          const Class& four_byte_string_class = Class::ZoneHandle(
              Isolate::Current()->object_store()->four_byte_string_class());
          __ CompareObject(RCX, four_byte_string_class);
          __ j(EQUAL, is_instance);
        } else if (type.IsFunctionInterface()) {
          const Immediate raw_null =
              Immediate(reinterpret_cast<intptr_t>(Object::null()));
          __ movq(RCX, FieldAddress(RAX, Object::class_offset()));
          __ movq(RCX, FieldAddress(RCX, Class::signature_function_offset()));
          __ cmpq(RCX, raw_null);
          __ j(NOT_EQUAL, is_instance);
        } else {
          __ LoadObject(RCX, type_class);
          // RAX: Instance (preserved).
          // RCX: test class (preserved).
          // RDX: instantiator type arguments (preserved).
          __ call(&StubCode::IsRawSubTypeLabel());
          // Result in RBX: 1 is raw subtype.
          __ cmpq(RBX, Immediate(1));
          __ j(EQUAL, is_instance);
          // Otherwise fallthrough to runtime call.
        }
      }
    }
  } else {
    ASSERT(!type.IsInstantiated());
    // Skip check if destination is a dynamic type.
    if (type.IsTypeParameter()) {
      // Check if dynamic.
      const Immediate raw_null =
          Immediate(reinterpret_cast<intptr_t>(Object::null()));
      // Instantiator type arguments are in RDX.
      __ cmpq(RDX, raw_null);
      __ j(EQUAL, is_instance);

      // For now handle only TypeArguments and bail out if InstantiatedTypeArgs.
      __ movq(RCX, FieldAddress(RDX, Object::class_offset()));
      __ CompareObject(RCX, Object::ZoneHandle(Object::type_arguments_class()));
      __ j(NOT_EQUAL, &runtime_call);
      __ movq(RCX,
              FieldAddress(RDX, TypeArguments::type_at_offset(type.Index())));
      // RCX: instantiated type parameter.
      __ CompareObject(RCX, Type::ZoneHandle(Type::DynamicType()));
      __ j(EQUAL, is_instance);
      // Check if the type has type parameters, if not, do the class comparison.
      Label not_smi;
      __ testq(RAX, Immediate(kSmiTagMask));  // Value is Smi?
      __ j(NOT_ZERO, &not_smi, Assembler::kNearJump);
      __ CompareObject(RCX, Type::ZoneHandle(Type::IntInterface()));
      __ j(EQUAL, is_instance);
      __ CompareObject(RCX, Type::ZoneHandle(Type::NumberInterface()));
      __ j(EQUAL, is_instance);
      __ Bind(&not_smi);
      // The instantiated type parameter RCX may not be a Type, but could be an
      // InstantiatedType. It is therefore necessary to check its class.
      __ movq(R10, FieldAddress(RCX, Object::class_offset()));
      __ CompareObject(R10, Object::ZoneHandle(Object::type_class()));
      __ j(NOT_EQUAL, &runtime_call, Assembler::kNearJump);
      __ movq(RCX, FieldAddress(RCX, Type::type_class_offset()));
      __ movq(R10, FieldAddress(RCX, Class::type_parameters_offset()));
      // Check that class of type has no type parameters.
      __ cmpq(R10, raw_null);
      __ j(NOT_EQUAL, &runtime_call, Assembler::kNearJump);
      // We have a non-parameterized class in RCX, compare with class of
      // value in RAX. RAX, RCX, and RDX are preserved in stub.
      __ call(&StubCode::IsRawSubTypeLabel());
      // Result in EBX: 1 is raw subtype.
      __ cmpq(RBX, Immediate(1));
      __ j(EQUAL, is_instance);
      // Fall through to runtime call.
    }
  }
  __ Bind(&runtime_call);
}


// Optimize assignable type check by adding inlined tests for:
// - NULL -> return NULL.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs:
// - RAX: object.
// - RDX: optional instantiator type arguments.
// Destroys RCX and RDX.
// Returns:
// - object in RAX for successful assignable check (or throws TypeError).
// Performance notes: positive checks must be quick, negative checks can be slow
// as they throw an exception.
void FlowGraphCompiler::GenerateAssertAssignable(intptr_t node_id,
                                                 intptr_t token_index,
                                                 intptr_t try_index,
                                                 const AbstractType& dst_type,
                                                 const String& dst_name) {
  ASSERT(FLAG_enable_type_checks);
  ASSERT(token_index >= 0);
  ASSERT(!dst_type.IsNull());
  ASSERT(dst_type.IsFinalized());
  ASSERT(dst_type.IsMalformed() ||
         (!dst_type.IsDynamicType() && !dst_type.IsObjectType()));
  ASSERT(!dst_type.IsVoidType());

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
        String::NewSymbol(error.ToErrorCString()));
    __ PushObject(Object::ZoneHandle());  // Make room for the result.
    const Immediate location =
        Immediate(reinterpret_cast<int64_t>(Smi::New(token_index)));
    __ pushq(location);  // Push the source location.
    __ pushq(RAX);  // Push the source object.
    __ PushObject(dst_name);  // Push the name of the destination.
    __ PushObject(error_message);
    GenerateCallRuntime(node_id,
                        token_index,
                        try_index,
                        kMalformedTypeErrorRuntimeEntry);
    // We should never return here.
    __ int3();

    __ Bind(&is_assignable);  // For a null object.
    return;
  }

  // Generate inline type check, linking to runtime call if not assignable.
  GenerateInlineInstanceof(dst_type, &is_assignable, &runtime_call);

  __ Bind(&runtime_call);
  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  const Immediate location =
      Immediate(reinterpret_cast<int64_t>(Smi::New(token_index)));
  const Immediate node_id_as_smi =
      Immediate(reinterpret_cast<int64_t>(Smi::New(node_id)));
  __ pushq(location);  // Push the source location.
  __ pushq(node_id_as_smi);  // node-id.
  __ pushq(RAX);  // Push the source object.
  __ PushObject(dst_type);  // Push the type of the destination.
  if (!dst_type.IsInstantiated()) {
    __ pushq(RDX);  // Instantiator type arguments.
  } else {
    __ pushq(raw_null);  // Null instantiator.
  }
  __ PushObject(dst_name);  // Push the name of the destination.
  GenerateCallRuntime(node_id,
                      token_index,
                      try_index,
                      kTypeCheckRuntimeEntry);
  // Pop the parameters supplied to the runtime entry. The result of the
  // type check runtime call is the checked value.
  __ addq(RSP, Immediate(6 * kWordSize));
  __ popq(RAX);

  __ Bind(&is_assignable);
}


void FlowGraphCompiler::LoadValue(Register dst, Value* value) {
  if (value->IsConstant()) {
    ConstantVal* constant = value->AsConstant();
    if (constant->value().IsSmi()) {
      int64_t imm = reinterpret_cast<int64_t>(constant->value().raw());
      __ movq(dst, Immediate(imm));
    } else {
      __ LoadObject(dst, value->AsConstant()->value());
    }
  } else {
    ASSERT(value->IsTemp());
    __ popq(dst);
  }
}


void FlowGraphCompiler::VisitTemp(TempVal* val) {
  LoadValue(RAX, val);
}


void FlowGraphCompiler::VisitConstant(ConstantVal* val) {
  LoadValue(RAX, val);
}


void FlowGraphCompiler::VisitAssertAssignable(AssertAssignableComp* comp) {
  if (comp->instantiator_type_arguments() != NULL) {
    __ popq(RDX);
  }
  LoadValue(RAX, comp->value());
  GenerateAssertAssignable(comp->node_id(),
                           comp->token_index(),
                           comp->try_index(),
                           comp->dst_type(),
                           comp->dst_name());
}


void FlowGraphCompiler::VisitAssertBoolean(AssertBooleanComp* comp) {
  LoadValue(RAX, comp->value());
  // Check that the type of the value is allowed in conditional context.
  // Call the runtime if the object is not bool::true or bool::false.
  Label done;
  __ CompareObject(RAX, Bool::ZoneHandle(Bool::True()));
  __ j(EQUAL, &done, Assembler::kNearJump);
  __ CompareObject(RAX, Bool::ZoneHandle(Bool::False()));
  __ j(EQUAL, &done, Assembler::kNearJump);

  const Immediate location =
      Immediate(reinterpret_cast<int64_t>(Smi::New(comp->token_index())));
  __ pushq(location);  // Push the source location.
  __ pushq(RAX);  // Push the source object.
  GenerateCallRuntime(comp->node_id(),
                      comp->token_index(),
                      comp->try_index(),
                      kConditionTypeErrorRuntimeEntry);
  // We should never return here.
  __ int3();

  __ Bind(&done);
}


// True iff. the arguments to a call will be properly pushed and can
// be popped after the call.
template <typename T> static bool VerifyCallComputation(T* comp) {
  // Argument values should be consecutive temps.
  //
  // TODO(kmillikin): implement stack height tracking so we can also assert
  // they are on top of the stack.
  intptr_t previous = -1;
  for (int i = 0; i < comp->ArgumentCount(); ++i) {
    TempVal* temp = comp->ArgumentAt(i)->AsTemp();
    if (temp == NULL) return false;
    if (i != 0) {
      if (temp->index() != previous + 1) return false;
    }
    previous = temp->index();
  }
  return true;
}


// Truee iff. the v2 is above v1 on stack, or one of them is constant.
static bool VerifyValues(Value* v1, Value* v2) {
  if (v1->IsTemp() && v2->IsTemp()) {
    return (v1->AsTemp()->index() + 1) == v2->AsTemp()->index();
  }
  return true;
}


void FlowGraphCompiler::EmitInstanceCall(intptr_t node_id,
                                         intptr_t token_index,
                                         intptr_t try_index,
                                         const String& function_name,
                                         intptr_t argument_count,
                                         const Array& argument_names,
                                         intptr_t checked_argument_count) {
  ICData& ic_data =
      ICData::ZoneHandle(ICData::New(parsed_function_.function(),
                                     function_name,
                                     node_id,
                                     checked_argument_count));
  const Array& arguments_descriptor =
      CodeGenerator::ArgumentsDescriptor(argument_count, argument_names);
  __ LoadObject(RBX, ic_data);
  __ LoadObject(R10, arguments_descriptor);

  uword label_address = 0;
  switch (checked_argument_count) {
    case 1:
      label_address = StubCode::OneArgCheckInlineCacheEntryPoint();
      break;
    case 2:
      label_address = StubCode::TwoArgsCheckInlineCacheEntryPoint();
      break;
    default:
      UNIMPLEMENTED();
  }
  ExternalLabel target_label("InlineCache", label_address);
  __ call(&target_label);
  AddCurrentDescriptor(PcDescriptors::kIcCall, node_id, token_index, try_index);
  __ addq(RSP, Immediate(argument_count * kWordSize));
}


void FlowGraphCompiler::EmitStaticCall(intptr_t token_index,
                                       intptr_t try_index,
                                       const Function& function,
                                       intptr_t argument_count,
                                       const Array& argument_names) {
  const Array& arguments_descriptor =
      CodeGenerator::ArgumentsDescriptor(argument_count, argument_names);
  __ LoadObject(RBX, function);
  __ LoadObject(R10, arguments_descriptor);

  GenerateCall(token_index,
               try_index,
               &StubCode::CallStaticFunctionLabel(),
               PcDescriptors::kFuncCall);
  __ addq(RSP, Immediate(argument_count * kWordSize));
}


void FlowGraphCompiler::VisitCurrentContext(CurrentContextComp* comp) {
  __ movq(RAX, CTX);
}


void FlowGraphCompiler::VisitStoreContext(StoreContextComp* comp) {
  LoadValue(CTX, comp->value());
}


void FlowGraphCompiler::VisitClosureCall(ClosureCallComp* comp) {
  ASSERT(comp->context()->IsTemp());
  ASSERT(VerifyCallComputation(comp));
  // The arguments to the stub include the closure.  The arguments
  // descriptor describes the closure's arguments (and so does not include
  // the closure).
  int argument_count = comp->ArgumentCount();
  const Array& arguments_descriptor =
      CodeGenerator::ArgumentsDescriptor(argument_count - 1,
                                         comp->argument_names());
  __ LoadObject(R10, arguments_descriptor);

  GenerateCall(comp->token_index(),
               comp->try_index(),
               &StubCode::CallClosureFunctionLabel(),
               PcDescriptors::kOther);
  __ addq(RSP, Immediate(argument_count * kWordSize));
  __ popq(CTX);
}


void FlowGraphCompiler::VisitInstanceCall(InstanceCallComp* comp) {
  ASSERT(VerifyCallComputation(comp));
  EmitInstanceCall(comp->node_id(),
                   comp->token_index(),
                   comp->try_index(),
                   comp->function_name(),
                   comp->ArgumentCount(),
                   comp->argument_names(),
                   comp->checked_argument_count());
}


void FlowGraphCompiler::VisitStrictCompare(StrictCompareComp* comp) {
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());
  LoadValue(RDX, comp->right());
  LoadValue(RAX, comp->left());
  __ cmpq(RAX, RDX);
  Label load_true, done;
  if (comp->kind() == Token::kEQ_STRICT) {
    __ j(EQUAL, &load_true, Assembler::kNearJump);
  } else {
    __ j(NOT_EQUAL, &load_true, Assembler::kNearJump);
  }
  __ LoadObject(RAX, bool_false);
  __ jmp(&done, Assembler::kNearJump);
  __ Bind(&load_true);
  __ LoadObject(RAX, bool_true);
  __ Bind(&done);
}


void FlowGraphCompiler::VisitEqualityCompare(EqualityCompareComp* comp) {
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label done, load_true, non_null_compare;
  LoadValue(RDX, comp->right());
  LoadValue(RAX, comp->left());
  __ cmpq(RAX, raw_null);
  __ j(NOT_EQUAL, &non_null_compare, Assembler::kNearJump);
  // Comparison with NULL is "===".
  __ cmpq(RAX, RDX);
  __ j(EQUAL, &load_true, Assembler::kNearJump);
  __ LoadObject(RAX, bool_false);
  __ jmp(&done, Assembler::kNearJump);
  __ Bind(&load_true);
  __ LoadObject(RAX, bool_true);
  __ jmp(&done);

  __ Bind(&non_null_compare);
  __ pushq(RAX);
  __ pushq(RDX);
  const String& operator_name = String::ZoneHandle(String::NewSymbol("=="));
  const int kNumberOfArguments = 2;
  const Array& kNoArgumentNames = Array::Handle();
  const int kNumArgumentsChecked = 1;

  EmitInstanceCall(comp->node_id(),
                   comp->token_index(),
                   comp->try_index(),
                   operator_name,
                   kNumberOfArguments,
                   kNoArgumentNames,
                   kNumArgumentsChecked);
  __ Bind(&done);
}


void FlowGraphCompiler::VisitStaticCall(StaticCallComp* comp) {
  ASSERT(VerifyCallComputation(comp));
  EmitStaticCall(comp->token_index(),
                 comp->try_index(),
                 comp->function(),
                 comp->ArgumentCount(),
                 comp->argument_names());
}


void FlowGraphCompiler::VisitLoadLocal(LoadLocalComp* comp) {
  if (comp->local().is_captured()) {
    // The variable lives in the context.
    intptr_t delta = comp->context_level() -
                     comp->local().owner()->context_level();
    ASSERT(delta >= 0);
    Register base = CTX;
    while (delta-- > 0) {
      __ movq(RAX, FieldAddress(base, Context::parent_offset()));
      base = RAX;
    }
    __ movq(RAX,
            FieldAddress(base,
                         Context::variable_offset(comp->local().index())));
  } else {
    // The variable lives in the current stack frame.
    __ movq(RAX, Address(RBP, comp->local().index() * kWordSize));
  }
}


void FlowGraphCompiler::VisitStoreLocal(StoreLocalComp* comp) {
  LoadValue(RAX, comp->value());
  if (comp->local().is_captured()) {
    // The variable lives in the context.
    Register scratch = R10;
    intptr_t delta = comp->context_level() -
                     comp->local().owner()->context_level();
    ASSERT(delta >= 0);
    Register base = CTX;
    while (delta-- > 0) {
      __ movq(scratch, FieldAddress(base, Context::parent_offset()));
      base = scratch;
    }
    __ StoreIntoObject(
        base,
        FieldAddress(base, Context::variable_offset(comp->local().index())),
        RAX);
  } else {
    // The variable lives in the current stack frame.
    __ movq(Address(RBP, comp->local().index() * kWordSize), RAX);
  }
}


void FlowGraphCompiler::VisitNativeCall(NativeCallComp* comp) {
  // Push the result place holder initialized to NULL.
  __ PushObject(Object::ZoneHandle());
  // Pass a pointer to the first argument in RAX.
  if (!comp->has_optional_parameters()) {
    __ leaq(RAX, Address(RBP, (1 + comp->argument_count()) * kWordSize));
  } else {
    __ leaq(RAX, Address(RBP, -1 * kWordSize));
  }
  __ movq(RBX, Immediate(reinterpret_cast<uword>(comp->native_c_function())));
  __ movq(R10, Immediate(comp->argument_count()));
  GenerateCall(comp->token_index(),
               comp->try_index(),
               &StubCode::CallNativeCFunctionLabel(),
               PcDescriptors::kOther);
  __ popq(RAX);
}


void FlowGraphCompiler::VisitLoadInstanceField(LoadInstanceFieldComp* comp) {
  LoadValue(RAX, comp->instance());
  __ movq(RAX, FieldAddress(RAX, comp->field().Offset()));
}


void FlowGraphCompiler::VisitStoreInstanceField(StoreInstanceFieldComp* comp) {
  VerifyValues(comp->instance(), comp->value());
  LoadValue(RDX, comp->value());
  LoadValue(RAX, comp->instance());
  __ StoreIntoObject(RAX, FieldAddress(RAX, comp->field().Offset()), RDX);
}



void FlowGraphCompiler::VisitLoadStaticField(LoadStaticFieldComp* comp) {
  __ LoadObject(RDX, comp->field());
  __ movq(RAX, FieldAddress(RDX, Field::value_offset()));
}


void FlowGraphCompiler::VisitStoreStaticField(StoreStaticFieldComp* comp) {
  LoadValue(RAX, comp->value());
  __ LoadObject(RDX, comp->field());
  __ StoreIntoObject(RDX, FieldAddress(RDX, Field::value_offset()), RAX);
}


void FlowGraphCompiler::VisitStoreIndexed(StoreIndexedComp* comp) {
  // Call operator []= but preserve the third argument value under the
  // arguments as the result of the computation.
  const String& function_name =
      String::ZoneHandle(String::NewSymbol(Token::Str(Token::kASSIGN_INDEX)));

  // Insert a copy of the third (last) argument under the arguments.
  __ popq(RAX);  // Value.
  __ popq(RBX);  // Index.
  __ popq(RCX);  // Receiver.
  __ pushq(RAX);
  __ pushq(RCX);
  __ pushq(RBX);
  __ pushq(RAX);
  EmitInstanceCall(comp->node_id(),
                   comp->token_index(),
                   comp->try_index(),
                   function_name,
                   3,
                   Array::ZoneHandle(),
                   1);
  __ popq(RAX);
}


void FlowGraphCompiler::VisitInstanceSetter(InstanceSetterComp* comp) {
  // Preserve the second argument under the arguments as the result of the
  // computation, then call the setter.
  const String& function_name =
      String::ZoneHandle(Field::SetterSymbol(comp->field_name()));

  // Insert a copy of the second (last) argument under the arguments.
  __ popq(RAX);  // Value.
  __ popq(RBX);  // Receiver.
  __ pushq(RAX);
  __ pushq(RBX);
  __ pushq(RAX);
  EmitInstanceCall(comp->node_id(),
                   comp->token_index(),
                   comp->try_index(),
                   function_name,
                   2,
                   Array::ZoneHandle(),
                   1);
  __ popq(RAX);
}


void FlowGraphCompiler::VisitStaticSetter(StaticSetterComp* comp) {
  // Preserve the argument as the result of the computation,
  // then call the setter.

  // Duplicate the argument.
  __ movq(RAX, Address(RSP, 0));
  __ pushq(RAX);
  EmitStaticCall(comp->token_index(),
                 comp->try_index(),
                 comp->setter_function(),
                 1,
                 Array::ZoneHandle());
  __ popq(RAX);
}


void FlowGraphCompiler::VisitBooleanNegate(BooleanNegateComp* comp) {
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());
  Label done;
  LoadValue(RDX, comp->value());
  __ LoadObject(RAX, bool_true);
  __ cmpq(RAX, RDX);
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  __ LoadObject(RAX, bool_false);
  __ Bind(&done);
}


// Optimize instanceof type test by adding inlined tests for:
// - NULL -> return false.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs:
// - RAX: object.
// - RDX: optional instantiator type arguments.
// Destroys RCX and RDX.
// Returns:
// - true or false in RAX.
void FlowGraphCompiler::GenerateInstanceOf(intptr_t node_id,
                                           intptr_t token_index,
                                           intptr_t try_index,
                                           const AbstractType& type,
                                           bool negate_result) {
  ASSERT(type.IsFinalized() && !type.IsMalformed());
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());

  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label is_instance, is_not_instance;
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
    __ cmpq(RAX, raw_null);
    __ j(EQUAL, &is_not_instance);
  }

  // Generate inline instanceof test.
  GenerateInlineInstanceof(type, &is_instance, &is_not_instance);

  // Generate runtime call.
  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  const Immediate location =
      Immediate(reinterpret_cast<int64_t>(Smi::New(token_index)));
  const Immediate node_id_as_smi =
      Immediate(reinterpret_cast<int64_t>(Smi::New(node_id)));
  __ pushq(location);  // Push the source location.
  __ pushq(node_id_as_smi);
  __ pushq(RAX);  // Push the instance.
  __ PushObject(type);  // Push the type.
  if (!type.IsInstantiated()) {
    __ pushq(RDX);  // Instantiator type arguments.
  } else {
    __ pushq(raw_null);  // Null instantiator.
  }
  GenerateCallRuntime(node_id, token_index, try_index, kInstanceofRuntimeEntry);
  // Pop the two parameters supplied to the runtime entry. The result of the
  // instanceof runtime call will be left as the result of the operation.
  __ addq(RSP, Immediate(5 * kWordSize));
  Label done;
  if (negate_result) {
    __ popq(RDX);
    __ LoadObject(RAX, bool_true);
    __ cmpq(RDX, RAX);
    __ j(NOT_EQUAL, &done, Assembler::kNearJump);
    __ LoadObject(RAX, bool_false);
  } else {
    __ popq(RAX);
  }
  __ jmp(&done, Assembler::kNearJump);

  __ Bind(&is_not_instance);
  __ LoadObject(RAX, negate_result ? bool_true : bool_false);
  __ jmp(&done, Assembler::kNearJump);

  __ Bind(&is_instance);
  __ LoadObject(RAX, negate_result ? bool_false : bool_true);
  __ Bind(&done);
}


void FlowGraphCompiler::VisitInstanceOf(InstanceOfComp* comp) {
  if (comp->type_arguments() != NULL) {
    __ popq(RDX);
  }
  LoadValue(RAX, comp->value());
  GenerateInstanceOf(comp->node_id(),
                     comp->token_index(),
                     comp->try_index(),
                     comp->type(),
                     comp->negate_result());
}


void FlowGraphCompiler::VisitAllocateObject(AllocateObjectComp* comp) {
  const Class& cls = Class::ZoneHandle(comp->constructor().owner());
  const Code& stub = Code::Handle(StubCode::GetAllocationStubForClass(cls));
  const ExternalLabel label(cls.ToCString(), stub.EntryPoint());
  GenerateCall(comp->token_index(), comp->try_index(), &label,
               PcDescriptors::kOther);
  for (intptr_t i = 0; i < comp->arguments().length(); i++) {
    __ popq(RCX);  // Discard allocation argument
  }
}


void FlowGraphCompiler::VisitCreateArray(CreateArrayComp* comp) {
  // 1. Allocate the array.  R10 = length, RBX = element type.
  __ movq(R10, Immediate(Smi::RawValue(comp->ElementCount())));
  const AbstractTypeArguments& element_type = comp->type_arguments();
  ASSERT(element_type.IsNull() || element_type.IsInstantiated());
  __ LoadObject(RBX, element_type);
  GenerateCall(comp->token_index(),
               comp->try_index(),
               &StubCode::AllocateArrayLabel(),
               PcDescriptors::kOther);

  // 2. Initialize the array in RAX with the element values.
  __ leaq(RCX, FieldAddress(RAX, Array::data_offset()));
  for (int i = comp->ElementCount() - 1; i >= 0; --i) {
    if (comp->ElementAt(i)->IsTemp()) {
      __ popq(Address(RCX, i * kWordSize));
    } else {
      LoadValue(RDX, comp->ElementAt(i));
      __ movq(Address(RCX, i * kWordSize), RDX);
    }
  }
}


void FlowGraphCompiler::VisitCreateClosure(CreateClosureComp* comp) {
  const Function& function = comp->function();
  const Code& stub = Code::Handle(
      StubCode::GetAllocationStubForClosure(function));
  const ExternalLabel label(function.ToCString(), stub.EntryPoint());
  GenerateCall(comp->token_index(), comp->try_index(), &label,
               PcDescriptors::kOther);

  const Class& cls = Class::Handle(function.signature_class());
  if (cls.HasTypeArguments()) {
    __ popq(RCX);  // Discard type arguments.
  }
  if (function.IsImplicitInstanceClosureFunction()) {
    __ popq(RCX);  // Discard receiver.
  }
}


void FlowGraphCompiler::VisitNativeLoadField(NativeLoadFieldComp* comp) {
  __ popq(RAX);
  __ movq(RAX, FieldAddress(RAX, comp->offset_in_bytes()));
}


void FlowGraphCompiler::VisitExtractFactoryTypeArguments(
    ExtractFactoryTypeArgumentsComp* comp) {
  __ popq(RAX);  // Instantiator.

  // RAX is the instantiator AbstractTypeArguments object (or null).
  // If the instantiator is null and if the type argument vector
  // instantiated from null becomes a vector of Dynamic, then use null as
  // the type arguments.
  Label type_arguments_instantiated;
  const intptr_t len = comp->type_arguments().Length();
  if (comp->type_arguments().IsRawInstantiatedRaw(len)) {
    const Immediate raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ cmpq(RAX, raw_null);
    __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);
  }
  // Instantiate non-null type arguments.
  if (comp->type_arguments().IsUninstantiatedIdentity()) {
    Label type_arguments_uninstantiated;
    // Check if the instantiator type argument vector is a TypeArguments of a
    // matching length and, if so, use it as the instantiated type_arguments.
    // No need to check the instantiator (RAX) for null here, because a null
    // instantiator will have the wrong class (Null instead of TypeArguments).
    __ LoadObject(RCX, Class::ZoneHandle(Object::type_arguments_class()));
    __ cmpq(RCX, FieldAddress(RAX, Object::class_offset()));
    __ j(NOT_EQUAL, &type_arguments_uninstantiated, Assembler::kNearJump);
    Immediate arguments_length = Immediate(reinterpret_cast<int64_t>(
        Smi::New(comp->type_arguments().Length())));
    __ cmpq(FieldAddress(RAX, TypeArguments::length_offset()),
        arguments_length);
    __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);
    __ Bind(&type_arguments_uninstantiated);
  }
  // A runtime call to instantiate the type arguments is required before
  // calling the factory.
  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  __ PushObject(comp->type_arguments());
  __ pushq(RAX);  // Push instantiator type arguments.
  GenerateCallRuntime(comp->node_id(),
                      comp->token_index(),
                      comp->try_index(),
                      kInstantiateTypeArgumentsRuntimeEntry);
  __ popq(RAX);  // Pop instantiator type arguments.
  __ popq(RAX);  // Pop uninstantiated type arguments.
  __ popq(RAX);  // Pop instantiated type arguments.
  __ Bind(&type_arguments_instantiated);
  // RAX: Instantiated type arguments.
}


void FlowGraphCompiler::VisitExtractConstructorTypeArguments(
    ExtractConstructorTypeArgumentsComp* comp) {
  __ popq(RAX);  // Instantiator.

  // RAX is the instantiator AbstractTypeArguments object (or null).
  // If the instantiator is null and if the type argument vector
  // instantiated from null becomes a vector of Dynamic, then use null as
  // the type arguments.
  Label type_arguments_instantiated;
  const intptr_t len = comp->type_arguments().Length();
  if (comp->type_arguments().IsRawInstantiatedRaw(len)) {
    const Immediate raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ cmpq(RAX, raw_null);
    __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);
  }
  // Instantiate non-null type arguments.
  if (comp->type_arguments().IsUninstantiatedIdentity()) {
    // Check if the instantiator type argument vector is a TypeArguments of a
    // matching length and, if so, use it as the instantiated type_arguments.
    // No need to check the instantiator (RAX) for null here, because a null
    // instantiator will have the wrong class (Null instead of TypeArguments).
    Label type_arguments_uninstantiated;
    __ LoadObject(RCX, Class::ZoneHandle(Object::type_arguments_class()));
    __ cmpq(RCX, FieldAddress(RAX, Object::class_offset()));
    __ j(NOT_EQUAL, &type_arguments_uninstantiated, Assembler::kNearJump);
    Immediate arguments_length = Immediate(reinterpret_cast<int64_t>(
        Smi::New(comp->type_arguments().Length())));
    __ cmpq(FieldAddress(RAX, TypeArguments::length_offset()),
        arguments_length);
    __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);
    __ Bind(&type_arguments_uninstantiated);
  }
  // In the non-factory case, we rely on the allocation stub to
  // instantiate the type arguments.
  __ LoadObject(RAX, comp->type_arguments());
  // RAX: uninstantiated type arguments.
  __ Bind(&type_arguments_instantiated);
  // RAX: uninstantiated or instantiated type arguments.
}


void FlowGraphCompiler::VisitExtractConstructorInstantiator(
    ExtractConstructorInstantiatorComp* comp) {
  __ popq(RCX);  // Discard value.
  __ popq(RAX);  // Instantiator.

  // RAX is the instantiator AbstractTypeArguments object (or null).
  // If the instantiator is null and if the type argument vector
  // instantiated from null becomes a vector of Dynamic, then use null as
  // the type arguments and do not pass the instantiator.
  Label done;
  const intptr_t len = comp->type_arguments().Length();
  if (comp->type_arguments().IsRawInstantiatedRaw(len)) {
    const Immediate raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    Label instantiator_not_null;
    __ cmpq(RAX, raw_null);
    __ j(NOT_EQUAL, &instantiator_not_null, Assembler::kNearJump);
    // Null was used in VisitExtractConstructorTypeArguments as the
    // instantiated type arguments, no proper instantiator needed.
    __ movq(RAX, Immediate(Smi::RawValue(StubCode::kNoInstantiator)));
    __ jmp(&done);
    __ Bind(&instantiator_not_null);
  }
  // Instantiate non-null type arguments.
  if (comp->type_arguments().IsUninstantiatedIdentity()) {
    // TODO(regis): The following emitted code is duplicated in
    // VisitExtractConstructorTypeArguments above. The reason is that the code
    // is split between two computations, so that each one produces a
    // single value, rather than producing a pair of values.
    // If this becomes an issue, we should expose these tests at the IL level.
    // TODO(regis): This code will still change, because bounds checking is not
    // implemented yet.

    // Check if the instantiator type argument vector is a TypeArguments of a
    // matching length and, if so, use it as the instantiated type_arguments.
    // No need to check the instantiator (RAX) for null here, because a null
    // instantiator will have the wrong class (Null instead of TypeArguments).
    __ LoadObject(RCX, Class::ZoneHandle(Object::type_arguments_class()));
    __ cmpq(RCX, FieldAddress(RAX, Object::class_offset()));
    __ j(NOT_EQUAL, &done, Assembler::kNearJump);
    Immediate arguments_length = Immediate(reinterpret_cast<int64_t>(
        Smi::New(comp->type_arguments().Length())));
    __ cmpq(FieldAddress(RAX, TypeArguments::length_offset()),
        arguments_length);
    __ j(NOT_EQUAL, &done, Assembler::kNearJump);
    // The instantiator was used in VisitExtractConstructorTypeArguments as the
    // instantiated type arguments, no proper instantiator needed.
    __ movq(RAX, Immediate(Smi::RawValue(StubCode::kNoInstantiator)));
  }
  __ Bind(&done);
  // RAX: instantiator or kNoInstantiator.
}


void FlowGraphCompiler::VisitAllocateContext(AllocateContextComp* comp) {
  __ movq(R10, Immediate(comp->num_context_variables()));
  const ExternalLabel label("alloc_context",
                            StubCode::AllocateContextEntryPoint());
  GenerateCall(comp->token_index(), comp->try_index(), &label,
               PcDescriptors::kOther);
}


void FlowGraphCompiler::VisitChainContext(ChainContextComp* comp) {
  __ popq(RAX);
  // Chain the new context in RAX to its parent in CTX.
  __ StoreIntoObject(RAX,
                     FieldAddress(RAX, Context::parent_offset()),
                     CTX);
  // Set new context as current context.
  __ movq(CTX, RAX);
}


void FlowGraphCompiler::VisitCloneContext(CloneContextComp* comp) {
  __ popq(RAX);  // Get context value from stack.
  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  __ pushq(RAX);
  GenerateCallRuntime(comp->node_id(),
                      comp->token_index(),
                      comp->try_index(),
                      kCloneContextRuntimeEntry);
  __ popq(RAX);  // Remove argument.
  __ popq(RAX);  // Get result (cloned context).
}


// Restore stack and initialize the two exception variables:
// exception and stack trace variables.
void FlowGraphCompiler::VisitCatchEntry(CatchEntryComp* comp) {
  // Restore RSP from RBP as we are coming from a throw and the code for
  // popping arguments has not been run.
  const intptr_t locals_space_size = StackSize() * kWordSize;
  ASSERT(locals_space_size >= 0);
  __ movq(RSP, RBP);
  __ subq(RSP, Immediate(locals_space_size));

  ASSERT(!comp->exception_var().is_captured());
  ASSERT(!comp->stacktrace_var().is_captured());
  __ movq(Address(RBP, comp->exception_var().index() * kWordSize),
          kExceptionObjectReg);
  __ movq(Address(RBP, comp->stacktrace_var().index() * kWordSize),
          kStackTraceObjectReg);
}


void FlowGraphCompiler::VisitBlocks() {
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    // Compile the block entry.
    current_block_ = block_order_[i];
    Instruction* instr = current_block()->Accept(this);
    // Compile all successors until an exit, branch, or a block entry.
    while ((instr != NULL) && !instr->IsBlockEntry()) {
      instr = instr->Accept(this);
    }

    BlockEntryInstr* successor =
        (instr == NULL) ? NULL : instr->AsBlockEntry();
    if (successor != NULL) {
      // Block ended with a "goto".  We can fall through if it is the
      // next block in the list.  Otherwise, we need a jump.
      if ((i == block_order_.length() - 1) ||
          (block_order_[i + 1] != successor)) {
        __ jmp(&block_info_[successor->postorder_number()]->label);
      }
    }
  }
}


void FlowGraphCompiler::VisitJoinEntry(JoinEntryInstr* instr) {
  __ Bind(&block_info_[instr->postorder_number()]->label);
}


void FlowGraphCompiler::VisitTargetEntry(TargetEntryInstr* instr) {
  __ Bind(&block_info_[instr->postorder_number()]->label);
  if (instr->HasTryIndex()) {
    exception_handlers_list_->AddHandler(instr->try_index(),
                                         assembler_->CodeSize());
  }
}


void FlowGraphCompiler::VisitPickTemp(PickTempInstr* instr) {
  // Semantics is to copy a stack-allocated temporary to the top of stack.
  // Destination index d is assumed the new top of stack after the
  // operation, so d-1 is the current top of stack and so d-s-1 is the
  // offset to source index s.
  intptr_t offset = instr->destination() - instr->source() - 1;
  ASSERT(offset >= 0);
  __ pushq(Address(RSP, offset * kWordSize));
}


void FlowGraphCompiler::VisitTuckTemp(TuckTempInstr* instr) {
  // Semantics is to assign to a stack-allocated temporary a copy of the top
  // of stack.  Source index s is assumed the top of stack, s-d is the
  // offset to destination index d.
  intptr_t offset = instr->source() - instr->destination();
  ASSERT(offset >= 0);
  __ movq(RAX, Address(RSP, 0));
  __ movq(Address(RSP, offset * kWordSize), RAX);
}


void FlowGraphCompiler::VisitDo(DoInstr* instr) {
  instr->computation()->Accept(this);
}


void FlowGraphCompiler::VisitBind(BindInstr* instr) {
  instr->computation()->Accept(this);
  __ pushq(RAX);
}


void FlowGraphCompiler::VisitReturn(ReturnInstr* instr) {
  LoadValue(RAX, instr->value());

#ifdef DEBUG
  // Check that the entry stack size matches the exit stack size.
  __ movq(R10, RBP);
  __ subq(R10, RSP);
  __ cmpq(R10, Immediate(StackSize() * kWordSize));
  Label stack_ok;
  __ j(EQUAL, &stack_ok, Assembler::kNearJump);
  __ Stop("Exit stack size does not match the entry stack size.");
  __ Bind(&stack_ok);
#endif  // DEBUG.

  if (FLAG_trace_functions) {
    __ pushq(RAX);  // Preserve result.
    const Function& function =
        Function::ZoneHandle(parsed_function_.function().raw());
    __ LoadObject(RBX, function);
    __ pushq(RBX);
    GenerateCallRuntime(AstNode::kNoId,
                        0,
                        CatchClauseNode::kInvalidTryIndex,
                        kTraceFunctionExitRuntimeEntry);
    __ popq(RAX);  // Remove argument.
    __ popq(RAX);  // Restore result.
  }
  __ LeaveFrame();
  __ ret();

  // Generate 8 bytes of NOPs so that the debugger can patch the
  // return pattern with a call to the debug stub.
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  AddCurrentDescriptor(PcDescriptors::kReturn,
                       instr->node_id(),
                       instr->token_index(),
                       CatchClauseNode::kInvalidTryIndex);  // try-index.
}


void FlowGraphCompiler::VisitThrow(ThrowInstr* instr) {
  LoadValue(RAX, instr->exception());
  __ pushq(RAX);
  GenerateCallRuntime(instr->node_id(),
                      instr->token_index(),
                      instr->try_index(),
                      kThrowRuntimeEntry);
  __ int3();
}


void FlowGraphCompiler::VisitReThrow(ReThrowInstr* instr) {
  LoadValue(RAX, instr->exception());
  __ pushq(RAX);
  LoadValue(RAX, instr->stack_trace());
  __ pushq(RAX);
  GenerateCallRuntime(instr->node_id(),
                      instr->token_index(),
                      instr->try_index(),
                      kReThrowRuntimeEntry);
  __ int3();
}



void FlowGraphCompiler::VisitBranch(BranchInstr* instr) {
  // Determine if the true branch is fall through (!negated) or the false
  // branch is.  They cannot both be backwards branches.
  intptr_t index = reverse_index(current_block()->postorder_number());
  bool negated = (block_order_[index + 1] == instr->false_successor());
  ASSERT(!negated == (block_order_[index + 1] == instr->true_successor()));

  LoadValue(RAX, instr->value());
  __ LoadObject(RDX, Bool::ZoneHandle(Bool::True()));
  __ cmpq(RAX, RDX);
  if (negated) {
    intptr_t target_index = instr->true_successor()->postorder_number();
    __ j(EQUAL, &block_info_[target_index]->label);
  } else {
    intptr_t target_index = instr->false_successor()->postorder_number();
    __ j(NOT_EQUAL, &block_info_[target_index]->label);
  }
}


// Coped from CodeGenerator::CopyParameters (CodeGenerator will be deprecated).
void FlowGraphCompiler::CopyParameters() {
  const Function& function = parsed_function_.function();
  LocalScope* scope = parsed_function_.node_sequence()->scope();
  const int num_fixed_params = function.num_fixed_parameters();
  const int num_opt_params = function.num_optional_parameters();
  ASSERT(parsed_function_.first_parameter_index() == -1);
  // Copy positional arguments.
  // Check that no fewer than num_fixed_params positional arguments are passed
  // in and that no more than num_params arguments are passed in.
  // Passed argument i at fp[1 + argc - i] copied to fp[-1 - i].
  const int num_params = num_fixed_params + num_opt_params;

  // Total number of args is the first Smi in args descriptor array (R10).
  __ movq(RBX, FieldAddress(R10, Array::data_offset()));
  // Check that num_args <= num_params.
  Label wrong_num_arguments;
  __ cmpq(RBX, Immediate(Smi::RawValue(num_params)));
  __ j(GREATER, &wrong_num_arguments);
  // Number of positional args is the second Smi in descriptor array (R10).
  __ movq(RCX, FieldAddress(R10, Array::data_offset() + (1 * kWordSize)));
  // Check that num_pos_args >= num_fixed_params.
  __ cmpq(RCX, Immediate(Smi::RawValue(num_fixed_params)));
  __ j(LESS, &wrong_num_arguments);
  // Since RBX and RCX are Smi, use TIMES_4 instead of TIMES_8.
  // Let RBX point to the last passed positional argument, i.e. to
  // fp[1 + num_args - (num_pos_args - 1)].
  __ subq(RBX, RCX);
  __ leaq(RBX, Address(RBP, RBX, TIMES_4, 2 * kWordSize));
  // Let RDI point to the last copied positional argument, i.e. to
  // fp[-1 - (num_pos_args - 1)].
  __ SmiUntag(RCX);
  __ movq(RAX, RCX);
  __ negq(RAX);
  __ leaq(RDI, Address(RBP, RAX, TIMES_8, 0));
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
  ASSERT(num_opt_params > 0);  // Or we would not have to copy arguments.
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
  // Total number of args is the first Smi in args descriptor array (R10).
  __ movq(RBX, FieldAddress(R10, Array::data_offset()));
  // Number of positional args is the second Smi in descriptor array (R10).
  __ movq(RCX, FieldAddress(R10, Array::data_offset() + (1 * kWordSize)));
  __ SmiUntag(RCX);
  // Let RBX point to the first passed argument, i.e. to fp[1 + argc - 0].
  __ leaq(RBX, Address(RBP, RBX, TIMES_4, kWordSize));  // RBX is Smi.
  // Let EDI point to the name/pos pair of the first named argument.
  __ leaq(RDI, FieldAddress(R10, Array::data_offset() + (2 * kWordSize)));
  for (int i = 0; i < num_opt_params; i++) {
    // Handle this optional parameter only if k or fewer positional arguments
    // have been passed, where k is the position of this optional parameter in
    // the formal parameter list.
    Label load_default_value, assign_optional_parameter, next_parameter;
    const int param_pos = opt_param_position[i];
    __ cmpq(RCX, Immediate(param_pos));
    __ j(GREATER, &next_parameter, Assembler::kNearJump);
    // Check if this named parameter was passed in.
    __ movq(RAX, Address(RDI, 0));  // Load RAX with the name of the argument.
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
    // Load RAX with default argument at pos.
    const Object& value = Object::ZoneHandle(
        parsed_function_.default_parameter_values().At(
            param_pos - num_fixed_params));
    __ LoadObject(RAX, value);
    __ Bind(&assign_optional_parameter);
    // Assign RAX to fp[-1 - param_pos].
    // We do not use the final allocation index of the variable here, i.e.
    // scope->VariableAt(i)->index(), because captured variables still need
    // to be copied to the context that is not yet allocated.
    const Address param_addr(RBP, (-1 - param_pos) * kWordSize);
    __ movq(param_addr, RAX);
    __ Bind(&next_parameter);
  }
  delete[] opt_param;
  delete[] opt_param_position;
  // Check that RDI now points to the null terminator in the array descriptor.
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label all_arguments_processed;
  __ cmpq(Address(RDI, 0), raw_null);
  __ j(EQUAL, &all_arguments_processed, Assembler::kNearJump);

  __ Bind(&wrong_num_arguments);
  if (function.IsClosureFunction()) {
    GenerateCallRuntime(AstNode::kNoId,
                        0,
                        CatchClauseNode::kInvalidTryIndex,
                        kClosureArgumentMismatchRuntimeEntry);
  } else {
    // Invoke noSuchMethod function.
    const int kNumArgsChecked = 1;
    ICData& ic_data = ICData::ZoneHandle();
    ic_data = ICData::New(parsed_function_.function(),
                          String::Handle(function.name()),
                          AstNode::kNoId,
                          kNumArgsChecked);
    __ LoadObject(RBX, ic_data);
    // RBP : points to previous frame pointer.
    // RBP + 8 : points to return address.
    // RBP + 16 : address of last argument (arg n-1).
    // RSP + 16 + 8*(n-1) : address of first argument (arg 0).
    // RBX : ic-data.
    // R10 : arguments descriptor array.
    __ call(&StubCode::CallNoSuchMethodFunctionLabel());
  }

  if (FLAG_trace_functions) {
    __ pushq(RAX);  // Preserve result.
    __ PushObject(Function::ZoneHandle(function.raw()));
    GenerateCallRuntime(AstNode::kNoId,
                        0,
                        CatchClauseNode::kInvalidTryIndex,
                        kTraceFunctionExitRuntimeEntry);
    __ popq(RAX);  // Remove argument.
    __ popq(RAX);  // Restore result.
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


bool FlowGraphCompiler::CanOptimize() {
  return
      !FLAG_report_usage_count &&
      (FLAG_optimization_counter_threshold >= 0) &&
      !Isolate::Current()->debugger()->IsActive();
}


void FlowGraphCompiler::IntrinsifyGetter() {
  // TOS: return address.
  // +1 : receiver.
  // Sequence node has one return node, its input is load field node.
  const SequenceNode& sequence_node = *parsed_function_.node_sequence();
  ASSERT(sequence_node.length() == 1);
  ASSERT(sequence_node.NodeAt(0)->IsReturnNode());
  const ReturnNode& return_node = *sequence_node.NodeAt(0)->AsReturnNode();
  ASSERT(return_node.value()->IsLoadInstanceFieldNode());
  const LoadInstanceFieldNode& load_node =
      *return_node.value()->AsLoadInstanceFieldNode();
  __ movq(RAX, Address(RSP, 1 * kWordSize));
  __ movq(RAX, FieldAddress(RAX, load_node.field().Offset()));
  __ ret();
}


void FlowGraphCompiler::IntrinsifySetter() {
  // TOS: return address.
  // +1 : value
  // +2 : receiver.
  // Sequence node has one store node and one return NULL node.
  const SequenceNode& sequence_node = *parsed_function_.node_sequence();
  ASSERT(sequence_node.length() == 2);
  ASSERT(sequence_node.NodeAt(0)->IsStoreInstanceFieldNode());
  ASSERT(sequence_node.NodeAt(1)->IsReturnNode());
  const StoreInstanceFieldNode& store_node =
      *sequence_node.NodeAt(0)->AsStoreInstanceFieldNode();
  __ movq(RAX, Address(RSP, 2 * kWordSize));  // Receiver.
  __ movq(RBX, Address(RSP, 1 * kWordSize));  // Value.
  __ StoreIntoObject(RAX, FieldAddress(RAX, store_node.field().Offset()), RBX);
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movq(RAX, raw_null);
  __ ret();
}


// Returns 'true' if code generation for this function is complete, i.e.,
// no fall-through to regular code is needed.
bool FlowGraphCompiler::TryIntrinsify() {
  if (!CanOptimize()) return false;
  // Intrinsification skips arguments checks, therefore disable if in checked
  // mode.
  if (FLAG_intrinsify && !FLAG_trace_functions && !FLAG_enable_type_checks) {
    if ((parsed_function_.function().kind() == RawFunction::kImplicitGetter)) {
      IntrinsifyGetter();
      return true;
    }
    if ((parsed_function_.function().kind() == RawFunction::kImplicitSetter)) {
      IntrinsifySetter();
      return true;
    }
  }
  // Even if an intrinsified version of the function was successfully
  // generated, it may fall through to the non-intrinsified method body.
  if (!FLAG_trace_functions) {
    return Intrinsifier::Intrinsify(parsed_function_.function(), assembler_);
  }
  return false;
}


// TODO(srdjan): Investigate where to put the argument type checks for
// checked mode.
void FlowGraphCompiler::CompileGraph() {
  TimerScope timer(FLAG_compiler_stats, &CompilerStats::graphcompiler_timer);
  if (TryIntrinsify()) {
    // Make it patchable: code must have a minimum code size, nop(2) increases
    // the minimum code size appropriately.
    __ nop(2);
    __ int3();
    __ jmp(&StubCode::FixCallersTargetLabel());
    return;
  }
  // Specialized version of entry code from CodeGenerator::GenerateEntryCode.
  const Function& function = parsed_function_.function();

  const int parameter_count = function.num_fixed_parameters();
  const int num_copied_params = parsed_function_.copied_parameter_count();
  const int local_count = parsed_function_.stack_local_count();
  __ EnterFrame(StackSize() * kWordSize);

  // We check the number of passed arguments when we have to copy them due to
  // the presence of optional named parameters.
  // No such checking code is generated if only fixed parameters are declared,
  // unless we are debug mode or unless we are compiling a closure.
  if (num_copied_params == 0) {
#ifdef DEBUG
    const bool check_arguments = true;
#else
    const bool check_arguments = function.IsClosureFunction();
#endif
    if (check_arguments) {
      // Check that num_fixed <= argc <= num_params.
      Label argc_in_range;
      // Total number of args is the first Smi in args descriptor array (R10).
      __ movq(RAX, FieldAddress(R10, Array::data_offset()));
      __ cmpq(RAX, Immediate(Smi::RawValue(parameter_count)));
      __ j(EQUAL, &argc_in_range, Assembler::kNearJump);
      if (function.IsClosureFunction()) {
        GenerateCallRuntime(AstNode::kNoId,
                            function.token_index(),
                            CatchClauseNode::kInvalidTryIndex,
                            kClosureArgumentMismatchRuntimeEntry);
      } else {
        __ Stop("Wrong number of arguments");
      }
      __ Bind(&argc_in_range);
    }
  } else {
    CopyParameters();
  }

  // Initialize locals to null.
  if (local_count > 0) {
    __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(Object::null())));
    const int base = parsed_function_.first_stack_local_index();
    for (int i = 0; i < local_count; ++i) {
      // Subtract index i (locals lie at lower addresses than RBP).
      __ movq(Address(RBP, (base - i) * kWordSize), RAX);
    }
  }

  // Generate stack overflow check.
  __ movq(TMP, Immediate(Isolate::Current()->stack_limit_address()));
  __ cmpq(RSP, Address(TMP, 0));
  Label no_stack_overflow;
  __ j(ABOVE, &no_stack_overflow, Assembler::kNearJump);
  GenerateCallRuntime(AstNode::kNoId,
                      function.token_index(),
                      CatchClauseNode::kInvalidTryIndex,
                      kStackOverflowRuntimeEntry);
  __ Bind(&no_stack_overflow);

  if (FLAG_print_scopes) {
    // Print the function scope (again) after generating the prologue in order
    // to see annotations such as allocation indices of locals.
    if (FLAG_print_ast) {
      // Second printing.
      OS::Print("Annotated ");
    }
    AstPrinter::PrintFunctionScope(parsed_function_);
  }

  VisitBlocks();

  __ int3();
  // Emit function patching code. This will be swapped with the first 13 bytes
  // at entry point.
  pc_descriptors_list_->AddDescriptor(PcDescriptors::kPatchCode,
                                      assembler_->CodeSize(),
                                      AstNode::kNoId,
                                      0,
                                      -1);
  __ jmp(&StubCode::FixCallersTargetLabel());
}


// Infrastructure copied from class CodeGenerator.
void FlowGraphCompiler::GenerateCall(intptr_t token_index,
                                     intptr_t try_index,
                                     const ExternalLabel* label,
                                     PcDescriptors::Kind kind) {
  __ call(label);
  AddCurrentDescriptor(kind, AstNode::kNoId, token_index, try_index);
}


void FlowGraphCompiler::GenerateCallRuntime(intptr_t node_id,
                                            intptr_t token_index,
                                            intptr_t try_index,
                                            const RuntimeEntry& entry) {
  __ CallRuntimeFromDart(entry);
  AddCurrentDescriptor(PcDescriptors::kOther, node_id, token_index, try_index);
}


// Uses current pc position and try-index.
void FlowGraphCompiler::AddCurrentDescriptor(PcDescriptors::Kind kind,
                                             intptr_t node_id,
                                             intptr_t token_index,
                                             intptr_t try_index) {
  pc_descriptors_list_->AddDescriptor(kind,
                                      assembler_->CodeSize(),
                                      node_id,
                                      token_index,
                                      try_index);
}


void FlowGraphCompiler::FinalizePcDescriptors(const Code& code) {
  ASSERT(pc_descriptors_list_ != NULL);
  const PcDescriptors& descriptors = PcDescriptors::Handle(
      pc_descriptors_list_->FinalizePcDescriptors(code.EntryPoint()));
  descriptors.Verify(parsed_function_.function().is_optimizable());
  code.set_pc_descriptors(descriptors);
}


void FlowGraphCompiler::FinalizeStackmaps(const Code& code) {
  // TODO(srdjan): Compute stack maps for optimizing compiler.
  code.set_stackmaps(Array::Handle());
}


void FlowGraphCompiler::FinalizeVarDescriptors(const Code& code) {
  const LocalVarDescriptors& var_descs = LocalVarDescriptors::Handle(
          parsed_function_.node_sequence()->scope()->GetVarDescriptors());
  code.set_var_descriptors(var_descs);
}


void FlowGraphCompiler::FinalizeExceptionHandlers(const Code& code) {
  ASSERT(exception_handlers_list_ != NULL);
  const ExceptionHandlers& handlers = ExceptionHandlers::Handle(
      exception_handlers_list_->FinalizeExceptionHandlers(code.EntryPoint()));
  code.set_exception_handlers(handlers);
}


}  // namespace dart

#endif  // defined TARGET_ARCH_X64

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/flow_graph_compiler.h"

#include "vm/ast_printer.h"
#include "vm/code_generator.h"
#include "vm/disassembler.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/stub_code.h"

namespace dart {

DECLARE_FLAG(bool, print_ast);
DECLARE_FLAG(bool, print_scopes);
DECLARE_FLAG(bool, trace_functions);

FlowGraphCompiler::FlowGraphCompiler(
    Assembler* assembler,
    const ParsedFunction& parsed_function,
    const GrowableArray<BlockEntryInstr*>* blocks)
    : assembler_(assembler),
      parsed_function_(parsed_function),
      blocks_(blocks),
      block_info_(blocks->length()),
      current_block_(NULL),
      pc_descriptors_list_(new CodeGenerator::DescriptorList()),
      stack_local_count_(0) {
  for (int i = 0; i < blocks->length(); ++i) {
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

#define __ assembler_->


void FlowGraphCompiler::GenerateAssertAssignable(intptr_t node_id,
                                                 intptr_t token_index,
                                                 const AbstractType& dst_type,
                                                 const String& dst_name) {
  Bailout("GenerateAssertAssignable");
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
  Bailout("AssertAssignableComp");
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
  AddCurrentDescriptor(PcDescriptors::kIcCall, node_id, token_index);
  __ addq(RSP, Immediate(argument_count * kWordSize));
}


void FlowGraphCompiler::VisitInstanceCall(InstanceCallComp* comp) {
  ASSERT(VerifyCallComputation(comp));
  EmitInstanceCall(comp->node_id(),
                   comp->token_index(),
                   comp->function_name(),
                   comp->ArgumentCount(),
                   comp->argument_names(),
                   comp->checked_argument_count());
}


void FlowGraphCompiler::VisitStrictCompare(StrictCompareComp* comp) {
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());
  LoadValue(RAX, comp->left());
  LoadValue(RDX, comp->right());
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



void FlowGraphCompiler::VisitStaticCall(StaticCallComp* comp) {
  ASSERT(VerifyCallComputation(comp));

  int argument_count = comp->ArgumentCount();
  const Array& arguments_descriptor =
      CodeGenerator::ArgumentsDescriptor(argument_count,
                                         comp->argument_names());
  __ LoadObject(RBX, comp->function());
  __ LoadObject(R10, arguments_descriptor);

  GenerateCall(comp->token_index(),
               &StubCode::CallStaticFunctionLabel(),
               PcDescriptors::kFuncCall);
  __ addq(RSP, Immediate(argument_count * kWordSize));
}


void FlowGraphCompiler::VisitLoadLocal(LoadLocalComp* comp) {
  if (comp->local().is_captured()) {
    Bailout("load of context variable");
  }
  __ movq(RAX, Address(RBP, comp->local().index() * kWordSize));
}


void FlowGraphCompiler::VisitStoreLocal(StoreLocalComp* comp) {
  if (comp->local().is_captured()) {
    Bailout("store to context variable");
  }
  LoadValue(RAX, comp->value());
  __ movq(Address(RBP, comp->local().index() * kWordSize), RAX);
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
  EmitInstanceCall(comp->node_id(), comp->token_index(), function_name, 3,
                   Array::ZoneHandle(), 1);
  __ popq(RAX);
}


void FlowGraphCompiler::VisitInstanceSetter(InstanceSetterComp* comp) {
  // Preserve the second argument under the arguments as the result of the
  // computation, then call the getter.
  const String& function_name =
      String::ZoneHandle(Field::SetterSymbol(comp->field_name()));

  // Insert a copy of the second (last) argument under the arguments.
  __ popq(RAX);  // Value.
  __ popq(RBX);  // Reciever.
  __ pushq(RAX);
  __ pushq(RBX);
  __ pushq(RAX);
  EmitInstanceCall(comp->node_id(), comp->token_index(), function_name, 2,
                   Array::ZoneHandle(), 1);
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


static const Class* CoreClass(const char* c_name) {
  const String& class_name = String::Handle(String::NewSymbol(c_name));
  const Class& cls = Class::ZoneHandle(Library::Handle(
      Library::CoreImplLibrary()).LookupClass(class_name));
  ASSERT(!cls.IsNull());
  return &cls;
}


void FlowGraphCompiler::GenerateInstantiatorTypeArguments(
    intptr_t token_index) {
  Bailout("FlowGraphCompiler::GenerateInstantiatorTypeArguments");
}


// Copied from CodeGenerator.
// Optimize instanceof type test by adding inlined tests for:
// - NULL -> return false.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs:
// - RAX: object.
// Destroys RCX.
// Returns:
// - true or false in RAX.
void FlowGraphCompiler::GenerateInstanceOf(intptr_t node_id,
                                           intptr_t token_index,
                                           const AbstractType& type,
                                           bool negate_result) {
  ASSERT(type.IsFinalized() && !type.IsMalformed());
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());

  // All instances are of a subtype of the Object type.
  const Type& object_type =
      Type::Handle(Isolate::Current()->object_store()->object_type());
  Error& malformed_error = Error::Handle();
  if (type.IsInstantiated() &&
      object_type.IsSubtypeOf(type, &malformed_error)) {
    __ LoadObject(RAX, negate_result ? bool_false : bool_true);
    return;
  }

  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label done;
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
    Label non_null;
    __ cmpq(RAX, raw_null);
    __ j(NOT_EQUAL, &non_null, Assembler::kNearJump);
    __ PushObject(negate_result ? bool_true : bool_false);
    __ jmp(&done);

    __ Bind(&non_null);

    const Class& type_class = Class::ZoneHandle(type.type_class());
    const bool requires_type_arguments = type_class.HasTypeArguments();
    // A Smi object cannot be the instance of a parameterized class.
    // A class equality check is only applicable with a dst type of a
    // non-parameterized class or with a raw dst type of a parameterized class.
    if (requires_type_arguments) {
      const AbstractTypeArguments& type_arguments =
          AbstractTypeArguments::Handle(type.arguments());
      const bool is_raw_type = type_arguments.IsNull() ||
          type_arguments.IsDynamicTypes(type_arguments.Length());
      Label runtime_call;
      __ testq(RAX, Immediate(kSmiTagMask));
      __ j(ZERO, &runtime_call, Assembler::kNearJump);
      // Object not Smi.
      if (is_raw_type) {
        if (type.IsListInterface()) {
          Label push_result;
          // TODO(srdjan) also accept List<Object>.
          __ movq(RCX, FieldAddress(RAX, Object::class_offset()));
          __ CompareObject(RCX, *CoreClass("ObjectArray"));
          __ j(EQUAL, &push_result, Assembler::kNearJump);
          __ CompareObject(RCX, *CoreClass("GrowableObjectArray"));
          __ j(NOT_EQUAL, &runtime_call, Assembler::kNearJump);
          __ Bind(&push_result);
          __ PushObject(negate_result ? bool_false : bool_true);
          __ jmp(&done);
        } else if (!type_class.is_interface()) {
          __ movq(RCX, FieldAddress(RAX, Object::class_offset()));
          __ CompareObject(RCX, type_class);
          __ j(NOT_EQUAL, &runtime_call, Assembler::kNearJump);
          __ PushObject(negate_result ? bool_false : bool_true);
          __ jmp(&done);
        }
      }
      __ Bind(&runtime_call);
      // Fall through to runtime call.
    } else {
      Label compare_classes;
      __ testq(RAX, Immediate(kSmiTagMask));
      __ j(NOT_ZERO, &compare_classes, Assembler::kNearJump);
      // Object is Smi.
      const Class& smi_class = Class::Handle(Smi::Class());
      // TODO(regis): We should introduce a SmiType.
      Error& malformed_error = Error::Handle();
      if (smi_class.IsSubtypeOf(TypeArguments::Handle(),
                                type_class,
                                TypeArguments::Handle(),
                                &malformed_error)) {
        __ PushObject(negate_result ? bool_false : bool_true);
      } else {
        __ PushObject(negate_result ? bool_true : bool_false);
      }
      __ jmp(&done);

      // Compare if the classes are equal.
      __ Bind(&compare_classes);
      const Class* compare_class = NULL;
      if (type.IsStringInterface()) {
        compare_class = &Class::ZoneHandle(
            Isolate::Current()->object_store()->one_byte_string_class());
      } else if (type.IsBoolInterface()) {
        compare_class = &Class::ZoneHandle(
            Isolate::Current()->object_store()->bool_class());
      } else if (!type_class.is_interface()) {
        compare_class = &type_class;
      }
      if (compare_class != NULL) {
        Label runtime_call;
        __ movq(RCX, FieldAddress(RAX, Object::class_offset()));
        __ CompareObject(RCX, *compare_class);
        __ j(NOT_EQUAL, &runtime_call, Assembler::kNearJump);
        __ PushObject(negate_result ? bool_false : bool_true);
        __ jmp(&done, Assembler::kNearJump);
        __ Bind(&runtime_call);
      }
    }
  }
  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  const Immediate location =
      Immediate(reinterpret_cast<int64_t>(Smi::New(token_index)));
  __ pushq(location);  // Push the source location.
  __ pushq(RAX);  // Push the instance.
  __ PushObject(type);  // Push the type.
  if (!type.IsInstantiated()) {
    GenerateInstantiatorTypeArguments(token_index);
  } else {
    __ pushq(raw_null);  // Null instantiator.
  }
  GenerateCallRuntime(node_id, token_index, kInstanceofRuntimeEntry);
  // Pop the two parameters supplied to the runtime entry. The result of the
  // instanceof runtime call will be left as the result of the operation.
  __ addq(RSP, Immediate(4 * kWordSize));
  if (negate_result) {
    Label negate_done;
    __ popq(RDX);
    __ LoadObject(RAX, bool_true);
    __ cmpq(RDX, RAX);
    __ j(NOT_EQUAL, &negate_done, Assembler::kNearJump);
    __ LoadObject(RAX, bool_false);
    __ Bind(&negate_done);
    __ pushq(RAX);
  }
  __ Bind(&done);
  __ popq(RAX);
}


void FlowGraphCompiler::VisitInstanceOf(InstanceOfComp* comp) {
  __ popq(RAX);
  GenerateInstanceOf(comp->node_id(),
                     comp->token_index(),
                     comp->type(),
                     comp->negate_result());
}


void FlowGraphCompiler::VisitAllocateObject(AllocateObjectComp* comp) {
  const Class& cls = Class::ZoneHandle(comp->constructor().owner());
  const Code& stub = Code::Handle(StubCode::GetAllocationStubForClass(cls));
  const ExternalLabel label(cls.ToCString(), stub.EntryPoint());
  GenerateCall(comp->token_index(), &label, PcDescriptors::kOther);
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


void FlowGraphCompiler::VisitBlocks(
    const GrowableArray<BlockEntryInstr*>& blocks) {
  for (intptr_t i = blocks.length() - 1; i >= 0; --i) {
    // Compile the block entry.
    current_block_ = blocks[i];
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
      if (i == 0 || (blocks[i - 1] != successor)) {
        __ jmp(&block_info_[successor->block_number()]->label);
      }
    }
  }
}


void FlowGraphCompiler::VisitJoinEntry(JoinEntryInstr* instr) {
  __ Bind(&block_info_[instr->block_number()]->label);
}


void FlowGraphCompiler::VisitTargetEntry(TargetEntryInstr* instr) {
  __ Bind(&block_info_[instr->block_number()]->label);
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
  __ cmpq(R10, Immediate(stack_local_count() * kWordSize));
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
                       AstNode::kNoId,
                       instr->token_index());
}


void FlowGraphCompiler::VisitBranch(BranchInstr* instr) {
  // Determine if the true branch is fall through (!negated) or the false
  // branch is.  They cannot both be backwards branches.
  intptr_t index = blocks_->length() - current_block()->block_number() - 1;
  ASSERT(index > 0);

  bool negated = ((*blocks_)[index - 1] == instr->false_successor());
  ASSERT(!negated == ((*blocks_)[index - 1] == instr->true_successor()));

  LoadValue(RAX, instr->value());
  __ LoadObject(RDX, Bool::ZoneHandle(Bool::True()));
  __ cmpq(RAX, RDX);
  if (negated) {
    __ j(EQUAL, &block_info_[instr->true_successor()->block_number()]->label);
  } else {
    __ j(NOT_EQUAL,
         &block_info_[instr->false_successor()->block_number()]->label);
  }
}


void FlowGraphCompiler::CompileGraph() {
  const Function& function = parsed_function_.function();
  if ((function.num_optional_parameters() != 0)) {
    Bailout("function has optional parameters");
  }
  LocalScope* scope = parsed_function_.node_sequence()->scope();
  LocalScope* context_owner = NULL;
  const int parameter_count = function.num_fixed_parameters();
  const int first_parameter_index = 1 + parameter_count;
  const int first_local_index = -1;
  int first_free_frame_index =
      scope->AllocateVariables(first_parameter_index,
                               parameter_count,
                               first_local_index,
                               scope,
                               &context_owner);
  set_stack_local_count(first_local_index - first_free_frame_index);

  // Specialized version of entry code from CodeGenerator::GenerateEntryCode.
  __ EnterFrame(stack_local_count() * kWordSize);
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
                          kClosureArgumentMismatchRuntimeEntry);
    } else {
      __ Stop("Wrong number of arguments");
    }
    __ Bind(&argc_in_range);
  }

  // Initialize locals to null.
  if (stack_local_count() > 0) {
    __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(Object::null())));
    for (int i = 0; i < stack_local_count(); ++i) {
      // Subtract index i (locals lie at lower addresses than RBP).
      __ movq(Address(RBP, (first_local_index - i) * kWordSize), RAX);
    }
  }

  // Generate stack overflow check.
  __ movq(TMP, Immediate(Isolate::Current()->stack_limit_address()));
  __ cmpq(RSP, Address(TMP, 0));
  Label no_stack_overflow;
  __ j(ABOVE, &no_stack_overflow, Assembler::kNearJump);
  GenerateCallRuntime(AstNode::kNoId,
                      function.token_index(),
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

  VisitBlocks(*blocks_);

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
                                     const ExternalLabel* label,
                                     PcDescriptors::Kind kind) {
  __ call(label);
  AddCurrentDescriptor(kind, AstNode::kNoId, token_index);
}


void FlowGraphCompiler::GenerateCallRuntime(intptr_t node_id,
                                            intptr_t token_index,
                                            const RuntimeEntry& entry) {
  __ CallRuntimeFromDart(entry);
  AddCurrentDescriptor(PcDescriptors::kOther, node_id, token_index);
}


// Uses current pc position and try-index.
void FlowGraphCompiler::AddCurrentDescriptor(PcDescriptors::Kind kind,
                                             intptr_t node_id,
                                             intptr_t token_index) {
  pc_descriptors_list_->AddDescriptor(kind,
                                      assembler_->CodeSize(),
                                      node_id,
                                      token_index,
                                      CatchClauseNode::kInvalidTryIndex);
}


void FlowGraphCompiler::FinalizePcDescriptors(const Code& code) {
  ASSERT(pc_descriptors_list_ != NULL);
  const PcDescriptors& descriptors = PcDescriptors::Handle(
      pc_descriptors_list_->FinalizePcDescriptors(code.EntryPoint()));
  descriptors.Verify(parsed_function_.function().is_optimizable());
  code.set_pc_descriptors(descriptors);
}


void FlowGraphCompiler::FinalizeVarDescriptors(const Code& code) {
  const LocalVarDescriptors& var_descs = LocalVarDescriptors::Handle(
          parsed_function_.node_sequence()->scope()->GetVarDescriptors());
  code.set_var_descriptors(var_descs);
}


void FlowGraphCompiler::FinalizeExceptionHandlers(const Code& code) {
  // We don't compile exception handlers yet.
  code.set_exception_handlers(
      ExceptionHandlers::Handle(ExceptionHandlers::New(0)));
}


}  // namespace dart

#endif  // defined TARGET_ARCH_X64

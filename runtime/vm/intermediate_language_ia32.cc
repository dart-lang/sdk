// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/intermediate_language.h"

#include "vm/flow_graph_compiler.h"
#include "vm/locations.h"
#include "vm/object_store.h"
#include "vm/stub_code.h"

#define __ compiler->assembler()->

namespace dart {

DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(bool, trace_functions);

// True iff. the arguments to a call will be properly pushed and can
// be popped after the call.
template <typename T> static bool VerifyCallComputation(T* comp) {
  // Argument values should be consecutive temps.
  //
  // TODO(kmillikin): implement stack height tracking so we can also assert
  // they are on top of the stack.
  intptr_t previous = -1;
  for (int i = 0; i < comp->ArgumentCount(); ++i) {
    Value* val = comp->ArgumentAt(i);
    if (!val->IsUse()) return false;
    intptr_t current = val->AsUse()->definition()->temp_index();
    if (i != 0) {
      if (current != (previous + 1)) return false;
    }
    previous = current;
  }
  return true;
}


// Generic summary for call instructions that have all arguments pushed
// on the stack and return the result in a fixed register EAX.
static LocationSummary* MakeCallSummary() {
  LocationSummary* result = new LocationSummary(0, 0);
  result->set_out(Location::RegisterLocation(EAX));
  return result;
}


void BindInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  computation()->EmitNativeCode(compiler);
  __ pushl(locs()->out().reg());
}


void GraphEntryInstr::PrepareEntry(FlowGraphCompiler* compiler) {
  // Nothing to do.
}


void JoinEntryInstr::PrepareEntry(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetBlockLabel(this));
}


void TargetEntryInstr::PrepareEntry(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetBlockLabel(this));
  if (HasTryIndex()) {
    compiler->AddExceptionHandler(try_index(),
                                  compiler->assembler()->CodeSize());
  }
}


LocationSummary* ReturnInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new LocationSummary(kNumInputs, kNumTemps);
  locs->set_in(0, Location::RegisterLocation(EAX));
  locs->set_temp(0, Location::RequiresRegister());
  return locs;
}


void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();
  ASSERT(result == EAX);
  if (!compiler->is_optimizing()) {
    // Count only in unoptimized code.
    // TODO(srdjan): Replace the counting code with a type feedback
    // collection and counting stub.
    const Function& function =
          Function::ZoneHandle(compiler->parsed_function().function().raw());
    __ LoadObject(temp, function);
    __ incl(FieldAddress(temp, Function::usage_counter_offset()));
    if (CodeGenerator::CanOptimize()) {
      // Do not optimize if usage count must be reported.
      __ cmpl(FieldAddress(temp, Function::usage_counter_offset()),
          Immediate(FLAG_optimization_counter_threshold));
      Label not_yet_hot;
      __ j(LESS_EQUAL, &not_yet_hot, Assembler::kNearJump);
      __ pushl(result);  // Preserve result.
      __ pushl(temp);  // Argument for runtime: function to optimize.
      __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry);
      __ popl(temp);  // Remove argument.
      __ popl(result);  // Restore result.
      __ Bind(&not_yet_hot);
    }
  }
  if (FLAG_trace_functions) {
    const Function& function =
        Function::ZoneHandle(compiler->parsed_function().function().raw());
    __ LoadObject(temp, function);
    __ pushl(result);  // Preserve result.
    __ pushl(temp);
    compiler->GenerateCallRuntime(AstNode::kNoId,
                                  0,
                                  CatchClauseNode::kInvalidTryIndex,
                                  kTraceFunctionExitRuntimeEntry);
    __ popl(temp);  // Remove argument.
    __ popl(result);  // Restore result.
  }
  __ LeaveFrame();
  __ ret();
  // Add a NOP to make return code pattern 5 bytes long for patching
  // in breakpoints during debugging.
  __ nop(1);
  compiler->AddCurrentDescriptor(PcDescriptors::kReturn,
                                 cid(),
                                 token_index(),
                                 CatchClauseNode::kInvalidTryIndex);
}


LocationSummary* ThrowInstr::MakeLocationSummary() const {
  return NULL;
}


void ThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ReThrowInstr::MakeLocationSummary() const {
  return NULL;
}


void ReThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BranchInstr::MakeLocationSummary() const {
  const int kNumInputs = 1;
  const int kNumTemps = 0;
  LocationSummary* locs = new LocationSummary(kNumInputs, kNumTemps);
  locs->set_in(0, Location::RequiresRegister());
  return locs;
}


void BranchInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  __ CompareObject(value,  Bool::ZoneHandle(Bool::True()));
  if (compiler->IsNextBlock(false_successor())) {
    // If the next block is the false successor we will fall through to it if
    // comparison with true fails.
    __ j(EQUAL, compiler->GetBlockLabel(true_successor()));
  } else {
    ASSERT(compiler->IsNextBlock(true_successor()));
    // If the next block is the true successor we negate comparison and fall
    // through to it.
    __ j(NOT_EQUAL, compiler->GetBlockLabel(false_successor()));
  }
}


LocationSummary* CurrentContextComp::MakeLocationSummary() const {
  return LocationSummary::Make(0, Location::RequiresRegister());
}


void CurrentContextComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ movl(locs()->out().reg(), CTX);
}


LocationSummary* StoreContextComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new LocationSummary(kNumInputs, kNumTemps);
  summary->set_in(0, Location::RegisterLocation(CTX));
  return summary;
}


void StoreContextComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Nothing to do.  Context register were loaded by register allocator.
  ASSERT(locs()->in(0).reg() == CTX);
}


LocationSummary* StrictCompareComp::MakeLocationSummary() const {
  return LocationSummary::Make(2, Location::SameAsFirstInput());
}


void StrictCompareComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());

  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  Register result = locs()->out().reg();

  __ cmpl(left, right);
  Label load_true, done;
  if (kind() == Token::kEQ_STRICT) {
    __ j(EQUAL, &load_true, Assembler::kNearJump);
  } else {
    ASSERT(kind() == Token::kNE_STRICT);
    __ j(NOT_EQUAL, &load_true, Assembler::kNearJump);
  }
  __ LoadObject(result, bool_false);
  __ jmp(&done, Assembler::kNearJump);
  __ Bind(&load_true);
  __ LoadObject(result, bool_true);
  __ Bind(&done);
}


LocationSummary* ClosureCallComp::MakeLocationSummary() const {
  return MakeCallSummary();
}


void ClosureCallComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(VerifyCallComputation(this));
  // The arguments to the stub include the closure.  The arguments
  // descriptor describes the closure's arguments (and so does not include
  // the closure).
  int argument_count = ArgumentCount();
  const Array& arguments_descriptor =
      CodeGenerator::ArgumentsDescriptor(argument_count - 1,
                                         argument_names());
  __ LoadObject(EDX, arguments_descriptor);
  compiler->GenerateCall(token_index(),
                         try_index(),
                         &StubCode::CallClosureFunctionLabel(),
                         PcDescriptors::kOther);
  __ Drop(argument_count);
}


LocationSummary* InstanceCallComp::MakeLocationSummary() const {
  return MakeCallSummary();
}


void InstanceCallComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(VerifyCallComputation(this));
  compiler->AddCurrentDescriptor(PcDescriptors::kDeopt,
                                 cid(),
                                 token_index(),
                                 try_index());
  compiler->GenerateInstanceCall(cid(),
                                 token_index(),
                                 try_index(),
                                 function_name(),
                                 ArgumentCount(),
                                 argument_names(),
                                 checked_argument_count());
}


LocationSummary* StaticCallComp::MakeLocationSummary() const {
  return MakeCallSummary();
}


void StaticCallComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(VerifyCallComputation(this));
  compiler->GenerateStaticCall(cid(),
                               token_index(),
                               try_index(),
                               function(),
                               ArgumentCount(),
                               argument_names());
}


LocationSummary* LoadLocalComp::MakeLocationSummary() const {
  return LocationSummary::Make(0, Location::RequiresRegister());
}


void LoadLocalComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out().reg();
  __ movl(result, Address(EBP, local().index() * kWordSize));
}


LocationSummary* StoreLocalComp::MakeLocationSummary() const {
  return LocationSummary::Make(1, Location::SameAsFirstInput());
}


void StoreLocalComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out().reg();
  ASSERT(result == value);  // Assert that register assignment is correct.
  __ movl(Address(EBP, local().index() * kWordSize), value);
}


LocationSummary* ConstantVal::MakeLocationSummary() const {
  return LocationSummary::Make(0, Location::RequiresRegister());
}


void ConstantVal::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out().reg();
  if (value().IsSmi()) {
    int32_t imm = reinterpret_cast<int32_t>(value().raw());
    __ movl(result, Immediate(imm));
  } else {
    __ LoadObject(result, value());
  }
}


LocationSummary* UseVal::MakeLocationSummary() const {
  return NULL;
}


void UseVal::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* AssertAssignableComp::MakeLocationSummary() const {
  LocationSummary* summary = new LocationSummary(3, 0);
  summary->set_in(0, Location::RegisterLocation(EAX));
  summary->set_in(1, Location::RegisterLocation(ECX));
  summary->set_in(2, Location::RegisterLocation(EDX));
  summary->set_out(Location::RegisterLocation(EAX));
  return summary;
}


void AssertAssignableComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == EAX);  // Value.
  ASSERT(locs()->in(1).reg() == ECX);  // Instantiator.
  ASSERT(locs()->in(2).reg() == EDX);  // Instantiator type arguments.

  compiler->GenerateAssertAssignable(cid(),
                                     token_index(),
                                     try_index(),
                                     dst_type(),
                                     dst_name());
  ASSERT(locs()->in(0).reg() == locs()->out().reg());
}


LocationSummary* AssertBooleanComp::MakeLocationSummary() const {
  return NULL;
}


void AssertBooleanComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* EqualityCompareComp::MakeLocationSummary() const {
  return NULL;
}


void EqualityCompareComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* NativeCallComp::MakeLocationSummary() const {
  LocationSummary* locs = new LocationSummary(0, 3);
  locs->set_temp(0, Location::RegisterLocation(EAX));
  locs->set_temp(1, Location::RegisterLocation(ECX));
  locs->set_temp(2, Location::RegisterLocation(EDX));
  locs->set_out(Location::RequiresRegister());
  return locs;
}


void NativeCallComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == EAX);
  ASSERT(locs()->temp(1).reg() == ECX);
  ASSERT(locs()->temp(2).reg() == EDX);
  Register result = locs()->out().reg();
  // Push the result place holder initialized to NULL.
  __ PushObject(Object::ZoneHandle());
  // Pass a pointer to the first argument in EAX.
  if (!has_optional_parameters()) {
    __ leal(EAX, Address(EBP, (1 + argument_count()) * kWordSize));
  } else {
    __ leal(EAX,
            Address(EBP, ParsedFunction::kFirstLocalSlotIndex * kWordSize));
  }
  __ movl(ECX, Immediate(reinterpret_cast<uword>(native_c_function())));
  __ movl(EDX, Immediate(argument_count()));
  compiler->GenerateCall(token_index(),
                         try_index(),
                         &StubCode::CallNativeCFunctionLabel(),
                         PcDescriptors::kOther);
  __ popl(result);
}


LocationSummary* StoreIndexedComp::MakeLocationSummary() const {
  return NULL;
}


void StoreIndexedComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* InstanceSetterComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  return LocationSummary::Make(kNumInputs, Location::RequiresRegister());
  return NULL;
}


void InstanceSetterComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register receiver = locs()->in(0).reg();
  Register value = locs()->in(1).reg();
  Register result = locs()->out().reg();

  // Preserve the value (second argument) under the arguments as the result
  // of the computation, then call the setter.
  const String& function_name =
      String::ZoneHandle(Field::SetterSymbol(field_name()));

  // Insert a copy of the second (last) argument under the arguments.
  // TODO(fschneider): Avoid preserving the value if the result is not used.
  __ pushl(value);
  __ pushl(receiver);
  __ pushl(value);
  const intptr_t kArgumentCount = 2;
  const intptr_t kCheckedArgumentCount = 1;
  compiler->GenerateInstanceCall(cid(),
                                 token_index(),
                                 try_index(),
                                 function_name,
                                 kArgumentCount,
                                 Array::ZoneHandle(),
                                 kCheckedArgumentCount);
  __ popl(result);
}


LocationSummary* StaticSetterComp::MakeLocationSummary() const {
  return NULL;
}


void StaticSetterComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* LoadInstanceFieldComp::MakeLocationSummary() const {
  return NULL;
}


void LoadInstanceFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StoreInstanceFieldComp::MakeLocationSummary() const {
  return NULL;
}


void StoreInstanceFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* LoadStaticFieldComp::MakeLocationSummary() const {
  return NULL;
}


void LoadStaticFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StoreStaticFieldComp::MakeLocationSummary() const {
  return NULL;
}


void StoreStaticFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BooleanNegateComp::MakeLocationSummary() const {
  return NULL;
}


void BooleanNegateComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* InstanceOfComp::MakeLocationSummary() const {
  LocationSummary* summary = new LocationSummary(3, 0);
  summary->set_in(0, Location::RegisterLocation(EAX));
  summary->set_in(1, Location::RegisterLocation(ECX));
  summary->set_in(2, Location::RegisterLocation(EDX));
  summary->set_out(Location::RegisterLocation(EAX));
  return summary;
}


void InstanceOfComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == EAX);  // Value.
  ASSERT(locs()->in(1).reg() == ECX);  // Instantiator.
  ASSERT(locs()->in(2).reg() == EDX);  // Instantiator type arguments.

  compiler->GenerateInstanceOf(cid(),
                               token_index(),
                               try_index(),
                               type(),
                               negate_result());
  ASSERT(locs()->out().reg() == EAX);
}


LocationSummary* CreateArrayComp::MakeLocationSummary() const {
  return NULL;
}


void CreateArrayComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CreateClosureComp::MakeLocationSummary() const {
  return MakeCallSummary();
}


void CreateClosureComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Function& closure_function = function();
  const Code& stub = Code::Handle(
      StubCode::GetAllocationStubForClosure(closure_function));
  const ExternalLabel label(closure_function.ToCString(), stub.EntryPoint());
  compiler->GenerateCall(token_index(), try_index(), &label,
                         PcDescriptors::kOther);
  __ Drop(2);  // Discard type arguments and receiver.
}


LocationSummary* AllocateObjectComp::MakeLocationSummary() const {
  return MakeCallSummary();
}


void AllocateObjectComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Class& cls = Class::ZoneHandle(constructor().owner());
  const Code& stub = Code::Handle(StubCode::GetAllocationStubForClass(cls));
  const ExternalLabel label(cls.ToCString(), stub.EntryPoint());
  compiler->GenerateCall(token_index(),
                         try_index(),
                         &label,
                         PcDescriptors::kOther);
  __ Drop(arguments().length());  // Discard arguments.
}


LocationSummary*
AllocateObjectWithBoundsCheckComp::MakeLocationSummary() const {
  return LocationSummary::Make(2, Location::RequiresRegister());
}


void AllocateObjectWithBoundsCheckComp::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  const Class& cls = Class::ZoneHandle(constructor().owner());
  Register type_arguments = locs()->in(0).reg();
  Register instantiator_type_arguments = locs()->in(1).reg();
  Register result = locs()->out().reg();

  __ PushObject(Object::ZoneHandle());
  __ pushl(Immediate(Smi::RawValue(token_index())));
  __ PushObject(cls);
  __ pushl(type_arguments);
  __ pushl(instantiator_type_arguments);
  compiler->GenerateCallRuntime(cid(),
                                token_index(),
                                try_index(),
                                kAllocateObjectWithBoundsCheckRuntimeEntry);
  // Pop instantiator type arguments, type arguments, class, and
  // source location.
  __ Drop(4);
  __ popl(result);  // Pop new instance.
}


LocationSummary* LoadVMFieldComp::MakeLocationSummary() const {
  return LocationSummary::Make(1, Location::RequiresRegister());
}


void LoadVMFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register obj = locs()->in(0).reg();
  Register result = locs()->out().reg();

  __ movl(result, FieldAddress(obj, offset_in_bytes()));
}


LocationSummary* StoreVMFieldComp::MakeLocationSummary() const {
  return LocationSummary::Make(2, Location::SameAsFirstInput());
}


void StoreVMFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value_reg = locs()->in(0).reg();
  Register dest_reg = locs()->in(1).reg();
  ASSERT(value_reg == locs()->out().reg());

  __ StoreIntoObject(dest_reg, FieldAddress(dest_reg, offset_in_bytes()),
                     value_reg);
}


LocationSummary* InstantiateTypeArgumentsComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new LocationSummary(kNumInputs, kNumTemps);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_temp(0, Location::RequiresRegister());
  locs->set_out(Location::SameAsFirstInput());
  return locs;
}


void InstantiateTypeArgumentsComp::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  Register instantiator_reg = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();
  Register result_reg = locs()->out().reg();

  // 'instantiator_reg' is the instantiator AbstractTypeArguments object
  // (or null).
  // If the instantiator is null and if the type argument vector
  // instantiated from null becomes a vector of Dynamic, then use null as
  // the type arguments.
  Label type_arguments_instantiated;
  const intptr_t len = type_arguments().Length();
  if (type_arguments().IsRawInstantiatedRaw(len)) {
    const Immediate raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ cmpl(instantiator_reg, raw_null);
    __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);
  }
  // Instantiate non-null type arguments.
  if (type_arguments().IsUninstantiatedIdentity()) {
    // Check if the instantiator type argument vector is a TypeArguments of a
    // matching length and, if so, use it as the instantiated type_arguments.
    // No need to check instantiator for null (again), because a null instance
    // will have the wrong class (Null instead of TypeArguments).
    Label type_arguments_uninstantiated;
    __ CompareClassId(instantiator_reg, kTypeArguments, temp);
    __ j(NOT_EQUAL, &type_arguments_uninstantiated, Assembler::kNearJump);
    __ cmpl(FieldAddress(instantiator_reg, TypeArguments::length_offset()),
            Immediate(Smi::RawValue(len)));
    __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);
    __ Bind(&type_arguments_uninstantiated);
  }
  // A runtime call to instantiate the type arguments is required.
  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  __ PushObject(type_arguments());
  __ pushl(instantiator_reg);  // Push instantiator type arguments.
  compiler->GenerateCallRuntime(cid(),
                                token_index(),
                                try_index(),
                                kInstantiateTypeArgumentsRuntimeEntry);
  __ Drop(2);  // Drop instantiator and uninstantiated type arguments.
  __ popl(result_reg);  // Pop instantiated type arguments.
  __ Bind(&type_arguments_instantiated);
  ASSERT(instantiator_reg == result_reg);
}


LocationSummary*
ExtractConstructorTypeArgumentsComp::MakeLocationSummary() const {
  return NULL;
}


void ExtractConstructorTypeArgumentsComp::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary*
ExtractConstructorInstantiatorComp::MakeLocationSummary() const {
  return NULL;
}


void ExtractConstructorInstantiatorComp::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* AllocateContextComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new LocationSummary(kNumInputs, kNumTemps);
  locs->set_temp(0, Location::RegisterLocation(EDX));
  locs->set_out(Location::RegisterLocation(EAX));
  return locs;
}


void AllocateContextComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == EDX);
  ASSERT(locs()->out().reg() == EAX);

  __ movl(EDX, Immediate(num_context_variables()));
  const ExternalLabel label("alloc_context",
                            StubCode::AllocateContextEntryPoint());
  compiler->GenerateCall(token_index(),
                         try_index(),
                         &label,
                         PcDescriptors::kOther);
}


LocationSummary* ChainContextComp::MakeLocationSummary() const {
  return LocationSummary::Make(1, Location::NoLocation());
}


void ChainContextComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register context_value = locs()->in(0).reg();

  // Chain the new context in context_value to its parent in CTX.
  __ StoreIntoObject(context_value,
                     FieldAddress(context_value, Context::parent_offset()),
                     CTX);
  // Set new context as current context.
  __ movl(CTX, context_value);
}


LocationSummary* CloneContextComp::MakeLocationSummary() const {
  return LocationSummary::Make(1, Location::RequiresRegister());
}


void CloneContextComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register context_value = locs()->in(0).reg();
  Register result = locs()->out().reg();

  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  __ pushl(context_value);
  compiler->GenerateCallRuntime(cid(),
                                token_index(),
                                try_index(),
                                kCloneContextRuntimeEntry);
  __ popl(result);  // Remove argument.
  __ popl(result);  // Get result (cloned context).
}


LocationSummary* CatchEntryComp::MakeLocationSummary() const {
  return NULL;
}


void CatchEntryComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryOpComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new LocationSummary(kNumInputs, kNumTemps);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void BinaryOpComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  // TODO(srdjan): Remove this code once BinaryOpComp has been implemeneted
  // for all intended operations.
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  __ pushl(left);
  __ pushl(right);
  InstanceCallComp* instance_call_comp = instance_call();
  instance_call_comp->EmitNativeCode(compiler);
  if (locs()->out().reg() != EAX) {
    __ movl(locs()->out().reg(), EAX);
  }
}


LocationSummary* UnarySmiOpComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new LocationSummary(kNumInputs, kNumTemps);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void UnarySmiOpComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  const ICData& ic_data = *instance_call()->ic_data();
  ASSERT(!ic_data.IsNull());
  ASSERT(ic_data.num_args_tested() == 1);
  // TODO(srdjan): Implement for more checks.
  ASSERT(ic_data.NumberOfChecks() == 1);
  Class& test_class = Class::Handle();
  Function& target = Function::Handle();
  ic_data.GetOneClassCheckAt(0, &test_class, &target);

  Register value = locs()->in(0).reg();
  Register result = locs()->out().reg();
  ASSERT(value == result);
  Label* deopt = compiler->AddDeoptStub(instance_call()->cid(),
                                        instance_call()->token_index(),
                                        instance_call()->try_index(),
                                        kDeoptSmiBinaryOp,
                                        value,
                                        kNoRegister);
  if (test_class.id() == kSmi) {
    __ testl(value, Immediate(kSmiTagMask));
    __ j(NOT_ZERO, deopt);
    switch (op_kind()) {
      case Token::kNEGATE:
        __ negl(value);
        __ j(OVERFLOW, deopt);
        break;
      case Token::kBIT_NOT:
        __ notl(value);
        __ andl(value, Immediate(~kSmiTagMask));  // Remove inverted smi-tag.
        break;
      default:
        UNREACHABLE();
    }
  } else {
    UNREACHABLE();
  }
}


LocationSummary* NumberNegateComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;  // Needed for doubles.
  LocationSummary* summary = new LocationSummary(kNumInputs, kNumTemps);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(Location::SameAsFirstInput());
  summary->set_temp(0, Location::RequiresRegister());
  return summary;
}


void NumberNegateComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  const ICData& ic_data = *instance_call()->ic_data();
  ASSERT(!ic_data.IsNull());
  ASSERT(ic_data.num_args_tested() == 1);

  // TODO(srdjan): Implement for more checks.
  ASSERT(ic_data.NumberOfChecks() == 1);
  Class& test_class = Class::Handle();
  Function& target = Function::Handle();
  ic_data.GetOneClassCheckAt(0, &test_class, &target);

  Register value = locs()->in(0).reg();
  Register result = locs()->out().reg();
  ASSERT(value == result);
  Label* deopt = compiler->AddDeoptStub(instance_call()->cid(),
                                        instance_call()->token_index(),
                                        instance_call()->try_index(),
                                        kDeoptSmiBinaryOp,
                                        value,
                                        kNoRegister);
  if (test_class.id() == kDouble) {
    Register temp = locs()->temp(0).reg();
    ASSERT(result != temp);
    __ testl(value, Immediate(kSmiTagMask));
    __ j(ZERO, deopt);  // Smi.
    __ CompareClassId(value, kDouble, temp);
    __ j(NOT_EQUAL, deopt);
    // Allocate result object.
    const Class& double_class =
      Class::ZoneHandle(Isolate::Current()->object_store()->double_class());
    const Code& stub =
        Code::Handle(StubCode::GetAllocationStubForClass(double_class));
    const ExternalLabel label(double_class.ToCString(), stub.EntryPoint());
    __ pushl(value);
    compiler->GenerateCall(instance_call()->token_index(),
                           instance_call()->try_index(),
                           &label,
                           PcDescriptors::kOther);
    // Result is in EAX.
    __ movl(result, EAX);
    __ popl(temp);
    __ movsd(XMM0, FieldAddress(temp, Double::value_offset()));
    __ DoubleNegate(XMM0);
    __ movsd(FieldAddress(result, Double::value_offset()), XMM0);
  } else {
    UNREACHABLE();
  }
}


}  // namespace dart

#undef __

#endif  // defined TARGET_ARCH_X64

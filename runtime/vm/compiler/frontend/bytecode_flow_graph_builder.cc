// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/bytecode_flow_graph_builder.h"

#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/frontend/prologue_builder.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/object_store.h"
#include "vm/stack_frame.h"
#include "vm/stack_frame_kbc.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

#define B (flow_graph_builder_)
#define Z (zone_)

namespace dart {

DEFINE_FLAG(bool,
            print_flow_graph_from_bytecode,
            false,
            "Print flow graph constructed from bytecode");

namespace kernel {

// 8-bit unsigned operand at bits 8-15.
BytecodeFlowGraphBuilder::Operand BytecodeFlowGraphBuilder::DecodeOperandA() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    intptr_t value = KernelBytecode::DecodeA(bytecode_instr_);
    return Operand(value);
  }
}

// 8-bit unsigned operand at bits 16-23.
BytecodeFlowGraphBuilder::Operand BytecodeFlowGraphBuilder::DecodeOperandB() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    intptr_t value = KernelBytecode::DecodeB(bytecode_instr_);
    return Operand(value);
  }
}

// 8-bit unsigned operand at bits 24-31.
BytecodeFlowGraphBuilder::Operand BytecodeFlowGraphBuilder::DecodeOperandC() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    intptr_t value = KernelBytecode::DecodeC(bytecode_instr_);
    return Operand(value);
  }
}

// 16-bit unsigned operand at bits 16-31.
BytecodeFlowGraphBuilder::Operand BytecodeFlowGraphBuilder::DecodeOperandD() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    intptr_t value = KernelBytecode::DecodeD(bytecode_instr_);
    return Operand(value);
  }
}

// 16-bit signed operand at bits 16-31.
BytecodeFlowGraphBuilder::Operand BytecodeFlowGraphBuilder::DecodeOperandX() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    intptr_t value = KernelBytecode::DecodeX(bytecode_instr_);
    return Operand(value);
  }
}

// 24-bit signed operand at bits 8-31.
BytecodeFlowGraphBuilder::Operand BytecodeFlowGraphBuilder::DecodeOperandT() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    intptr_t value = KernelBytecode::DecodeT(bytecode_instr_);
    return Operand(value);
  }
}

KBCInstr BytecodeFlowGraphBuilder::InstructionAt(
    intptr_t pc,
    KernelBytecode::Opcode expect_opcode) {
  ASSERT(!is_generating_interpreter());
  ASSERT((0 <= pc) && (pc < bytecode_length_));

  const KBCInstr instr = raw_bytecode_[pc];
  if (KernelBytecode::DecodeOpcode(instr) != expect_opcode) {
    FATAL3("Expected bytecode instruction %s, but found %s at %" Pd "",
           KernelBytecode::NameOf(KernelBytecode::Encode(expect_opcode)),
           KernelBytecode::NameOf(instr), pc);
  }

  return instr;
}

BytecodeFlowGraphBuilder::Constant BytecodeFlowGraphBuilder::ConstantAt(
    Operand entry_index,
    intptr_t add_index) {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    const Object& value = Object::ZoneHandle(
        Z, object_pool_.ObjectAt(entry_index.value() + add_index));
    return Constant(Z, value);
  }
}

void BytecodeFlowGraphBuilder::PushConstant(Constant constant) {
  if (is_generating_interpreter()) {
    B->Push(constant.definition());
  } else {
    code_ += B->Constant(constant.value());
  }
}

BytecodeFlowGraphBuilder::Constant BytecodeFlowGraphBuilder::PopConstant() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    const Object& value = B->stack_->definition()->AsConstant()->value();
    code_ += B->Drop();
    return Constant(Z, value);
  }
}

void BytecodeFlowGraphBuilder::LoadStackSlots(intptr_t num_slots) {
  if (B->stack_ != nullptr) {
    intptr_t stack_depth = B->stack_->definition()->temp_index() + 1;
    ASSERT(stack_depth >= num_slots);
    return;
  }

  ASSERT(is_generating_interpreter());
  UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
}

void BytecodeFlowGraphBuilder::AllocateLocalVariables(
    Operand frame_size,
    intptr_t num_param_locals) {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    // TODO(alexmarkov): Make table of local variables in bytecode and
    // propagate type, name and positions.

    ASSERT(local_vars_.is_empty());

    const intptr_t num_bytecode_locals = frame_size.value();
    ASSERT(num_bytecode_locals >= 0);

    intptr_t num_locals = num_bytecode_locals;
    if (exception_var_ != nullptr) {
      ++num_locals;
    }
    if (stacktrace_var_ != nullptr) {
      ++num_locals;
    }
    if (scratch_var_ != nullptr) {
      ++num_locals;
    }
    if (parsed_function()->has_arg_desc_var()) {
      ++num_locals;
    }

    if (num_locals == 0) {
      return;
    }

    local_vars_.EnsureLength(num_bytecode_locals, nullptr);
    for (intptr_t i = num_param_locals; i < num_bytecode_locals; ++i) {
      String& name =
          String::ZoneHandle(Z, Symbols::NewFormatted(thread(), "var%" Pd, i));
      LocalVariable* local = new (Z)
          LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                        name, Object::dynamic_type());
      local->set_index(VariableIndex(-i));
      local_vars_[i] = local;
    }

    intptr_t idx = num_bytecode_locals;
    if (exception_var_ != nullptr) {
      exception_var_->set_index(VariableIndex(-idx));
      ++idx;
    }
    if (stacktrace_var_ != nullptr) {
      stacktrace_var_->set_index(VariableIndex(-idx));
      ++idx;
    }
    if (scratch_var_ != nullptr) {
      scratch_var_->set_index(VariableIndex(-idx));
      ++idx;
    }
    if (parsed_function()->has_arg_desc_var()) {
      parsed_function()->arg_desc_var()->set_index(VariableIndex(-idx));
      ++idx;
    }
    ASSERT(idx == num_locals);

    ASSERT(parsed_function()->node_sequence() == nullptr);
    parsed_function()->AllocateBytecodeVariables(num_locals);
  }
}

LocalVariable* BytecodeFlowGraphBuilder::AllocateParameter(
    intptr_t param_index,
    VariableIndex var_index) {
  const String& name =
      String::ZoneHandle(Z, function().ParameterNameAt(param_index));
  const AbstractType& type =
      AbstractType::ZoneHandle(Z, function().ParameterTypeAt(param_index));

  LocalVariable* param_var = new (Z) LocalVariable(
      TokenPosition::kNoSource, TokenPosition::kNoSource, name, type);
  param_var->set_index(var_index);

  if (var_index.value() <= 0) {
    local_vars_[-var_index.value()] = param_var;
  }

  return param_var;
}

void BytecodeFlowGraphBuilder::AllocateFixedParameters() {
  if (is_generating_interpreter()) {
    return;
  }

  ASSERT(!function().HasOptionalParameters());

  const intptr_t num_fixed_params = function().num_fixed_parameters();
  auto parameters =
      new (Z) ZoneGrowableArray<LocalVariable*>(Z, num_fixed_params);

  for (intptr_t i = 0; i < num_fixed_params; ++i) {
    LocalVariable* param_var =
        AllocateParameter(i, VariableIndex(num_fixed_params - i));
    parameters->Add(param_var);
  }

  parsed_function()->SetRawParameters(parameters);
}

LocalVariable* BytecodeFlowGraphBuilder::LocalVariableAt(intptr_t local_index) {
  ASSERT(!is_generating_interpreter());
  if (local_index < 0) {
    // Parameter
    ASSERT(!function().HasOptionalParameters());
    const intptr_t param_index = local_index +
                                 function().num_fixed_parameters() +
                                 kKBCParamEndSlotFromFp;
    ASSERT((0 <= param_index) &&
           (param_index < function().num_fixed_parameters()));
    return parsed_function()->RawParameterVariable(param_index);
  } else {
    return local_vars_.At(local_index);
  }
}

void BytecodeFlowGraphBuilder::StoreLocal(Operand local_index) {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    LocalVariable* local_var = LocalVariableAt(local_index.value());
    code_ += B->StoreLocalRaw(position_, local_var);
  }
}

void BytecodeFlowGraphBuilder::LoadLocal(Operand local_index) {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    LocalVariable* local_var = LocalVariableAt(local_index.value());
    code_ += B->LoadLocal(local_var);
  }
}

Value* BytecodeFlowGraphBuilder::Pop() {
  LoadStackSlots(1);
  return B->Pop();
}

ArgumentArray BytecodeFlowGraphBuilder::GetArguments(int count) {
  ArgumentArray arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(Z, count);
  arguments->SetLength(count);
  for (intptr_t i = count - 1; i >= 0; --i) {
    Definition* arg_def = B->stack_->definition();
    ASSERT(!arg_def->HasSSATemp());
    ASSERT(arg_def->temp_index() >= i);

    PushArgumentInstr* argument = new (Z) PushArgumentInstr(Pop());

    if (code_.current == arg_def) {
      code_ <<= argument;
    } else {
      Instruction* next = arg_def->next();
      ASSERT(next != nullptr);
      arg_def->LinkTo(argument);
      argument->LinkTo(next);
    }

    arguments->data()[i] = argument;
  }
  return arguments;
}

void BytecodeFlowGraphBuilder::PropagateStackState(intptr_t target_pc) {
  if (is_generating_interpreter() || (B->stack_ == nullptr)) {
    return;
  }

  // Stack state propagation is supported for forward branches only.
  // Bytecode generation guarantees that expression stack is empty between
  // statements and backward jumps are only used to transfer control between
  // statements (e.g. in loop and continue statements).
  RELEASE_ASSERT(target_pc > pc_);

  Value* current_stack = B->stack_;
  Value* target_stack = stack_states_.Lookup(target_pc);

  if (target_stack != nullptr) {
    // Control flow join should observe the same stack state from
    // all incoming branches.
    RELEASE_ASSERT(target_stack == current_stack);
  } else {
    stack_states_.Insert(target_pc, current_stack);
  }
}

void BytecodeFlowGraphBuilder::BuildInstruction(KernelBytecode::Opcode opcode) {
  switch (opcode) {
#define BUILD_BYTECODE_CASE(name, encoding, op1, op2, op3)                     \
  case KernelBytecode::k##name:                                                \
    Build##name();                                                             \
    break;

    KERNEL_BYTECODES_LIST(BUILD_BYTECODE_CASE)

#undef BUILD_BYTECODE_CASE
    default:
      FATAL1("Unsupported bytecode instruction %s\n",
             KernelBytecode::NameOf(bytecode_instr_));
  }
}

void BytecodeFlowGraphBuilder::BuildEntry() {
  AllocateLocalVariables(DecodeOperandD());
  AllocateFixedParameters();
}

void BytecodeFlowGraphBuilder::BuildEntryFixed() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  const intptr_t num_fixed_params = DecodeOperandA().value();
  ASSERT(num_fixed_params == function().num_fixed_parameters());

  AllocateLocalVariables(DecodeOperandD());
  AllocateFixedParameters();

  Fragment check_args;

  ASSERT(throw_no_such_method_ == nullptr);
  throw_no_such_method_ = B->BuildThrowNoSuchMethod();

  check_args += B->LoadArgDescriptor();
  check_args += B->LoadField(ArgumentsDescriptor::positional_count_offset());
  check_args += B->IntConstant(num_fixed_params);
  TargetEntryInstr *success1, *fail1;
  check_args += B->BranchIfEqual(&success1, &fail1);
  check_args = Fragment(check_args.entry, success1);

  check_args += B->LoadArgDescriptor();
  check_args += B->LoadField(ArgumentsDescriptor::count_offset());
  check_args += B->IntConstant(num_fixed_params);
  TargetEntryInstr *success2, *fail2;
  check_args += B->BranchIfEqual(&success2, &fail2);
  check_args = Fragment(check_args.entry, success2);

  Fragment(fail1) + B->Goto(throw_no_such_method_);
  Fragment(fail2) + B->Goto(throw_no_such_method_);

  ASSERT(B->stack_ == nullptr);

  if (!B->IsInlining() && !B->IsCompiledForOsr()) {
    code_ += check_args;
  }
}

void BytecodeFlowGraphBuilder::BuildEntryOptional() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  const intptr_t num_fixed_params = DecodeOperandA().value();
  const intptr_t num_opt_pos_params = DecodeOperandB().value();
  const intptr_t num_opt_named_params = DecodeOperandC().value();
  ASSERT(num_fixed_params == function().num_fixed_parameters());
  ASSERT(num_opt_pos_params == function().NumOptionalPositionalParameters());
  ASSERT(num_opt_named_params == function().NumOptionalNamedParameters());

  ASSERT((num_opt_pos_params == 0) || (num_opt_named_params == 0));
  const intptr_t num_load_const = num_opt_pos_params + 2 * num_opt_named_params;

  const KBCInstr frame_instr =
      InstructionAt(pc_ + 1 + num_load_const, KernelBytecode::kFrame);
  const intptr_t num_extra_locals = KernelBytecode::DecodeD(frame_instr);
  const intptr_t num_params =
      num_fixed_params + num_opt_pos_params + num_opt_named_params;
  const intptr_t total_locals = num_params + num_extra_locals;

  AllocateLocalVariables(Operand(total_locals), num_params);

  ZoneGrowableArray<const Instance*>* default_values =
      new (Z) ZoneGrowableArray<const Instance*>(
          Z, num_opt_pos_params + num_opt_named_params);
  ZoneGrowableArray<LocalVariable*>* raw_parameters =
      new (Z) ZoneGrowableArray<LocalVariable*>(Z, num_params);
  LocalVariable* temp_var = nullptr;

  intptr_t param = 0;
  for (; param < num_fixed_params; ++param) {
    LocalVariable* param_var = AllocateParameter(param, VariableIndex(-param));
    raw_parameters->Add(param_var);
  }

  for (intptr_t i = 0; i < num_opt_pos_params; ++i, ++param) {
    const KBCInstr load_value_instr =
        InstructionAt(pc_ + 1 + i, KernelBytecode::kLoadConstant);
    const Object& default_value =
        ConstantAt(Operand(KernelBytecode::DecodeD(load_value_instr))).value();
    ASSERT(KernelBytecode::DecodeA(load_value_instr) == param);

    LocalVariable* param_var = AllocateParameter(param, VariableIndex(-param));
    raw_parameters->Add(param_var);
    default_values->Add(
        &Instance::ZoneHandle(Z, Instance::RawCast(default_value.raw())));
  }

  if (num_opt_named_params > 0) {
    default_values->EnsureLength(num_opt_named_params, nullptr);
    raw_parameters->EnsureLength(num_params, nullptr);

    ASSERT(scratch_var_ != nullptr);
    temp_var = scratch_var_;

    for (intptr_t i = 0; i < num_opt_named_params; ++i, ++param) {
      const KBCInstr load_name_instr =
          InstructionAt(pc_ + 1 + i * 2, KernelBytecode::kLoadConstant);
      const KBCInstr load_value_instr =
          InstructionAt(pc_ + 1 + i * 2 + 1, KernelBytecode::kLoadConstant);
      const String& param_name = String::Cast(
          ConstantAt(Operand(KernelBytecode::DecodeD(load_name_instr)))
              .value());
      ASSERT(param_name.IsSymbol());
      const Object& default_value =
          ConstantAt(Operand(KernelBytecode::DecodeD(load_value_instr)))
              .value();

      intptr_t param_index = num_fixed_params;
      for (; param_index < num_params; ++param_index) {
        if (function().ParameterNameAt(param_index) == param_name.raw()) {
          break;
        }
      }
      ASSERT(param_index < num_params);

      ASSERT(default_values->At(param_index - num_fixed_params) == nullptr);
      (*default_values)[param_index - num_fixed_params] =
          &Instance::ZoneHandle(Z, Instance::RawCast(default_value.raw()));

      const intptr_t local_index = KernelBytecode::DecodeA(load_name_instr);
      ASSERT(local_index == KernelBytecode::DecodeA(load_value_instr));

      LocalVariable* param_var =
          AllocateParameter(param_index, VariableIndex(-param));
      ASSERT(raw_parameters->At(param_index) == nullptr);
      (*raw_parameters)[param_index] = param_var;
    }
  }

  parsed_function()->set_default_parameter_values(default_values);
  parsed_function()->SetRawParameters(raw_parameters);

  Fragment copy_args_prologue;

  // Code generated for EntryOptional is considered a prologue code.
  // Prologue should span a range of block ids, so start a new block at the
  // beginning and end a block at the end.
  JoinEntryInstr* prologue_entry = B->BuildJoinEntry();
  copy_args_prologue += B->Goto(prologue_entry);
  copy_args_prologue = Fragment(copy_args_prologue.entry, prologue_entry);

  ASSERT(throw_no_such_method_ == nullptr);
  throw_no_such_method_ = B->BuildThrowNoSuchMethod();

  PrologueBuilder prologue_builder(parsed_function(), B->last_used_block_id_,
                                   B->IsCompiledForOsr(), B->IsInlining());

  B->last_used_block_id_ = prologue_builder.last_used_block_id();

  copy_args_prologue += prologue_builder.BuildOptionalParameterHandling(
      throw_no_such_method_, temp_var);

  JoinEntryInstr* prologue_exit = B->BuildJoinEntry();
  copy_args_prologue += B->Goto(prologue_exit);
  copy_args_prologue.current = prologue_exit;

  if (!B->IsInlining() && !B->IsCompiledForOsr()) {
    code_ += copy_args_prologue;
  }

  prologue_info_ =
      PrologueInfo(prologue_entry->block_id(), prologue_exit->block_id() - 1);

  // Skip LoadConstant and Frame instructions.
  pc_ += num_load_const + 1;

  ASSERT(B->stack_ == nullptr);
}

void BytecodeFlowGraphBuilder::BuildLoadConstant() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  // Handled in EntryOptional instruction.
  UNREACHABLE();
}

void BytecodeFlowGraphBuilder::BuildFrame() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  // Handled in EntryOptional instruction.
  UNREACHABLE();
}

void BytecodeFlowGraphBuilder::BuildCheckFunctionTypeArgs() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  const intptr_t expected_num_type_args = DecodeOperandA().value();
  LocalVariable* type_args_var = LocalVariableAt(DecodeOperandD().value());
  ASSERT(function().IsGeneric());

  if (throw_no_such_method_ == nullptr) {
    throw_no_such_method_ = B->BuildThrowNoSuchMethod();
  }

  Fragment setup_type_args;
  JoinEntryInstr* done = B->BuildJoinEntry();

  // Type args are always optional, so length can always be zero.
  // If expect_type_args, a non-zero length must match the declaration length.
  TargetEntryInstr *then, *fail;
  setup_type_args += B->LoadArgDescriptor();
  setup_type_args += B->LoadNativeField(NativeFieldDesc::Get(
      NativeFieldDesc::kArgumentsDescriptor_type_args_len));

  if (expected_num_type_args != 0) {
    JoinEntryInstr* join2 = B->BuildJoinEntry();

    LocalVariable* len = B->MakeTemporary();

    TargetEntryInstr* otherwise;
    setup_type_args += B->LoadLocal(len);
    setup_type_args += B->IntConstant(0);
    setup_type_args += B->BranchIfEqual(&then, &otherwise);

    TargetEntryInstr* then2;
    Fragment check_len(otherwise);
    check_len += B->LoadLocal(len);
    check_len += B->IntConstant(expected_num_type_args);
    check_len += B->BranchIfEqual(&then2, &fail);

    Fragment null_type_args(then);
    null_type_args += B->NullConstant();
    null_type_args += B->StoreLocalRaw(TokenPosition::kNoSource, type_args_var);
    null_type_args += B->Drop();
    null_type_args += B->Goto(join2);

    Fragment store_type_args(then2);
    store_type_args += B->LoadArgDescriptor();
    store_type_args += B->LoadField(ArgumentsDescriptor::count_offset());
    store_type_args += B->LoadFpRelativeSlot(
        kWordSize * (1 + compiler_frame_layout.param_end_from_fp));
    store_type_args +=
        B->StoreLocalRaw(TokenPosition::kNoSource, type_args_var);
    store_type_args += B->Drop();
    store_type_args += B->Goto(join2);

    Fragment(join2) + B->Drop() + B->Goto(done);
    Fragment(fail) + B->Goto(throw_no_such_method_);
  } else {
    setup_type_args += B->IntConstant(0);
    setup_type_args += B->BranchIfEqual(&then, &fail);
    Fragment(then) + B->Goto(done);
    Fragment(fail) + B->Goto(throw_no_such_method_);
  }

  setup_type_args = Fragment(setup_type_args.entry, done);
  ASSERT(B->stack_ == nullptr);

  if (expected_num_type_args != 0) {
    parsed_function()->set_function_type_arguments(type_args_var);
    parsed_function()->SetRawTypeArgumentsVariable(type_args_var);
  }

  if (!B->IsInlining() && !B->IsCompiledForOsr()) {
    code_ += setup_type_args;
  }
}

void BytecodeFlowGraphBuilder::BuildCheckStack() {
  // TODO(alexmarkov): update B->loop_depth_
  code_ += B->CheckStackOverflow(position_);
  ASSERT(B->stack_ == nullptr);
}

void BytecodeFlowGraphBuilder::BuildPushConstant() {
  PushConstant(ConstantAt(DecodeOperandD()));
}

void BytecodeFlowGraphBuilder::BuildPushNull() {
  code_ += B->NullConstant();
}

void BytecodeFlowGraphBuilder::BuildPushTrue() {
  code_ += B->Constant(Bool::True());
}

void BytecodeFlowGraphBuilder::BuildPushFalse() {
  code_ += B->Constant(Bool::False());
}

void BytecodeFlowGraphBuilder::BuildPushInt() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }
  code_ += B->IntConstant(DecodeOperandX().value());
}

void BytecodeFlowGraphBuilder::BuildStoreLocal() {
  LoadStackSlots(1);
  const Operand local_index = DecodeOperandX();
  StoreLocal(local_index);
}

void BytecodeFlowGraphBuilder::BuildPopLocal() {
  BuildStoreLocal();
  code_ += B->Drop();
}

void BytecodeFlowGraphBuilder::BuildPush() {
  const Operand local_index = DecodeOperandX();
  LoadLocal(local_index);
}

void BytecodeFlowGraphBuilder::BuildIndirectStaticCall() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  const ICData& icdata = ICData::Cast(PopConstant().value());

  const Function& target = Function::ZoneHandle(Z, icdata.GetTargetAt(0));
  const ArgumentsDescriptor arg_desc(
      Array::Cast(ConstantAt(DecodeOperandD()).value()));
  intptr_t argc = DecodeOperandA().value();
  ASSERT(ic_data_array_->At(icdata.deopt_id())->Original() == icdata.raw());

  ArgumentArray arguments = GetArguments(argc);

  // TODO(alexmarkov): pass ICData::kSuper for super calls
  // (need to distinguish them in bytecode).
  StaticCallInstr* call = new (Z) StaticCallInstr(
      position_, target, arg_desc.TypeArgsLen(),
      Array::ZoneHandle(Z, arg_desc.GetArgumentNames()), arguments,
      *ic_data_array_, icdata.deopt_id(), ICData::kStatic);

  // TODO(alexmarkov): add type info
  // SetResultTypeForStaticCall(call, target, argument_count, result_type);

  code_ <<= call;
  B->Push(call);
}

void BytecodeFlowGraphBuilder::BuildInstanceCall() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  const ICData& icdata = ICData::Cast(ConstantAt(DecodeOperandD()).value());
  ASSERT(ic_data_array_->At(icdata.deopt_id())->Original() == icdata.raw());

  const intptr_t argc = DecodeOperandA().value();
  const ArgumentsDescriptor arg_desc(
      Array::Handle(Z, icdata.arguments_descriptor()));

  const String& name = String::ZoneHandle(Z, icdata.target_name());
  const Token::Kind token_kind =
      MethodTokenRecognizer::RecognizeTokenKind(name);

  const ArgumentArray arguments = GetArguments(argc);

  // TODO(alexmarkov): store interface_target in bytecode and pass it here.

  InstanceCallInstr* call = new (Z) InstanceCallInstr(
      position_, name, token_kind, arguments, arg_desc.TypeArgsLen(),
      Array::ZoneHandle(Z, arg_desc.GetArgumentNames()), icdata.NumArgsTested(),
      *ic_data_array_, icdata.deopt_id());

  ASSERT(call->ic_data() != nullptr);
  ASSERT(call->ic_data()->Original() == icdata.raw());

  // TODO(alexmarkov): add type info - call->SetResultType()

  code_ <<= call;
  B->Push(call);
}

void BytecodeFlowGraphBuilder::BuildNativeCall() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  // Default flow graph builder is used to compile native methods.
  UNREACHABLE();
}

void BytecodeFlowGraphBuilder::BuildAllocate() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  const Class& klass = Class::Cast(ConstantAt(DecodeOperandD()).value());

  const ArgumentArray arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(Z, 0);

  AllocateObjectInstr* allocate =
      new (Z) AllocateObjectInstr(position_, klass, arguments);

  code_ <<= allocate;
  B->Push(allocate);
}

void BytecodeFlowGraphBuilder::BuildAllocateT() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  const Class& klass = Class::Cast(PopConstant().value());
  const ArgumentArray arguments = GetArguments(1);

  AllocateObjectInstr* allocate =
      new (Z) AllocateObjectInstr(position_, klass, arguments);

  code_ <<= allocate;
  B->Push(allocate);
}

void BytecodeFlowGraphBuilder::BuildAllocateContext() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  code_ += B->AllocateContext(DecodeOperandD().value());
}

void BytecodeFlowGraphBuilder::BuildCloneContext() {
  LoadStackSlots(1);
  // TODO(alexmarkov): Pass context_size and use it in compiled mode.
  CloneContextInstr* clone_instruction = new (Z) CloneContextInstr(
      TokenPosition::kNoSource, Pop(), CloneContextInstr::kUnknownContextSize,
      B->GetNextDeoptId());
  code_ <<= clone_instruction;
  B->Push(clone_instruction);
}

void BytecodeFlowGraphBuilder::BuildCreateArrayTOS() {
  LoadStackSlots(2);
  code_ += B->CreateArray();
}

void BytecodeFlowGraphBuilder::BuildStoreFieldTOS() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  LoadStackSlots(2);
  Operand cp_index = DecodeOperandD();

  const Field& field = Field::Cast(ConstantAt(cp_index, 1).value());
  ASSERT(Smi::Cast(ConstantAt(cp_index).value()).Value() * kWordSize ==
         field.Offset());

  if (field.Owner() == isolate()->object_store()->closure_class()) {
    // Stores to _Closure fields are lower-level.
    // TODO(alexmarkov): use NativeFieldDesc
    code_ += B->StoreInstanceField(position_, field.Offset());
  } else {
    // The rest of the StoreFieldTOS are for field initializers.
    // TODO(alexmarkov): Consider adding a flag to StoreFieldTOS or even
    // adding a separate bytecode instruction.
    code_ += B->StoreInstanceFieldGuarded(field,
                                          /* is_initialization_store = */ true);
  }
}

void BytecodeFlowGraphBuilder::BuildLoadFieldTOS() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  LoadStackSlots(1);
  Operand cp_index = DecodeOperandD();

  const Field& field = Field::Cast(ConstantAt(cp_index, 1).value());
  ASSERT(Smi::Cast(ConstantAt(cp_index).value()).Value() * kWordSize ==
         field.Offset());

  if (field.Owner() == isolate()->object_store()->closure_class()) {
    // Loads from _Closure fields are lower-level.
    // TODO(alexmarkov): use NativeFieldDesc
    code_ += B->LoadField(field.Offset());
  } else {
    code_ += B->LoadField(field);
  }
}

void BytecodeFlowGraphBuilder::BuildStoreContextParent() {
  LoadStackSlots(2);

  // TODO(alexmarkov): use NativeFieldDesc
  code_ += B->StoreInstanceField(position_, Context::parent_offset());
}

void BytecodeFlowGraphBuilder::BuildLoadContextParent() {
  LoadStackSlots(1);

  // TODO(alexmarkov): use NativeFieldDesc
  code_ += B->LoadField(Context::parent_offset());
}

void BytecodeFlowGraphBuilder::BuildStoreContextVar() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  LoadStackSlots(2);
  Operand var_index = DecodeOperandD();

  // TODO(alexmarkov): use NativeFieldDesc
  code_ += B->StoreInstanceField(position_,
                                 Context::variable_offset(var_index.value()));
}

void BytecodeFlowGraphBuilder::BuildLoadContextVar() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  LoadStackSlots(1);
  Operand var_index = DecodeOperandD();

  // TODO(alexmarkov): use NativeFieldDesc
  code_ += B->LoadField(Context::variable_offset(var_index.value()));
}

void BytecodeFlowGraphBuilder::BuildLoadTypeArgumentsField() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  LoadStackSlots(1);
  const intptr_t offset =
      Smi::Cast(ConstantAt(DecodeOperandD()).value()).Value() * kWordSize;

  code_ +=
      B->LoadNativeField(NativeFieldDesc::GetTypeArgumentsField(Z, offset));
}

void BytecodeFlowGraphBuilder::BuildStoreStaticTOS() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  LoadStackSlots(1);
  Operand cp_index = DecodeOperandD();

  const Field& field = Field::Cast(ConstantAt(cp_index).value());

  code_ += B->StoreStaticField(position_, field);
}

void BytecodeFlowGraphBuilder::BuildPushStatic() {
  // Note: Field object is both pushed into the stack and
  // available in constant pool entry D.
  // TODO(alexmarkov): clean this up. If we stop pushing field object
  // explicitly, we might need the following code to get it from constant
  // pool: PushConstant(ConstantAt(DecodeOperandD()));

  code_ += B->LoadStaticField();
}

void BytecodeFlowGraphBuilder::BuildStoreIndexedTOS() {
  LoadStackSlots(3);
  code_ += B->StoreIndexed(kArrayCid);
  code_ += B->Drop();
}

void BytecodeFlowGraphBuilder::BuildBooleanNegateTOS() {
  LoadStackSlots(1);
  code_ += B->BooleanNegate();
}

void BytecodeFlowGraphBuilder::BuildInstantiateType() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  const AbstractType& type =
      AbstractType::Cast(ConstantAt(DecodeOperandD()).value());

  LoadStackSlots(2);
  code_ += B->InstantiateType(type);
}

void BytecodeFlowGraphBuilder::BuildInstantiateTypeArgumentsTOS() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  const TypeArguments& type_args =
      TypeArguments::Cast(ConstantAt(DecodeOperandD()).value());

  LoadStackSlots(2);
  code_ += B->InstantiateTypeArguments(type_args);
}

void BytecodeFlowGraphBuilder::BuildAssertBoolean() {
  LoadStackSlots(1);
  code_ += B->AssertBool(position_);
}

void BytecodeFlowGraphBuilder::BuildAssertAssignable() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  LoadStackSlots(5);

  const String& dst_name = String::Cast(PopConstant().value());
  Value* function_type_args = Pop();
  Value* instantiator_type_args = Pop();
  const AbstractType& dst_type = AbstractType::Cast(PopConstant().value());
  Value* value = Pop();

  AssertAssignableInstr* instr = new (Z) AssertAssignableInstr(
      position_, value, instantiator_type_args, function_type_args, dst_type,
      dst_name, B->GetNextDeoptId());

  code_ <<= instr;

  B->Push(instr);
}

void BytecodeFlowGraphBuilder::BuildAssertSubtype() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  LoadStackSlots(5);

  const String& dst_name = String::Cast(PopConstant().value());
  const AbstractType& super_type = AbstractType::Cast(PopConstant().value());
  const AbstractType& sub_type = AbstractType::Cast(PopConstant().value());
  Value* function_type_args = Pop();
  Value* instantiator_type_args = Pop();

  AssertSubtypeInstr* instr = new (Z)
      AssertSubtypeInstr(position_, instantiator_type_args, function_type_args,
                         sub_type, super_type, dst_name, B->GetNextDeoptId());
  code_ <<= instr;
}

void BytecodeFlowGraphBuilder::BuildJump() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  const intptr_t target_pc = pc_ + DecodeOperandT().value();
  JoinEntryInstr* join = jump_targets_.Lookup(target_pc);
  ASSERT(join != nullptr);
  code_ += B->Goto(join);
  PropagateStackState(target_pc);
  B->stack_ = nullptr;
}

void BytecodeFlowGraphBuilder::BuildJumpIfNoAsserts() {
  if (!isolate()->asserts()) {
    BuildJump();
  }
}

void BytecodeFlowGraphBuilder::BuildJumpIfNotZeroTypeArgs() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  TargetEntryInstr *is_zero, *is_not_zero;
  code_ += B->LoadArgDescriptor();
  code_ += B->LoadNativeField(NativeFieldDesc::Get(
      NativeFieldDesc::kArgumentsDescriptor_type_args_len));
  code_ += B->IntConstant(0);
  code_ += B->BranchIfEqual(&is_zero, &is_not_zero);

  const intptr_t target_pc = pc_ + DecodeOperandT().value();
  JoinEntryInstr* join = jump_targets_.Lookup(target_pc);
  ASSERT(join != nullptr);
  Fragment(is_not_zero) += B->Goto(join);
  PropagateStackState(target_pc);

  code_ = Fragment(code_.entry, is_zero);
}

void BytecodeFlowGraphBuilder::BuildJumpIfStrictCompare(Token::Kind cmp_kind) {
  ASSERT((cmp_kind == Token::kEQ) || (cmp_kind == Token::kNE));

  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  LoadStackSlots(2);

  TargetEntryInstr* eq_branch = nullptr;
  TargetEntryInstr* ne_branch = nullptr;
  code_ += B->BranchIfStrictEqual(&eq_branch, &ne_branch);

  TargetEntryInstr* then_entry =
      (cmp_kind == Token::kEQ) ? eq_branch : ne_branch;
  TargetEntryInstr* else_entry =
      (cmp_kind == Token::kEQ) ? ne_branch : eq_branch;

  const intptr_t target_pc = pc_ + DecodeOperandT().value();
  JoinEntryInstr* join = jump_targets_.Lookup(target_pc);
  ASSERT(join != nullptr);

  code_ = Fragment(then_entry);
  code_ += B->Goto(join);
  PropagateStackState(target_pc);

  code_ = Fragment(else_entry);
}

void BytecodeFlowGraphBuilder::BuildJumpIfEqStrict() {
  BuildJumpIfStrictCompare(Token::kEQ);
}

void BytecodeFlowGraphBuilder::BuildJumpIfNeStrict() {
  BuildJumpIfStrictCompare(Token::kNE);
}

void BytecodeFlowGraphBuilder::BuildJumpIfTrue() {
  code_ += B->Constant(Bool::True());
  BuildJumpIfStrictCompare(Token::kEQ);
}

void BytecodeFlowGraphBuilder::BuildJumpIfFalse() {
  code_ += B->Constant(Bool::False());
  BuildJumpIfStrictCompare(Token::kEQ);
}

void BytecodeFlowGraphBuilder::BuildJumpIfNull() {
  code_ += B->NullConstant();
  BuildJumpIfStrictCompare(Token::kEQ);
}

void BytecodeFlowGraphBuilder::BuildJumpIfNotNull() {
  code_ += B->NullConstant();
  BuildJumpIfStrictCompare(Token::kNE);
}

void BytecodeFlowGraphBuilder::BuildDrop1() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
    // AdjustSP(-1);
  } else {
    code_ += B->Drop();
  }
}

void BytecodeFlowGraphBuilder::BuildReturnTOS() {
  LoadStackSlots(1);
  ASSERT(code_.is_open());
  code_ += B->Return(position_);
}

void BytecodeFlowGraphBuilder::BuildTrap() {
  code_ += Fragment(new (Z) StopInstr("Bytecode Trap instruction")).closed();
}

void BytecodeFlowGraphBuilder::BuildThrow() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  if (DecodeOperandA().value() == 0) {
    // throw
    LoadStackSlots(1);
    code_ += B->PushArgument();
    code_ += B->ThrowException(position_);
  } else {
    // rethrow
    LoadStackSlots(2);
    GetArguments(2);
    code_ += Fragment(new (Z) ReThrowInstr(position_, kInvalidTryIndex,
                                           B->GetNextDeoptId()))
                 .closed();
  }

  ASSERT(code_.is_closed());

  // Empty stack as closed fragment should not leave any values on the stack.
  while (B->stack_ != nullptr) {
    B->Pop();
  }
}

void BytecodeFlowGraphBuilder::BuildMoveSpecial() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  LocalVariable* special_var = nullptr;
  switch (DecodeOperandD().value()) {
    // TODO(alexmarkov): Move these constants to constants_kbc.h
    case KernelBytecode::kExceptionSpecialIndex:
      ASSERT(exception_var_ != nullptr);
      special_var = exception_var_;
      break;
    case KernelBytecode::kStackTraceSpecialIndex:
      ASSERT(stacktrace_var_ != nullptr);
      special_var = stacktrace_var_;
      break;
    default:
      UNREACHABLE();
  }

  code_ += B->LoadLocal(special_var);
  StoreLocal(DecodeOperandA());
  code_ += B->Drop();
}

void BytecodeFlowGraphBuilder::BuildSetFrame() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  // No-op in compiled code.
  ASSERT(B->stack_ == nullptr);
}

void BytecodeFlowGraphBuilder::BuildEqualsNull() {
  ASSERT(scratch_var_ != nullptr);
  LoadStackSlots(1);

  TargetEntryInstr* true_branch = nullptr;
  TargetEntryInstr* false_branch = nullptr;
  code_ += B->BranchIfNull(&true_branch, &false_branch);

  JoinEntryInstr* join = B->BuildJoinEntry();

  code_ = Fragment(true_branch);
  code_ += B->Constant(Bool::True());
  code_ += B->StoreLocalRaw(position_, scratch_var_);
  code_ += B->Drop();
  code_ += B->Goto(join);

  code_ = Fragment(false_branch);
  code_ += B->Constant(Bool::False());
  code_ += B->StoreLocalRaw(position_, scratch_var_);
  code_ += B->Drop();
  code_ += B->Goto(join);

  code_ = Fragment(join);
  code_ += B->LoadLocal(scratch_var_);
}

void BytecodeFlowGraphBuilder::BuildIntOp(const String& name,
                                          Token::Kind token_kind,
                                          int num_args) {
  ASSERT((num_args == 1) || (num_args == 2));
  ASSERT(MethodTokenRecognizer::RecognizeTokenKind(name) == token_kind);

  LoadStackSlots(num_args);
  const ArgumentArray arguments = GetArguments(num_args);

  InstanceCallInstr* call = new (Z) InstanceCallInstr(
      position_, name, token_kind, arguments, 0, Array::null_array(), num_args,
      *ic_data_array_, B->GetNextDeoptId());

  code_ <<= call;
  B->Push(call);
}

void BytecodeFlowGraphBuilder::BuildNegateInt() {
  BuildIntOp(Symbols::UnaryMinus(), Token::kNEGATE, 1);
}

void BytecodeFlowGraphBuilder::BuildAddInt() {
  BuildIntOp(Symbols::Plus(), Token::kADD, 2);
}

void BytecodeFlowGraphBuilder::BuildSubInt() {
  BuildIntOp(Symbols::Minus(), Token::kSUB, 2);
}

void BytecodeFlowGraphBuilder::BuildMulInt() {
  BuildIntOp(Symbols::Star(), Token::kMUL, 2);
}

void BytecodeFlowGraphBuilder::BuildTruncDivInt() {
  BuildIntOp(Symbols::TruncDivOperator(), Token::kTRUNCDIV, 2);
}

void BytecodeFlowGraphBuilder::BuildModInt() {
  BuildIntOp(Symbols::Percent(), Token::kMOD, 2);
}

void BytecodeFlowGraphBuilder::BuildBitAndInt() {
  BuildIntOp(Symbols::Ampersand(), Token::kBIT_AND, 2);
}

void BytecodeFlowGraphBuilder::BuildBitOrInt() {
  BuildIntOp(Symbols::BitOr(), Token::kBIT_OR, 2);
}

void BytecodeFlowGraphBuilder::BuildBitXorInt() {
  BuildIntOp(Symbols::Caret(), Token::kBIT_XOR, 2);
}

void BytecodeFlowGraphBuilder::BuildShlInt() {
  BuildIntOp(Symbols::LeftShiftOperator(), Token::kSHL, 2);
}

void BytecodeFlowGraphBuilder::BuildShrInt() {
  BuildIntOp(Symbols::RightShiftOperator(), Token::kSHR, 2);
}

void BytecodeFlowGraphBuilder::BuildCompareIntEq() {
  BuildIntOp(Symbols::EqualOperator(), Token::kEQ, 2);
}

void BytecodeFlowGraphBuilder::BuildCompareIntGt() {
  BuildIntOp(Symbols::RAngleBracket(), Token::kGT, 2);
}

void BytecodeFlowGraphBuilder::BuildCompareIntLt() {
  BuildIntOp(Symbols::LAngleBracket(), Token::kLT, 2);
}

void BytecodeFlowGraphBuilder::BuildCompareIntGe() {
  BuildIntOp(Symbols::GreaterEqualOperator(), Token::kGTE, 2);
}

void BytecodeFlowGraphBuilder::BuildCompareIntLe() {
  BuildIntOp(Symbols::LessEqualOperator(), Token::kLTE, 2);
}

static bool IsICDataEntry(const ObjectPool& object_pool, intptr_t index) {
  if (object_pool.TypeAt(index) != ObjectPool::kTaggedObject) {
    return false;
  }
  RawObject* entry = object_pool.ObjectAt(index);
  return entry->IsHeapObject() && entry->IsICData();
}

// Read ICData entries in object pool, skip deopt_ids and
// pre-populate ic_data_array_.
void BytecodeFlowGraphBuilder::ProcessICDataInObjectPool(
    const ObjectPool& object_pool) {
  CompilerState& compiler_state = thread()->compiler_state();
  ASSERT(compiler_state.deopt_id() == 0);

  const intptr_t pool_length = object_pool.Length();
  for (intptr_t i = 0; i < pool_length; ++i) {
    if (IsICDataEntry(object_pool, i)) {
      const ICData& icdata = ICData::CheckedHandle(Z, object_pool.ObjectAt(i));
      const intptr_t deopt_id = compiler_state.GetNextDeoptId();

      ASSERT(icdata.deopt_id() == deopt_id);
      ASSERT(ic_data_array_->is_empty() ||
             (ic_data_array_->At(deopt_id)->Original() == icdata.raw()));
    }
  }

  if (ic_data_array_->is_empty()) {
    const intptr_t len = compiler_state.deopt_id();
    ic_data_array_->EnsureLength(len, nullptr);
    for (intptr_t i = 0; i < pool_length; ++i) {
      if (IsICDataEntry(object_pool, i)) {
        const ICData& icdata =
            ICData::CheckedHandle(Z, object_pool.ObjectAt(i));
        (*ic_data_array_)[icdata.deopt_id()] = &icdata;
      }
    }
  }
}

intptr_t BytecodeFlowGraphBuilder::GetTryIndex(const PcDescriptors& descriptors,
                                               intptr_t pc) {
  const uword pc_offset =
      KernelBytecode::BytecodePcToOffset(pc, /* is_return_address = */ true);
  PcDescriptors::Iterator iter(descriptors, RawPcDescriptors::kAnyKind);
  intptr_t try_index = kInvalidTryIndex;
  while (iter.MoveNext()) {
    const intptr_t current_try_index = iter.TryIndex();
    const uword start_pc = iter.PcOffset();
    if (pc_offset < start_pc) {
      break;
    }
    const bool has_next = iter.MoveNext();
    ASSERT(has_next);
    const uword end_pc = iter.PcOffset();
    if (start_pc <= pc_offset && pc_offset < end_pc) {
      ASSERT(try_index < current_try_index);
      try_index = current_try_index;
    }
  }
  return try_index;
}

JoinEntryInstr* BytecodeFlowGraphBuilder::EnsureControlFlowJoin(
    const PcDescriptors& descriptors,
    intptr_t pc) {
  ASSERT((0 <= pc) && (pc < bytecode_length_));
  JoinEntryInstr* join = jump_targets_.Lookup(pc);
  if (join == nullptr) {
    join = B->BuildJoinEntry(GetTryIndex(descriptors, pc));
    jump_targets_.Insert(pc, join);
  }
  return join;
}

bool BytecodeFlowGraphBuilder::RequiresScratchVar(KBCInstr instr) {
  switch (KernelBytecode::DecodeOpcode(instr)) {
    case KernelBytecode::kEntryOptional:
      return KernelBytecode::DecodeC(instr) > 0;
    case KernelBytecode::kEqualsNull:
      return true;
    default:
      return false;
  }
}

void BytecodeFlowGraphBuilder::CollectControlFlow(
    const PcDescriptors& descriptors,
    const ExceptionHandlers& handlers,
    GraphEntryInstr* graph_entry) {
  for (intptr_t pc = 0; pc < bytecode_length_; ++pc) {
    const KBCInstr instr = raw_bytecode_[pc];

    if (KernelBytecode::IsJumpOpcode(instr)) {
      const intptr_t target = pc + KernelBytecode::DecodeT(instr);
      EnsureControlFlowJoin(descriptors, target);
    }

    if ((scratch_var_ == nullptr) && RequiresScratchVar(instr)) {
      scratch_var_ = new (Z)
          LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                        Symbols::ExprTemp(), Object::dynamic_type());
    }
  }

  PcDescriptors::Iterator iter(descriptors, RawPcDescriptors::kAnyKind);
  while (iter.MoveNext()) {
    const intptr_t start_pc = KernelBytecode::OffsetToBytecodePc(
        iter.PcOffset(), /* is_return_address = */ true);
    EnsureControlFlowJoin(descriptors, start_pc);

    const bool has_next = iter.MoveNext();
    ASSERT(has_next);
    const intptr_t end_pc = KernelBytecode::OffsetToBytecodePc(
        iter.PcOffset(), /* is_return_address = */ true);
    EnsureControlFlowJoin(descriptors, end_pc);
  }

  if (handlers.num_entries() > 0) {
    B->InlineBailout("kernel::BytecodeFlowGraphBuilder::CollectControlFlow");

    exception_var_ = new (Z)
        LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                      Symbols::ExceptionVar(), Object::dynamic_type());
    stacktrace_var_ = new (Z)
        LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                      Symbols::StackTraceVar(), Object::dynamic_type());
  }

  for (intptr_t try_index = 0; try_index < handlers.num_entries();
       ++try_index) {
    ExceptionHandlerInfo handler_info;
    handlers.GetHandlerInfo(try_index, &handler_info);

    const intptr_t handler_pc = KernelBytecode::OffsetToBytecodePc(
        handler_info.handler_pc_offset, /* is_return_address = */ false);
    JoinEntryInstr* join = EnsureControlFlowJoin(descriptors, handler_pc);

    const Array& handler_types =
        Array::ZoneHandle(Z, handlers.GetHandledTypes(try_index));

    CatchBlockEntryInstr* entry = new (Z) CatchBlockEntryInstr(
        TokenPosition::kNoSource, handler_info.is_generated,
        B->AllocateBlockId(), handler_info.outer_try_index, graph_entry,
        handler_types, try_index, handler_info.needs_stacktrace,
        B->GetNextDeoptId(), nullptr, nullptr, exception_var_, stacktrace_var_);
    graph_entry->AddCatchEntry(entry);

    code_ = Fragment(entry);
    code_ += B->Goto(join);
  }
}

FlowGraph* BytecodeFlowGraphBuilder::BuildGraph() {
  // Use default flow graph builder for native methods.
  ASSERT(!function().is_native());

  const Code& bytecode = Code::Handle(Z, function().Bytecode());

  object_pool_ = bytecode.object_pool();
  raw_bytecode_ = reinterpret_cast<KBCInstr*>(bytecode.EntryPoint());
  bytecode_length_ = bytecode.Size() / sizeof(KBCInstr);

  ProcessICDataInObjectPool(object_pool_);

  TargetEntryInstr* normal_entry = B->BuildTargetEntry();
  GraphEntryInstr* graph_entry =
      new (Z) GraphEntryInstr(*parsed_function_, normal_entry, B->osr_id_);

  const PcDescriptors& descriptors =
      PcDescriptors::Handle(Z, bytecode.pc_descriptors());
  const ExceptionHandlers& handlers =
      ExceptionHandlers::Handle(Z, bytecode.exception_handlers());

  CollectControlFlow(descriptors, handlers, graph_entry);

  code_ = Fragment(normal_entry);

  for (pc_ = 0; pc_ < bytecode_length_; ++pc_) {
    bytecode_instr_ = raw_bytecode_[pc_];

    JoinEntryInstr* join = jump_targets_.Lookup(pc_);
    if (join != nullptr) {
      Value* stack_state = stack_states_.Lookup(pc_);
      if (code_.is_open()) {
        ASSERT((stack_state == nullptr) || (stack_state == B->stack_));
        code_ += B->Goto(join);
      } else {
        ASSERT(B->stack_ == nullptr);
        B->stack_ = stack_state;
      }
      code_ = Fragment(join);
      B->SetCurrentTryIndex(join->try_index());
    } else if (code_.is_closed()) {
      // Skip unreachable bytecode instructions.
      continue;
    }

    BuildInstruction(KernelBytecode::DecodeOpcode(bytecode_instr_));

    if (code_.is_closed()) {
      ASSERT(B->stack_ == nullptr);
    }
  }

  // When compiling for OSR, use a depth first search to find the OSR
  // entry and make graph entry jump to it instead of normal entry.
  // Catch entries are always considered reachable, even if they
  // become unreachable after OSR.
  if (B->IsCompiledForOsr()) {
    graph_entry->RelinkToOsrEntry(Z, B->last_used_block_id_ + 1);
  }

  FlowGraph* flow_graph = new (Z) FlowGraph(
      *parsed_function_, graph_entry, B->last_used_block_id_, prologue_info_);

  if (FLAG_print_flow_graph_from_bytecode) {
    FlowGraphPrinter::PrintGraph("Constructed from bytecode", flow_graph);
  }

  return flow_graph;
}

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

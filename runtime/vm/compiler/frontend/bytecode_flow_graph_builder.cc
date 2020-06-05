// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/bytecode_flow_graph_builder.h"

#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/ffi/callback.h"
#include "vm/compiler/frontend/bytecode_reader.h"
#include "vm/compiler/frontend/prologue_builder.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/object_store.h"
#include "vm/stack_frame.h"
#include "vm/stack_frame_kbc.h"

#define B (flow_graph_builder_)
#define Z (zone_)

namespace dart {

DEFINE_FLAG(bool,
            print_flow_graph_from_bytecode,
            false,
            "Print flow graph constructed from bytecode");

namespace kernel {

BytecodeFlowGraphBuilder::Operand BytecodeFlowGraphBuilder::DecodeOperandA() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    intptr_t value = KernelBytecode::DecodeA(bytecode_instr_);
    return Operand(value);
  }
}

BytecodeFlowGraphBuilder::Operand BytecodeFlowGraphBuilder::DecodeOperandB() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    intptr_t value = KernelBytecode::DecodeB(bytecode_instr_);
    return Operand(value);
  }
}

BytecodeFlowGraphBuilder::Operand BytecodeFlowGraphBuilder::DecodeOperandC() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    intptr_t value = KernelBytecode::DecodeC(bytecode_instr_);
    return Operand(value);
  }
}

BytecodeFlowGraphBuilder::Operand BytecodeFlowGraphBuilder::DecodeOperandD() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    intptr_t value = KernelBytecode::DecodeD(bytecode_instr_);
    return Operand(value);
  }
}

BytecodeFlowGraphBuilder::Operand BytecodeFlowGraphBuilder::DecodeOperandE() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    intptr_t value = KernelBytecode::DecodeE(bytecode_instr_);
    return Operand(value);
  }
}

BytecodeFlowGraphBuilder::Operand BytecodeFlowGraphBuilder::DecodeOperandF() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    intptr_t value = KernelBytecode::DecodeF(bytecode_instr_);
    return Operand(value);
  }
}

BytecodeFlowGraphBuilder::Operand BytecodeFlowGraphBuilder::DecodeOperandX() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    intptr_t value = KernelBytecode::DecodeX(bytecode_instr_);
    return Operand(value);
  }
}

BytecodeFlowGraphBuilder::Operand BytecodeFlowGraphBuilder::DecodeOperandY() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    intptr_t value = KernelBytecode::DecodeY(bytecode_instr_);
    return Operand(value);
  }
}

BytecodeFlowGraphBuilder::Operand BytecodeFlowGraphBuilder::DecodeOperandT() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
    intptr_t value = KernelBytecode::DecodeT(bytecode_instr_);
    return Operand(value);
  }
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
    ASSERT(!IsStackEmpty());
    const Object& value = B->stack_->definition()->AsConstant()->value();
    code_ += B->Drop();
    return Constant(Z, value);
  }
}

void BytecodeFlowGraphBuilder::LoadStackSlots(intptr_t num_slots) {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  ASSERT(GetStackDepth() >= num_slots);
}

void BytecodeFlowGraphBuilder::AllocateLocalVariables(
    Operand frame_size,
    intptr_t num_param_locals) {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  } else {
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
    if (parsed_function()->has_entry_points_temp_var()) {
      ++num_locals;
    }

    if (num_locals == 0) {
      return;
    }

    local_vars_.EnsureLength(num_bytecode_locals, nullptr);
    intptr_t idx = num_param_locals;
    for (; idx < num_bytecode_locals; ++idx) {
      String& name = String::ZoneHandle(
          Z, Symbols::NewFormatted(thread(), "var%" Pd, idx));
      LocalVariable* local = new (Z)
          LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                        name, Object::dynamic_type());
      local->set_index(VariableIndex(-idx));
      local_vars_[idx] = local;
    }

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
    if (parsed_function()->has_entry_points_temp_var()) {
      parsed_function()->entry_points_temp_var()->set_index(
          VariableIndex(-idx));
      ++idx;
    }
    ASSERT(idx == num_locals);

    ASSERT(parsed_function()->scope() == nullptr);
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

  CompileType* param_type = nullptr;
  if (!inferred_types_attribute_.IsNull()) {
    // Parameter types are assigned to synthetic PCs = -N,..,-1
    // where N is number of parameters.
    const intptr_t pc = -function().NumParameters() + param_index;
    // Search from the beginning as parameters may be declared in arbitrary
    // order.
    inferred_types_index_ = 0;
    const InferredTypeMetadata inferred_type = GetInferredType(pc);
    if (!inferred_type.IsTrivial()) {
      param_type = new (Z) CompileType(inferred_type.ToCompileType(Z));
    }
  }

  LocalVariable* param_var =
      new (Z) LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                            name, type, param_type);
  param_var->set_index(var_index);

  if (!function().IsNonImplicitClosureFunction() &&
      (function().is_static() ||
       ((function().name() != Symbols::Call().raw()) &&
        !parsed_function()->IsCovariantParameter(param_index) &&
        !parsed_function()->IsGenericCovariantImplParameter(param_index)))) {
    param_var->set_type_check_mode(LocalVariable::kTypeCheckedByCaller);
  }

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

const KBCInstr*
BytecodeFlowGraphBuilder::AllocateParametersAndLocalsForEntryOptional() {
  ASSERT(KernelBytecode::IsEntryOptionalOpcode(bytecode_instr_));

  const intptr_t num_fixed_params = DecodeOperandA().value();
  const intptr_t num_opt_pos_params = DecodeOperandB().value();
  const intptr_t num_opt_named_params = DecodeOperandC().value();

  ASSERT(num_fixed_params == function().num_fixed_parameters());
  ASSERT(num_opt_pos_params == function().NumOptionalPositionalParameters());
  ASSERT(num_opt_named_params == function().NumOptionalNamedParameters());

  ASSERT((num_opt_pos_params == 0) || (num_opt_named_params == 0));
  const intptr_t num_load_const = num_opt_pos_params + 2 * num_opt_named_params;

  const KBCInstr* instr = KernelBytecode::Next(bytecode_instr_);
  const KBCInstr* frame_instr = instr;
  for (intptr_t i = 0; i < num_load_const; ++i) {
    frame_instr = KernelBytecode::Next(frame_instr);
  }
  ASSERT(KernelBytecode::IsFrameOpcode(frame_instr));
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

  intptr_t param = 0;
  for (; param < num_fixed_params; ++param) {
    LocalVariable* param_var = AllocateParameter(param, VariableIndex(-param));
    raw_parameters->Add(param_var);
  }

  for (intptr_t i = 0; i < num_opt_pos_params; ++i, ++param) {
    const KBCInstr* load_value_instr = instr;
    instr = KernelBytecode::Next(instr);
    ASSERT(KernelBytecode::IsLoadConstantOpcode(load_value_instr));
    ASSERT(KernelBytecode::DecodeA(load_value_instr) == param);
    const Object& default_value =
        ConstantAt(Operand(KernelBytecode::DecodeE(load_value_instr))).value();

    LocalVariable* param_var = AllocateParameter(param, VariableIndex(-param));
    raw_parameters->Add(param_var);
    default_values->Add(
        &Instance::ZoneHandle(Z, Instance::RawCast(default_value.raw())));
  }

  if (num_opt_named_params > 0) {
    default_values->EnsureLength(num_opt_named_params, nullptr);
    raw_parameters->EnsureLength(num_params, nullptr);

    ASSERT(scratch_var_ != nullptr);

    for (intptr_t i = 0; i < num_opt_named_params; ++i, ++param) {
      const KBCInstr* load_name_instr = instr;
      const KBCInstr* load_value_instr = KernelBytecode::Next(load_name_instr);
      instr = KernelBytecode::Next(load_value_instr);
      ASSERT(KernelBytecode::IsLoadConstantOpcode(load_name_instr));
      ASSERT(KernelBytecode::IsLoadConstantOpcode(load_value_instr));
      const String& param_name = String::Cast(
          ConstantAt(Operand(KernelBytecode::DecodeE(load_name_instr)))
              .value());
      ASSERT(param_name.IsSymbol());
      const Object& default_value =
          ConstantAt(Operand(KernelBytecode::DecodeE(load_value_instr)))
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

  ASSERT(instr == frame_instr);

  parsed_function()->set_default_parameter_values(default_values);
  parsed_function()->SetRawParameters(raw_parameters);

  return KernelBytecode::Next(frame_instr);
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

intptr_t BytecodeFlowGraphBuilder::GetStackDepth() const {
  ASSERT(!is_generating_interpreter());
  return B->GetStackDepth();
}

bool BytecodeFlowGraphBuilder::IsStackEmpty() const {
  ASSERT(!is_generating_interpreter());
  return B->GetStackDepth() == 0;
}

InferredTypeMetadata BytecodeFlowGraphBuilder::GetInferredType(intptr_t pc) {
  ASSERT(!inferred_types_attribute_.IsNull());
  intptr_t i = inferred_types_index_;
  const intptr_t len = inferred_types_attribute_.Length();
  for (; i < len; i += InferredTypeBytecodeAttribute::kNumElements) {
    ASSERT(i + InferredTypeBytecodeAttribute::kNumElements <= len);
    const intptr_t attr_pc =
        InferredTypeBytecodeAttribute::GetPCAt(inferred_types_attribute_, i);
    if (attr_pc == pc) {
      const InferredTypeMetadata result =
          InferredTypeBytecodeAttribute::GetInferredTypeAt(
              Z, inferred_types_attribute_, i);
      // Found. Next time, continue search at the next entry.
      inferred_types_index_ = i + InferredTypeBytecodeAttribute::kNumElements;
      return result;
    }
    if (attr_pc > pc) {
      break;
    }
  }
  // Not found. Next time, continue search at the last inspected entry.
  inferred_types_index_ = i;
  return InferredTypeMetadata(kDynamicCid, InferredTypeMetadata::kFlagNullable);
}

void BytecodeFlowGraphBuilder::PropagateStackState(intptr_t target_pc) {
  if (is_generating_interpreter() || IsStackEmpty()) {
    return;
  }

  Value* current_stack = B->stack_;
  Value* target_stack = stack_states_.Lookup(target_pc);

  if (target_stack != nullptr) {
    // Control flow join should observe the same stack state from
    // all incoming branches.
    RELEASE_ASSERT(target_stack == current_stack);
  } else {
    // Stack state propagation is supported for forward branches only.
    RELEASE_ASSERT(target_pc > pc_);
    stack_states_.Insert(target_pc, current_stack);
  }
}

// Drop values from the stack unless they are used in control flow joins
// which are not generated yet (dartbug.com/36374).
void BytecodeFlowGraphBuilder::DropUnusedValuesFromStack() {
  intptr_t drop_depth = GetStackDepth();
  auto it = stack_states_.GetIterator();
  for (const auto* current = it.Next(); current != nullptr;
       current = it.Next()) {
    if (current->key > pc_) {
      Value* used_value = current->value;
      Value* value = B->stack_;
      // Find if a value on the expression stack is used in a propagated
      // stack state, and adjust [drop_depth] to preserve it.
      for (intptr_t i = 0; i < drop_depth; ++i) {
        if (value == used_value) {
          drop_depth = i;
          break;
        }
        value = value->next_use();
      }
    }
  }
  for (intptr_t i = 0; i < drop_depth; ++i) {
    B->Pop();
  }
}

void BytecodeFlowGraphBuilder::BuildInstruction(KernelBytecode::Opcode opcode) {
  switch (opcode) {
#define WIDE_CASE(name) case KernelBytecode::k##name##_Wide:
#define WIDE_CASE_0(name)
#define WIDE_CASE_A(name)
#define WIDE_CASE_D(name) WIDE_CASE(name)
#define WIDE_CASE_X(name) WIDE_CASE(name)
#define WIDE_CASE_T(name) WIDE_CASE(name)
#define WIDE_CASE_A_E(name) WIDE_CASE(name)
#define WIDE_CASE_A_Y(name) WIDE_CASE(name)
#define WIDE_CASE_D_F(name) WIDE_CASE(name)
#define WIDE_CASE_A_B_C(name)

#define BUILD_BYTECODE_CASE(name, encoding, kind, op1, op2, op3)               \
  BUILD_BYTECODE_CASE_##kind(name, encoding)

#define BUILD_BYTECODE_CASE_WIDE(name, encoding)
#define BUILD_BYTECODE_CASE_RESV(name, encoding)
#define BUILD_BYTECODE_CASE_ORDN(name, encoding)                               \
  case KernelBytecode::k##name:                                                \
    WIDE_CASE_##encoding(name) Build##name();                                  \
    break;

    PUBLIC_KERNEL_BYTECODES_LIST(BUILD_BYTECODE_CASE)

#undef WIDE_CASE
#undef WIDE_CASE_0
#undef WIDE_CASE_A
#undef WIDE_CASE_D
#undef WIDE_CASE_X
#undef WIDE_CASE_T
#undef WIDE_CASE_A_E
#undef WIDE_CASE_A_Y
#undef WIDE_CASE_D_F
#undef WIDE_CASE_A_B_C
#undef BUILD_BYTECODE_CASE
#undef BUILD_BYTECODE_CASE_WIDE
#undef BUILD_BYTECODE_CASE_RESV
#undef BUILD_BYTECODE_CASE_ORDN

    default:
      FATAL1("Unsupported bytecode instruction %s\n",
             KernelBytecode::NameOf(opcode));
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

  AllocateLocalVariables(DecodeOperandE());
  AllocateFixedParameters();

  Fragment check_args;

  ASSERT(throw_no_such_method_ == nullptr);
  throw_no_such_method_ = B->BuildThrowNoSuchMethod();

  check_args += B->LoadArgDescriptor();
  check_args +=
      B->LoadNativeField(Slot::ArgumentsDescriptor_positional_count());
  check_args += B->IntConstant(num_fixed_params);
  TargetEntryInstr *success1, *fail1;
  check_args += B->BranchIfEqual(&success1, &fail1);
  check_args = Fragment(check_args.entry, success1);

  check_args += B->LoadArgDescriptor();
  check_args += B->LoadNativeField(Slot::ArgumentsDescriptor_count());
  check_args += B->IntConstant(num_fixed_params);
  TargetEntryInstr *success2, *fail2;
  check_args += B->BranchIfEqual(&success2, &fail2);
  check_args = Fragment(check_args.entry, success2);

  Fragment(fail1) + B->Goto(throw_no_such_method_);
  Fragment(fail2) + B->Goto(throw_no_such_method_);

  ASSERT(IsStackEmpty());

  if (!B->IsInlining() && !B->IsCompiledForOsr()) {
    code_ += check_args;
  }
}

void BytecodeFlowGraphBuilder::BuildEntryOptional() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  const KBCInstr* next_instr = AllocateParametersAndLocalsForEntryOptional();

  LocalVariable* temp_var = nullptr;
  if (function().HasOptionalNamedParameters()) {
    ASSERT(scratch_var_ != nullptr);
    temp_var = scratch_var_;
  }

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

  copy_args_prologue += prologue_builder.BuildOptionalParameterHandling(
      throw_no_such_method_, temp_var);

  B->last_used_block_id_ = prologue_builder.last_used_block_id();

  JoinEntryInstr* prologue_exit = B->BuildJoinEntry();
  copy_args_prologue += B->Goto(prologue_exit);
  copy_args_prologue.current = prologue_exit;

  if (!B->IsInlining() && !B->IsCompiledForOsr()) {
    code_ += copy_args_prologue;
  }

  prologue_info_ =
      PrologueInfo(prologue_entry->block_id(), prologue_exit->block_id() - 1);

  // Skip LoadConstant and Frame instructions.
  next_pc_ = pc_ + (next_instr - bytecode_instr_);

  ASSERT(IsStackEmpty());
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
  LocalVariable* type_args_var = LocalVariableAt(DecodeOperandE().value());

  if (throw_no_such_method_ == nullptr) {
    throw_no_such_method_ = B->BuildThrowNoSuchMethod();
  }

  Fragment setup_type_args;
  JoinEntryInstr* done = B->BuildJoinEntry();

  // Type args are always optional, so length can always be zero.
  // If expect_type_args, a non-zero length must match the declaration length.
  TargetEntryInstr *then, *fail;
  setup_type_args += B->LoadArgDescriptor();
  setup_type_args +=
      B->LoadNativeField(Slot::ArgumentsDescriptor_type_args_len());

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
    store_type_args += B->LoadNativeField(Slot::ArgumentsDescriptor_count());
    store_type_args += B->LoadFpRelativeSlot(
        compiler::target::kWordSize *
            (1 + compiler::target::frame_layout.param_end_from_fp),
        CompileType::CreateNullable(/*is_nullable=*/true, kTypeArgumentsCid));
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
  ASSERT(IsStackEmpty());

  if (expected_num_type_args != 0) {
    parsed_function()->set_function_type_arguments(type_args_var);
    parsed_function()->SetRawTypeArgumentsVariable(type_args_var);
  }

  if (!B->IsInlining() && !B->IsCompiledForOsr()) {
    code_ += setup_type_args;
  }
}

void BytecodeFlowGraphBuilder::BuildCheckStack() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }
  const intptr_t loop_depth = DecodeOperandA().value();
  if (loop_depth == 0) {
    ASSERT(IsStackEmpty());
    code_ += B->CheckStackOverflowInPrologue(position_);
  } else {
    const intptr_t stack_depth = B->GetStackDepth();
    code_ += B->CheckStackOverflow(position_, stack_depth, loop_depth);
  }
}

void BytecodeFlowGraphBuilder::BuildDebugCheck() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }
  // DebugStepCheck instructions are emitted for all explicit DebugCheck
  // opcodes as well as for implicit DEBUG_CHECK executed by the interpreter
  // for some opcodes, but not before the first explicit DebugCheck opcode is
  // encountered.
  build_debug_step_checks_ = true;
  BuildDebugStepCheck();
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

void BytecodeFlowGraphBuilder::BuildDirectCallCommon(bool is_unchecked_call) {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  // A DebugStepCheck is performed as part of the calling stub.

  const Function& target = Function::Cast(ConstantAt(DecodeOperandD()).value());
  const intptr_t argc = DecodeOperandF().value();

  switch (target.recognized_kind()) {
    case MethodRecognizer::kFfiAsFunctionInternal:
      BuildFfiAsFunction();
      return;
    case MethodRecognizer::kFfiNativeCallbackFunction:
      if (CompilerState::Current().is_aot()) {
        BuildFfiNativeCallbackFunction();
        return;
      }
      break;
    case MethodRecognizer::kObjectIdentical:
      // Note: similar optimization is performed in AST flow graph builder -
      // see StreamingFlowGraphBuilder::BuildStaticInvocation,
      // special_case_identical.
      // TODO(alexmarkov): find a better place for this optimization.
      ASSERT(argc == 2);
      code_ += B->StrictCompare(Token::kEQ_STRICT, /*number_check=*/true);
      return;
    case MethodRecognizer::kAsyncStackTraceHelper:
    case MethodRecognizer::kSetAsyncThreadStackTrace:
      if (!FLAG_causal_async_stacks) {
        ASSERT(argc == 1);
        // Drop the ignored parameter to _asyncStackTraceHelper(:async_op) or
        // _setAsyncThreadStackTrace(stackTrace).
        code_ += B->Drop();
        code_ += B->NullConstant();
        return;
      }
      break;
    case MethodRecognizer::kClearAsyncThreadStackTrace:
      if (!FLAG_causal_async_stacks) {
        ASSERT(argc == 0);
        code_ += B->NullConstant();
        return;
      }
      break;
    case MethodRecognizer::kStringBaseInterpolate:
      ASSERT(argc == 1);
      code_ += B->StringInterpolate(position_);
      return;
    default:
      break;
  }

  const Array& arg_desc_array =
      Array::Cast(ConstantAt(DecodeOperandD(), 1).value());
  const ArgumentsDescriptor arg_desc(arg_desc_array);

  InputsArray* arguments = B->GetArguments(argc);

  StaticCallInstr* call = new (Z) StaticCallInstr(
      position_, target, arg_desc.TypeArgsLen(),
      Array::ZoneHandle(Z, arg_desc.GetArgumentNames()), arguments,
      *ic_data_array_, B->GetNextDeoptId(),
      target.IsDynamicFunction() ? ICData::kSuper : ICData::kStatic);

  if (is_unchecked_call) {
    call->set_entry_kind(Code::EntryKind::kUnchecked);
  }

  if (!call->InitResultType(Z)) {
    if (!inferred_types_attribute_.IsNull()) {
      const InferredTypeMetadata result_type = GetInferredType(pc_);
      if (!result_type.IsTrivial()) {
        call->SetResultType(Z, result_type.ToCompileType(Z));
      }
    }
  }

  code_ <<= call;
  B->Push(call);
}

void BytecodeFlowGraphBuilder::BuildDirectCall() {
  BuildDirectCallCommon(/* is_unchecked_call = */ false);
}

void BytecodeFlowGraphBuilder::BuildUncheckedDirectCall() {
  BuildDirectCallCommon(/* is_unchecked_call = */ true);
}

static void ComputeTokenKindAndCheckedArguments(
    const String& name,
    const ArgumentsDescriptor& arg_desc,
    Token::Kind* token_kind,
    intptr_t* checked_argument_count) {
  *token_kind = MethodTokenRecognizer::RecognizeTokenKind(name);

  *checked_argument_count = 1;
  if (*token_kind != Token::kILLEGAL) {
    intptr_t argument_count = arg_desc.Count();
    ASSERT(argument_count <= 2);
    *checked_argument_count = (*token_kind == Token::kSET) ? 1 : argument_count;
  } else if (Library::IsPrivateCoreLibName(name,
                                           Symbols::_simpleInstanceOf())) {
    ASSERT(arg_desc.Count() == 2);
    *checked_argument_count = 2;
    *token_kind = Token::kIS;
  } else if (Library::IsPrivateCoreLibName(name, Symbols::_instanceOf())) {
    ASSERT(arg_desc.Count() == 4);
    *token_kind = Token::kIS;
  }
}

void BytecodeFlowGraphBuilder::BuildInterfaceCallCommon(
    bool is_unchecked_call,
    bool is_instantiated_call) {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  // A DebugStepCheck is performed as part of the calling stub.

  const Function& interface_target =
      Function::Cast(ConstantAt(DecodeOperandD()).value());
  const String& name = String::ZoneHandle(Z, interface_target.name());
  ASSERT(name.IsSymbol());

  const Array& arg_desc_array =
      Array::Cast(ConstantAt(DecodeOperandD(), 1).value());
  const ArgumentsDescriptor arg_desc(arg_desc_array);

  Token::Kind token_kind;
  intptr_t checked_argument_count;
  ComputeTokenKindAndCheckedArguments(name, arg_desc, &token_kind,
                                      &checked_argument_count);

  const intptr_t argc = DecodeOperandF().value();
  InputsArray* arguments = B->GetArguments(argc);

  InstanceCallInstr* call = new (Z) InstanceCallInstr(
      position_, name, token_kind, arguments, arg_desc.TypeArgsLen(),
      Array::ZoneHandle(Z, arg_desc.GetArgumentNames()), checked_argument_count,
      *ic_data_array_, B->GetNextDeoptId(), interface_target);

  if (!inferred_types_attribute_.IsNull()) {
    const InferredTypeMetadata result_type = GetInferredType(pc_);
    if (!result_type.IsTrivial()) {
      call->SetResultType(Z, result_type.ToCompileType(Z));
    }
  }

  if (is_unchecked_call) {
    call->set_entry_kind(Code::EntryKind::kUnchecked);
  }

  if (is_instantiated_call) {
    const AbstractType& static_receiver_type =
        AbstractType::Cast(ConstantAt(DecodeOperandD(), 2).value());
    call->set_receivers_static_type(&static_receiver_type);
  } else {
    const Class& owner = Class::Handle(Z, interface_target.Owner());
    const AbstractType& type =
        AbstractType::ZoneHandle(Z, owner.DeclarationType());
    call->set_receivers_static_type(&type);
  }

  code_ <<= call;
  B->Push(call);
}

void BytecodeFlowGraphBuilder::BuildInterfaceCall() {
  BuildInterfaceCallCommon(/*is_unchecked_call=*/false,
                           /*is_instantiated_call=*/false);
}

void BytecodeFlowGraphBuilder::BuildInstantiatedInterfaceCall() {
  BuildInterfaceCallCommon(/*is_unchecked_call=*/false,
                           /*is_instantiated_call=*/true);
}

void BytecodeFlowGraphBuilder::BuildUncheckedInterfaceCall() {
  BuildInterfaceCallCommon(/*is_unchecked_call=*/true,
                           /*is_instantiated_call=*/false);
}

void BytecodeFlowGraphBuilder::BuildUncheckedClosureCall() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  BuildDebugStepCheck();

  const Array& arg_desc_array =
      Array::Cast(ConstantAt(DecodeOperandD()).value());
  const ArgumentsDescriptor arg_desc(arg_desc_array);

  const intptr_t argc = DecodeOperandF().value();

  LocalVariable* receiver_temp = B->MakeTemporary();
  code_ += B->CheckNull(position_, receiver_temp, Symbols::Call(),
                        /*clear_temp=*/false);

  code_ += B->LoadNativeField(Slot::Closure_function());

  InputsArray* arguments = B->GetArguments(argc + 1);

  ClosureCallInstr* call = new (Z) ClosureCallInstr(
      arguments, arg_desc.TypeArgsLen(),
      Array::ZoneHandle(Z, arg_desc.GetArgumentNames()), position_,
      B->GetNextDeoptId(), Code::EntryKind::kUnchecked);

  // TODO(alexmarkov): use inferred result type for ClosureCallInstr
  //  if (!inferred_types_attribute_.IsNull()) {
  //    const InferredTypeMetadata result_type = GetInferredType(pc_);
  //    if (!result_type.IsTrivial()) {
  //      call->SetResultType(Z, result_type.ToCompileType(Z));
  //    }
  //  }

  code_ <<= call;
  B->Push(call);
}

void BytecodeFlowGraphBuilder::BuildDynamicCall() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  // A DebugStepCheck is performed as part of the calling stub.

  const String& name = String::Cast(ConstantAt(DecodeOperandD()).value());
  const ArgumentsDescriptor arg_desc(
      Array::Cast(ConstantAt(DecodeOperandD(), 1).value()));

  Token::Kind token_kind;
  intptr_t checked_argument_count;
  ComputeTokenKindAndCheckedArguments(name, arg_desc, &token_kind,
                                      &checked_argument_count);

  const intptr_t argc = DecodeOperandF().value();
  InputsArray* arguments = B->GetArguments(argc);

  const Function& interface_target = Function::null_function();

  InstanceCallInstr* call = new (Z) InstanceCallInstr(
      position_, name, token_kind, arguments, arg_desc.TypeArgsLen(),
      Array::ZoneHandle(Z, arg_desc.GetArgumentNames()), checked_argument_count,
      *ic_data_array_, B->GetNextDeoptId(), interface_target);

  if (!inferred_types_attribute_.IsNull()) {
    const InferredTypeMetadata result_type = GetInferredType(pc_);
    if (!result_type.IsTrivial()) {
      call->SetResultType(Z, result_type.ToCompileType(Z));
    }
  }

  code_ <<= call;
  B->Push(call);
}

void BytecodeFlowGraphBuilder::BuildNativeCall() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  ASSERT(function().is_native());
  B->InlineBailout("BytecodeFlowGraphBuilder::BuildNativeCall");

  const auto& name = String::ZoneHandle(Z, function().native_name());
  const intptr_t num_args =
      function().NumParameters() + (function().IsGeneric() ? 1 : 0);
  InputsArray* arguments = B->GetArguments(num_args);
  auto* call =
      new (Z) NativeCallInstr(&name, &function(), FLAG_link_natives_lazily,
                              function().end_token_pos(), arguments);
  code_ <<= call;
  B->Push(call);
}

void BytecodeFlowGraphBuilder::BuildAllocate() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  const Class& klass = Class::Cast(ConstantAt(DecodeOperandD()).value());

  AllocateObjectInstr* allocate = new (Z) AllocateObjectInstr(position_, klass);

  code_ <<= allocate;
  B->Push(allocate);
}

void BytecodeFlowGraphBuilder::BuildAllocateT() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  const Class& klass = Class::Cast(PopConstant().value());
  Value* type_arguments = Pop();

  AllocateObjectInstr* allocate =
      new (Z) AllocateObjectInstr(position_, klass, type_arguments);

  code_ <<= allocate;
  B->Push(allocate);
}

void BytecodeFlowGraphBuilder::BuildAllocateContext() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  const intptr_t context_id = DecodeOperandA().value();
  const intptr_t num_context_vars = DecodeOperandE().value();

  auto& context_slots = CompilerState::Current().GetDummyContextSlots(
      context_id, num_context_vars);
  code_ += B->AllocateContext(context_slots);
}

void BytecodeFlowGraphBuilder::BuildCloneContext() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  LoadStackSlots(1);
  const intptr_t context_id = DecodeOperandA().value();
  const intptr_t num_context_vars = DecodeOperandE().value();

  auto& context_slots = CompilerState::Current().GetDummyContextSlots(
      context_id, num_context_vars);
  CloneContextInstr* clone_instruction = new (Z) CloneContextInstr(
      TokenPosition::kNoSource, Pop(), context_slots, B->GetNextDeoptId());
  code_ <<= clone_instruction;
  B->Push(clone_instruction);
}

void BytecodeFlowGraphBuilder::BuildCreateArrayTOS() {
  LoadStackSlots(2);
  code_ += B->CreateArray();
}

const Slot& ClosureSlotByField(const Field& field) {
  const intptr_t offset = field.HostOffset();
  if (offset == Closure::instantiator_type_arguments_offset()) {
    return Slot::Closure_instantiator_type_arguments();
  } else if (offset == Closure::function_type_arguments_offset()) {
    return Slot::Closure_function_type_arguments();
  } else if (offset == Closure::delayed_type_arguments_offset()) {
    return Slot::Closure_delayed_type_arguments();
  } else if (offset == Closure::function_offset()) {
    return Slot::Closure_function();
  } else if (offset == Closure::context_offset()) {
    return Slot::Closure_context();
  } else {
    RELEASE_ASSERT(offset == Closure::hash_offset());
    return Slot::Closure_hash();
  }
}

void BytecodeFlowGraphBuilder::BuildStoreFieldTOS() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  LoadStackSlots(2);
  Operand cp_index = DecodeOperandD();

  const Field& field = Field::Cast(ConstantAt(cp_index, 1).value());
  ASSERT(Smi::Cast(ConstantAt(cp_index).value()).Value() * kWordSize ==
         field.HostOffset());

  if (field.Owner() == isolate()->object_store()->closure_class()) {
    // Stores to _Closure fields are lower-level.
    code_ +=
        B->StoreInstanceField(position_, ClosureSlotByField(field),
                              StoreInstanceFieldInstr::Kind::kInitializing);
  } else {
    // The rest of the StoreFieldTOS are for field initializers.
    // TODO(alexmarkov): Consider adding a flag to StoreFieldTOS or even
    // adding a separate bytecode instruction.
    code_ += B->StoreInstanceFieldGuarded(
        field, StoreInstanceFieldInstr::Kind::kInitializing);
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
         field.HostOffset());

  if (field.Owner() == isolate()->object_store()->closure_class()) {
    // Loads from _Closure fields are lower-level.
    code_ += B->LoadNativeField(ClosureSlotByField(field));
  } else {
    code_ += B->LoadField(field, /*calls_initializer=*/false);
  }
}

void BytecodeFlowGraphBuilder::BuildStoreContextParent() {
  LoadStackSlots(2);

  code_ += B->StoreInstanceField(position_, Slot::Context_parent(),
                                 StoreInstanceFieldInstr::Kind::kInitializing);
}

void BytecodeFlowGraphBuilder::BuildLoadContextParent() {
  LoadStackSlots(1);

  code_ += B->LoadNativeField(Slot::Context_parent());
}

void BytecodeFlowGraphBuilder::BuildStoreContextVar() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  LoadStackSlots(2);
  const intptr_t context_id = DecodeOperandA().value();
  const intptr_t var_index = DecodeOperandE().value();

  auto var =
      CompilerState::Current().GetDummyCapturedVariable(context_id, var_index);
  code_ += B->StoreInstanceField(
      position_, Slot::GetContextVariableSlotFor(thread(), *var));
}

void BytecodeFlowGraphBuilder::BuildLoadContextVar() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  LoadStackSlots(1);
  const intptr_t context_id = DecodeOperandA().value();
  const intptr_t var_index = DecodeOperandE().value();

  auto var =
      CompilerState::Current().GetDummyCapturedVariable(context_id, var_index);
  code_ += B->LoadNativeField(Slot::GetContextVariableSlotFor(thread(), *var));
}

void BytecodeFlowGraphBuilder::BuildLoadTypeArgumentsField() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  LoadStackSlots(1);
  const intptr_t offset =
      Smi::Cast(ConstantAt(DecodeOperandD()).value()).Value() *
      compiler::target::kWordSize;

  code_ += B->LoadNativeField(Slot::GetTypeArgumentsSlotAt(thread(), offset));
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

void BytecodeFlowGraphBuilder::BuildInitLateField() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  LoadStackSlots(1);
  Operand cp_index = DecodeOperandD();

  const Field& field = Field::Cast(ConstantAt(cp_index, 1).value());
  ASSERT(Smi::Cast(ConstantAt(cp_index).value()).Value() * kWordSize ==
         field.HostOffset());

  code_ += B->Constant(Object::sentinel());
  code_ += B->StoreInstanceField(
      field, StoreInstanceFieldInstr::Kind::kInitializing, kNoStoreBarrier);
}

void BytecodeFlowGraphBuilder::BuildPushUninitializedSentinel() {
  code_ += B->Constant(Object::sentinel());
}

void BytecodeFlowGraphBuilder::BuildJumpIfInitialized() {
  code_ += B->Constant(Object::sentinel());
  BuildJumpIfStrictCompare(Token::kNE);
}

void BytecodeFlowGraphBuilder::BuildLoadStatic() {
  const Constant operand = ConstantAt(DecodeOperandD());
  const auto& field = Field::Cast(operand.value());
  // All constant expressions (including access to const fields) are evaluated
  // in bytecode. However, values of injected cid fields are only available in
  // the VM. In such case, evaluate const fields with known value here.
  if (field.is_const() && !field.has_nontrivial_initializer()) {
    const auto& value = Object::ZoneHandle(Z, field.StaticValue());
    ASSERT((value.raw() != Object::sentinel().raw()) &&
           (value.raw() != Object::transition_sentinel().raw()));
    code_ += B->Constant(value);
    return;
  }
  code_ += B->LoadStaticField(field, /*calls_initializer=*/false);
}

void BytecodeFlowGraphBuilder::BuildStoreIndexedTOS() {
  LoadStackSlots(3);
  code_ += B->StoreIndexed(kArrayCid);
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
      TypeArguments::Cast(ConstantAt(DecodeOperandE()).value());

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

  const AbstractType& dst_type =
      AbstractType::Cast(B->Peek(/*depth=*/3)->AsConstant()->value());
  if (dst_type.IsTopTypeForSubtyping()) {
    code_ += B->Drop();  // dst_name
    code_ += B->Drop();  // function_type_args
    code_ += B->Drop();  // instantiator_type_args
    code_ += B->Drop();  // dst_type
    // Leave value on top.
    return;
  }

  const String& dst_name = String::Cast(PopConstant().value());
  Value* function_type_args = Pop();
  Value* instantiator_type_args = Pop();
  Value* dst_type_value = Pop();
  Value* value = Pop();

  AssertAssignableInstr* instr = new (Z) AssertAssignableInstr(
      position_, value, dst_type_value, instantiator_type_args,
      function_type_args, dst_name, B->GetNextDeoptId());

  code_ <<= instr;

  B->Push(instr);
}

void BytecodeFlowGraphBuilder::BuildAssertSubtype() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  LoadStackSlots(5);

  const String& dst_name = String::Cast(PopConstant().value());
  Value* super_type = Pop();
  Value* sub_type = Pop();
  Value* function_type_args = Pop();
  Value* instantiator_type_args = Pop();

  AssertSubtypeInstr* instr = new (Z)
      AssertSubtypeInstr(position_, instantiator_type_args, function_type_args,
                         sub_type, super_type, dst_name, B->GetNextDeoptId());
  code_ <<= instr;
}

void BytecodeFlowGraphBuilder::BuildNullCheck() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  const String& selector =
      String::CheckedZoneHandle(Z, ConstantAt(DecodeOperandD()).value().raw());

  LocalVariable* receiver_temp = B->MakeTemporary();
  code_ +=
      B->CheckNull(position_, receiver_temp, selector, /*clear_temp=*/false);
  code_ += B->Drop();
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
  ASSERT(IsStackEmpty());
  if (!isolate()->asserts()) {
    BuildJump();
    // Skip all instructions up to the target PC, as they are all unreachable.
    // If not skipped, some of the assert code may be considered reachable
    // (if it contains jumps) and generated. The problem is that generated
    // code may expect values left on the stack from unreachable
    // (and not generated) code which immediately follows this Jump.
    next_pc_ = pc_ + DecodeOperandT().value();
    ASSERT(next_pc_ > pc_);
  }
}

void BytecodeFlowGraphBuilder::BuildJumpIfNotZeroTypeArgs() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  TargetEntryInstr *is_zero, *is_not_zero;
  code_ += B->LoadArgDescriptor();
  code_ += B->LoadNativeField(Slot::ArgumentsDescriptor_type_args_len());
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

  // Fallthrough should correspond to 'then' branch target.
  // This results in a slightly better regalloc.
  TargetEntryInstr* then_entry = nullptr;
  TargetEntryInstr* else_entry = nullptr;
  code_ += B->BranchIfEqual(&then_entry, &else_entry,
                            /* negate = */ (cmp_kind == Token::kEQ));

  const intptr_t target_pc = pc_ + DecodeOperandT().value();
  JoinEntryInstr* join = jump_targets_.Lookup(target_pc);
  ASSERT(join != nullptr);

  code_ = Fragment(else_entry);
  code_ += B->Goto(join);
  PropagateStackState(target_pc);

  code_ = Fragment(then_entry);
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

void BytecodeFlowGraphBuilder::BuildJumpIfUnchecked() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  ASSERT(IsStackEmpty());

  const intptr_t target_pc = pc_ + DecodeOperandT().value();
  JoinEntryInstr* target = jump_targets_.Lookup(target_pc);
  ASSERT(target != nullptr);
  FunctionEntryInstr* unchecked_entry = nullptr;
  const intptr_t kCheckedEntry =
      static_cast<intptr_t>(UncheckedEntryPointStyle::kNone);
  const intptr_t kUncheckedEntry =
      static_cast<intptr_t>(UncheckedEntryPointStyle::kSharedWithVariable);

  switch (entry_point_style_) {
    case UncheckedEntryPointStyle::kNone: {
      JoinEntryInstr* do_checks = B->BuildJoinEntry();
      code_ += B->Goto(B->InliningUncheckedEntry() ? target : do_checks);
      code_ = Fragment(do_checks);
    } break;

    case UncheckedEntryPointStyle::kSeparate: {
      // Route normal entry to checks.
      if (FLAG_enable_testing_pragmas) {
        code_ += B->IntConstant(kCheckedEntry);
        code_ += B->BuildEntryPointsIntrospection();
      }
      Fragment do_checks = code_;

      // Create a separate unchecked entry point.
      unchecked_entry = B->BuildFunctionEntry(graph_entry_);
      code_ = Fragment(unchecked_entry);

      // Re-build prologue for unchecked entry point. It can only contain
      // Entry, CheckStack and DebugCheck instructions.
      bytecode_instr_ = raw_bytecode_;
      ASSERT(KernelBytecode::IsEntryOpcode(bytecode_instr_));
      bytecode_instr_ = KernelBytecode::Next(bytecode_instr_);
      while (!KernelBytecode::IsJumpIfUncheckedOpcode(bytecode_instr_)) {
        ASSERT(KernelBytecode::IsCheckStackOpcode(bytecode_instr_) ||
               KernelBytecode::IsDebugCheckOpcode(bytecode_instr_));
        ASSERT(jump_targets_.Lookup(bytecode_instr_ - raw_bytecode_) ==
               nullptr);
        BuildInstruction(KernelBytecode::DecodeOpcode(bytecode_instr_));
        bytecode_instr_ = KernelBytecode::Next(bytecode_instr_);
      }
      ASSERT((bytecode_instr_ - raw_bytecode_) == pc_);

      if (FLAG_enable_testing_pragmas) {
        code_ += B->IntConstant(
            static_cast<intptr_t>(UncheckedEntryPointStyle::kSeparate));
        code_ += B->BuildEntryPointsIntrospection();
      }
      code_ += B->Goto(target);

      code_ = do_checks;
    } break;

    case UncheckedEntryPointStyle::kSharedWithVariable: {
      LocalVariable* ep_var = parsed_function()->entry_points_temp_var();

      // Dispatch based on the value of entry_points_temp_var.
      TargetEntryInstr *do_checks, *skip_checks;
      if (FLAG_enable_testing_pragmas) {
        code_ += B->LoadLocal(ep_var);
        code_ += B->BuildEntryPointsIntrospection();
      }
      code_ += B->LoadLocal(ep_var);
      code_ += B->IntConstant(kUncheckedEntry);
      code_ += B->BranchIfEqual(&skip_checks, &do_checks, /*negate=*/false);

      code_ = Fragment(skip_checks);
      code_ += B->Goto(target);

      // Relink the body of the function from normal entry to 'prologue_join'.
      JoinEntryInstr* prologue_join = B->BuildJoinEntry();
      FunctionEntryInstr* normal_entry = graph_entry_->normal_entry();
      if (normal_entry->next() != nullptr) {
        prologue_join->LinkTo(normal_entry->next());
        normal_entry->set_next(nullptr);
      }

      unchecked_entry = B->BuildFunctionEntry(graph_entry_);
      code_ = Fragment(unchecked_entry);
      code_ += B->IntConstant(kUncheckedEntry);
      code_ += B->StoreLocal(TokenPosition::kNoSource, ep_var);
      code_ += B->Drop();
      code_ += B->Goto(prologue_join);

      code_ = Fragment(normal_entry);
      code_ += B->IntConstant(kCheckedEntry);
      code_ += B->StoreLocal(TokenPosition::kNoSource, ep_var);
      code_ += B->Drop();
      code_ += B->Goto(prologue_join);

      code_ = Fragment(do_checks);
    } break;
  }

  if (unchecked_entry != nullptr) {
    B->RecordUncheckedEntryPoint(graph_entry_, unchecked_entry);
  }
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
  BuildDebugStepCheck();
  LoadStackSlots(1);
  ASSERT(code_.is_open());
  intptr_t yield_index = PcDescriptorsLayout::kInvalidYieldIndex;
  if (function().IsAsyncClosure() || function().IsAsyncGenClosure()) {
    if (pc_ == last_yield_point_pc_) {
      // The return might actually be a yield point, if so we need to attach the
      // yield index to the return instruction.
      yield_index = last_yield_point_index_;
    }
  }
  code_ += B->Return(position_, yield_index);
  ASSERT(IsStackEmpty());
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
    Value* exception = Pop();
    code_ +=
        Fragment(new (Z) ThrowInstr(position_, B->GetNextDeoptId(), exception))
            .closed();
  } else {
    // rethrow
    LoadStackSlots(2);
    Value* stacktrace = Pop();
    Value* exception = Pop();
    code_ += Fragment(new (Z) ReThrowInstr(position_, kInvalidTryIndex,
                                           B->GetNextDeoptId(), exception,
                                           stacktrace))
                 .closed();
  }

  ASSERT(code_.is_closed());

  if (!IsStackEmpty()) {
    DropUnusedValuesFromStack();
    B->stack_ = nullptr;
  }
}

void BytecodeFlowGraphBuilder::BuildMoveSpecial() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  LocalVariable* special_var = nullptr;
  switch (DecodeOperandA().value()) {
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
  StoreLocal(DecodeOperandY());
  code_ += B->Drop();
}

void BytecodeFlowGraphBuilder::BuildSetFrame() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  // No-op in compiled code.
  ASSERT(IsStackEmpty());
}

void BytecodeFlowGraphBuilder::BuildEqualsNull() {
  BuildDebugStepCheck();

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

void BytecodeFlowGraphBuilder::BuildPrimitiveOp(
    const String& name,
    Token::Kind token_kind,
    const AbstractType& static_receiver_type,
    int num_args) {
  ASSERT((num_args == 1) || (num_args == 2));
  ASSERT(MethodTokenRecognizer::RecognizeTokenKind(name) == token_kind);

  // A DebugStepCheck is performed as part of the calling stub.

  LoadStackSlots(num_args);
  InputsArray* arguments = B->GetArguments(num_args);

  InstanceCallInstr* call = new (Z) InstanceCallInstr(
      position_, name, token_kind, arguments, 0, Array::null_array(), num_args,
      *ic_data_array_, B->GetNextDeoptId());

  call->set_receivers_static_type(&static_receiver_type);

  code_ <<= call;
  B->Push(call);
}

void BytecodeFlowGraphBuilder::BuildIntOp(const String& name,
                                          Token::Kind token_kind,
                                          int num_args) {
  BuildPrimitiveOp(name, token_kind,
                   AbstractType::ZoneHandle(Z, Type::IntType()), num_args);
}

void BytecodeFlowGraphBuilder::BuildDoubleOp(const String& name,
                                             Token::Kind token_kind,
                                             int num_args) {
  BuildPrimitiveOp(name, token_kind,
                   AbstractType::ZoneHandle(Z, Type::Double()), num_args);
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

void BytecodeFlowGraphBuilder::BuildNegateDouble() {
  BuildDoubleOp(Symbols::UnaryMinus(), Token::kNEGATE, 1);
}

void BytecodeFlowGraphBuilder::BuildAddDouble() {
  BuildDoubleOp(Symbols::Plus(), Token::kADD, 2);
}

void BytecodeFlowGraphBuilder::BuildSubDouble() {
  BuildDoubleOp(Symbols::Minus(), Token::kSUB, 2);
}

void BytecodeFlowGraphBuilder::BuildMulDouble() {
  BuildDoubleOp(Symbols::Star(), Token::kMUL, 2);
}

void BytecodeFlowGraphBuilder::BuildDivDouble() {
  BuildDoubleOp(Symbols::Slash(), Token::kDIV, 2);
}

void BytecodeFlowGraphBuilder::BuildCompareDoubleEq() {
  BuildDoubleOp(Symbols::EqualOperator(), Token::kEQ, 2);
}

void BytecodeFlowGraphBuilder::BuildCompareDoubleGt() {
  BuildDoubleOp(Symbols::RAngleBracket(), Token::kGT, 2);
}

void BytecodeFlowGraphBuilder::BuildCompareDoubleLt() {
  BuildDoubleOp(Symbols::LAngleBracket(), Token::kLT, 2);
}

void BytecodeFlowGraphBuilder::BuildCompareDoubleGe() {
  BuildDoubleOp(Symbols::GreaterEqualOperator(), Token::kGTE, 2);
}

void BytecodeFlowGraphBuilder::BuildCompareDoubleLe() {
  BuildDoubleOp(Symbols::LessEqualOperator(), Token::kLTE, 2);
}

void BytecodeFlowGraphBuilder::BuildAllocateClosure() {
  if (is_generating_interpreter()) {
    UNIMPLEMENTED();  // TODO(alexmarkov): interpreter
  }

  const Function& target = Function::Cast(ConstantAt(DecodeOperandD()).value());
  code_ += B->AllocateClosure(position_, target);
}

// Builds graph for a call to 'dart:ffi::_asFunctionInternal'. The stack must
// look like:
//
// <receiver> => pointer argument
// <type arguments vector> => signatures
// ...
void BytecodeFlowGraphBuilder::BuildFfiAsFunction() {
  // The bytecode FGB doesn't eagerly insert PushArguments, so the type
  // arguments won't be wrapped in a PushArgumentsInstr.
  const TypeArguments& type_args =
      TypeArguments::Cast(B->Peek(/*depth=*/1)->AsConstant()->value());
  // Drop type arguments, preserving pointer.
  code_ += B->DropTempsPreserveTop(1);
  code_ += B->BuildFfiAsFunctionInternalCall(type_args);
}

// Builds graph for a call to 'dart:ffi::_nativeCallbackFunction'.
// The call-site must look like this (guaranteed by the FE which inserts it):
//
//   _nativeCallbackFunction<NativeSignatureType>(target, exceptionalReturn)
//
// Therefore the stack shall look like:
//
// <exceptional return value> => ensured (by FE) to be a constant
// <target> => closure, ensured (by FE) to be a (non-partially-instantiated)
//             static tearoff
// <type args> => [NativeSignatureType]
void BytecodeFlowGraphBuilder::BuildFfiNativeCallbackFunction() {
  const TypeArguments& type_args =
      TypeArguments::Cast(B->Peek(/*depth=*/2)->AsConstant()->value());
  ASSERT(type_args.IsInstantiated() && type_args.Length() == 1);
  const Function& native_sig = Function::Handle(
      Z, Type::CheckedHandle(Z, type_args.TypeAt(0)).signature());

  const Closure& target_closure =
      Closure::Cast(B->Peek(/*depth=*/1)->AsConstant()->value());
  ASSERT(!target_closure.IsNull());
  Function& target = Function::Handle(Z, target_closure.function());
  ASSERT(!target.IsNull() && target.IsImplicitClosureFunction());
  target = target.parent_function();

  const Instance& exceptional_return =
      Instance::Cast(B->Peek(/*depth=*/0)->AsConstant()->value());

  const Function& result =
      Function::ZoneHandle(Z, compiler::ffi::NativeCallbackFunction(
                                  native_sig, target, exceptional_return));
  code_ += B->Constant(result);
  code_ += B->DropTempsPreserveTop(3);
}

void BytecodeFlowGraphBuilder::BuildDebugStepCheck() {
#if !defined(PRODUCT)
  if (build_debug_step_checks_) {
    code_ += B->DebugStepCheck(position_);
  }
#endif  // !defined(PRODUCT)
}

intptr_t BytecodeFlowGraphBuilder::GetTryIndex(const PcDescriptors& descriptors,
                                               intptr_t pc) {
  const uword pc_offset =
      KernelBytecode::BytecodePcToOffset(pc, /* is_return_address = */ true);
  PcDescriptors::Iterator iter(descriptors, PcDescriptorsLayout::kAnyKind);
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

bool BytecodeFlowGraphBuilder::RequiresScratchVar(const KBCInstr* instr) {
  switch (KernelBytecode::DecodeOpcode(instr)) {
    case KernelBytecode::kEntryOptional:
      return KernelBytecode::DecodeC(instr) > 0;

    case KernelBytecode::kEqualsNull:
      return true;

    case KernelBytecode::kNativeCall:
    case KernelBytecode::kNativeCall_Wide:
      return function().recognized_kind() == MethodRecognizer::kListFactory;

    default:
      return false;
  }
}

void BytecodeFlowGraphBuilder::CollectControlFlow(
    const PcDescriptors& descriptors,
    const ExceptionHandlers& handlers,
    GraphEntryInstr* graph_entry) {
  bool seen_jump_if_unchecked = false;
  for (intptr_t pc = 0; pc < bytecode_length_;) {
    const KBCInstr* instr = &(raw_bytecode_[pc]);

    if (KernelBytecode::IsJumpOpcode(instr)) {
      const intptr_t target = pc + KernelBytecode::DecodeT(instr);
      EnsureControlFlowJoin(descriptors, target);

      if (KernelBytecode::IsJumpIfUncheckedOpcode(instr)) {
        if (seen_jump_if_unchecked) {
          FATAL1(
              "Multiple JumpIfUnchecked bytecode instructions are not allowed: "
              "%s.",
              function().ToFullyQualifiedCString());
        }
        seen_jump_if_unchecked = true;
        ASSERT(entry_point_style_ == UncheckedEntryPointStyle::kNone);
        entry_point_style_ = ChooseEntryPointStyle(instr);
        if (entry_point_style_ ==
            UncheckedEntryPointStyle::kSharedWithVariable) {
          parsed_function_->EnsureEntryPointsTemp();
        }
      }
    } else if (KernelBytecode::IsCheckStackOpcode(instr) &&
               (KernelBytecode::DecodeA(instr) != 0)) {
      // (dartbug.com/36590) BlockEntryInstr::FindOsrEntryAndRelink assumes
      // that CheckStackOverflow instruction is at the beginning of a join
      // block.
      EnsureControlFlowJoin(descriptors, pc);
    }

    if ((scratch_var_ == nullptr) && RequiresScratchVar(instr)) {
      scratch_var_ = new (Z)
          LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                        Symbols::ExprTemp(), Object::dynamic_type());
    }

    pc += (KernelBytecode::Next(instr) - instr);
  }

  PcDescriptors::Iterator iter(descriptors, PcDescriptorsLayout::kAnyKind);
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

    // Make sure exception handler starts with SetFrame bytecode instruction.
    ASSERT(KernelBytecode::IsSetFrameOpcode(&(raw_bytecode_[handler_pc])));

    const Array& handler_types =
        Array::ZoneHandle(Z, handlers.GetHandledTypes(try_index));

    CatchBlockEntryInstr* entry = new (Z) CatchBlockEntryInstr(
        handler_info.is_generated != 0, B->AllocateBlockId(),
        handler_info.outer_try_index, graph_entry, handler_types, try_index,
        handler_info.needs_stacktrace != 0, B->GetNextDeoptId(), nullptr,
        nullptr, exception_var_, stacktrace_var_);
    graph_entry->AddCatchEntry(entry);

    code_ = Fragment(entry);
    code_ += B->Goto(join);
  }
}

UncheckedEntryPointStyle BytecodeFlowGraphBuilder::ChooseEntryPointStyle(
    const KBCInstr* jump_if_unchecked) {
  ASSERT(KernelBytecode::IsJumpIfUncheckedOpcode(jump_if_unchecked));

  if (!function().MayHaveUncheckedEntryPoint()) {
    return UncheckedEntryPointStyle::kNone;
  }

  // Separate entry points are used if bytecode has the following pattern:
  //   Entry
  //   CheckStack (optional)
  //   DebugCheck (optional)
  //   JumpIfUnchecked
  //
  const KBCInstr* instr = raw_bytecode_;
  if (!KernelBytecode::IsEntryOpcode(instr)) {
    return UncheckedEntryPointStyle::kSharedWithVariable;
  }
  instr = KernelBytecode::Next(instr);
  if (KernelBytecode::IsCheckStackOpcode(instr)) {
    instr = KernelBytecode::Next(instr);
  }
  if (KernelBytecode::IsDebugCheckOpcode(instr)) {
    instr = KernelBytecode::Next(instr);
  }
  if (instr != jump_if_unchecked) {
    return UncheckedEntryPointStyle::kSharedWithVariable;
  }
  return UncheckedEntryPointStyle::kSeparate;
}

void BytecodeFlowGraphBuilder::CreateParameterVariables() {
  const Bytecode& bytecode = Bytecode::Handle(Z, function().bytecode());
  object_pool_ = bytecode.object_pool();
  bytecode_instr_ = reinterpret_cast<const KBCInstr*>(bytecode.PayloadStart());

  scratch_var_ = parsed_function_->EnsureExpressionTemp();

  if (KernelBytecode::IsEntryOptionalOpcode(bytecode_instr_)) {
    AllocateParametersAndLocalsForEntryOptional();
  } else if (KernelBytecode::IsEntryOpcode(bytecode_instr_)) {
    AllocateLocalVariables(DecodeOperandD());
    AllocateFixedParameters();
  } else if (KernelBytecode::IsEntryFixedOpcode(bytecode_instr_)) {
    AllocateLocalVariables(DecodeOperandE());
    AllocateFixedParameters();
  } else {
    UNREACHABLE();
  }

  if (function().IsGeneric()) {
    // For recognized methods we generate the IL by hand. Yet we need to find
    // out which [LocalVariable] is holding the function type arguments. We
    // scan the bytecode for the CheckFunctionTypeArgs bytecode.
    //
    // Note that we cannot add an extra local variable for the type argument
    // in [AllocateLocalVariables]. We sometimes reuse the same ParsedFunction
    // multiple times. For non-recognized generic bytecode functions
    // ParsedFunction::RawTypeArgumentsVariable() is set during flow graph
    // construction (after local variables are allocated). So the next time,
    // if ParsedFunction is reused, we would allocate an extra local variable.
    // TODO(alexmarkov): revise how function type args variable is allocated
    // and avoid looking at CheckFunctionTypeArgs bytecode.
    const KBCInstr* instr =
        reinterpret_cast<const KBCInstr*>(bytecode.PayloadStart());
    const KBCInstr* end = reinterpret_cast<const KBCInstr*>(
        bytecode.PayloadStart() + bytecode.Size());

    LocalVariable* type_args_var = nullptr;
    while (instr < end) {
      if (KernelBytecode::IsCheckFunctionTypeArgs(instr)) {
        const intptr_t expected_num_type_args = KernelBytecode::DecodeA(instr);
        if (expected_num_type_args > 0) {  // Exclude weird closure case.
          type_args_var = LocalVariableAt(KernelBytecode::DecodeE(instr));
          break;
        }
      }
      instr = KernelBytecode::Next(instr);
    }

    // Every generic function *must* have a kCheckFunctionTypeArgs bytecode.
    ASSERT(type_args_var != nullptr);

    // Normally the flow graph building code of bytecode will, as a side-effect
    // of building the flow graph, register the function type arguments variable
    // in the [ParsedFunction] (see [BuildCheckFunctionTypeArgs]).
    parsed_function_->set_function_type_arguments(type_args_var);
    parsed_function_->SetRawTypeArgumentsVariable(type_args_var);
  }
}

intptr_t BytecodeFlowGraphBuilder::UpdateScope(
    BytecodeLocalVariablesIterator* iter,
    intptr_t pc) {
  // Leave scopes that have ended.
  while ((current_scope_ != nullptr) && (current_scope_->end_pc_ <= pc)) {
    for (LocalVariable* local : current_scope_->hidden_vars_) {
      local_vars_[-local->index().value()] = local;
    }
    current_scope_ = current_scope_->parent_;
  }

  // Enter scopes that have started.
  intptr_t next_pc = bytecode_length_;
  while (!iter->IsDone()) {
    if (iter->IsScope()) {
      if (iter->StartPC() > pc) {
        next_pc = iter->StartPC();
        break;
      }
      if (iter->EndPC() > pc) {
        // Push new scope and declare its variables.
        current_scope_ = new (Z) BytecodeScope(
            Z, iter->EndPC(), iter->ContextLevel(), current_scope_);
        if (!seen_parameters_scope_) {
          // Skip variables from the first scope as it may contain variables
          // which were used in prologue (parameters, function type arguments).
          // The already used variables should not be replaced with new ones.
          seen_parameters_scope_ = true;
          iter->MoveNext();
          continue;
        }
        while (iter->MoveNext() && iter->IsVariableDeclaration()) {
          const intptr_t index = iter->Index();
          if (!iter->IsCaptured() && (index >= 0)) {
            LocalVariable* local = new (Z) LocalVariable(
                TokenPosition::kNoSource, TokenPosition::kNoSource,
                String::ZoneHandle(Z, iter->Name()),
                AbstractType::ZoneHandle(Z, iter->Type()));
            local->set_index(VariableIndex(-index));
            ASSERT(local_vars_[index]->index().value() == -index);
            current_scope_->hidden_vars_.Add(local_vars_[index]);
            local_vars_[index] = local;
          }
        }
        continue;
      }
    }
    iter->MoveNext();
  }
  if (current_scope_ != nullptr && next_pc > current_scope_->end_pc_) {
    next_pc = current_scope_->end_pc_;
  }
  B->set_context_depth(
      current_scope_ != nullptr ? current_scope_->context_level_ : 0);
  return next_pc;
}

FlowGraph* BytecodeFlowGraphBuilder::BuildGraph() {
  const Bytecode& bytecode = Bytecode::Handle(Z, function().bytecode());

  object_pool_ = bytecode.object_pool();
  raw_bytecode_ = reinterpret_cast<const KBCInstr*>(bytecode.PayloadStart());
  bytecode_length_ = bytecode.Size() / sizeof(KBCInstr);

  graph_entry_ = new (Z) GraphEntryInstr(*parsed_function_, B->osr_id_);

  auto normal_entry = B->BuildFunctionEntry(graph_entry_);
  graph_entry_->set_normal_entry(normal_entry);

  const PcDescriptors& descriptors =
      PcDescriptors::Handle(Z, bytecode.pc_descriptors());
  const ExceptionHandlers& handlers =
      ExceptionHandlers::Handle(Z, bytecode.exception_handlers());

  CollectControlFlow(descriptors, handlers, graph_entry_);

  inferred_types_attribute_ ^= BytecodeReader::GetBytecodeAttribute(
      function(), Symbols::vm_inferred_type_metadata());

  kernel::BytecodeSourcePositionsIterator source_pos_iter(Z, bytecode);
  bool update_position = source_pos_iter.MoveNext();

  kernel::BytecodeLocalVariablesIterator local_vars_iter(Z, bytecode);
  intptr_t next_pc_to_update_scope =
      local_vars_iter.MoveNext() ? 0 : bytecode_length_;

  code_ = Fragment(normal_entry);

  for (pc_ = 0; pc_ < bytecode_length_; pc_ = next_pc_) {
    bytecode_instr_ = &(raw_bytecode_[pc_]);
    next_pc_ = pc_ + (KernelBytecode::Next(bytecode_instr_) - bytecode_instr_);

    JoinEntryInstr* join = jump_targets_.Lookup(pc_);
    if (join != nullptr) {
      Value* stack_state = stack_states_.Lookup(pc_);
      if (code_.is_open()) {
        if (stack_state != B->stack_) {
          ASSERT(stack_state == nullptr);
          stack_states_.Insert(pc_, B->stack_);
        }
        code_ += B->Goto(join);
      } else {
        ASSERT(IsStackEmpty());
        B->stack_ = stack_state;
      }
      code_ = Fragment(join);
      join->set_stack_depth(B->GetStackDepth());
      B->SetCurrentTryIndex(join->try_index());
    } else {
      // Unreachable bytecode is not allowed.
      ASSERT(!code_.is_closed());
    }

    while (update_position &&
           static_cast<uword>(pc_) >= source_pos_iter.PcOffset()) {
      position_ = source_pos_iter.TokenPos();
      if (source_pos_iter.IsYieldPoint()) {
        last_yield_point_pc_ = source_pos_iter.PcOffset();
        ++last_yield_point_index_;
      }
      update_position = source_pos_iter.MoveNext();
    }

    if (pc_ >= next_pc_to_update_scope) {
      next_pc_to_update_scope = UpdateScope(&local_vars_iter, pc_);
    }

    BuildInstruction(KernelBytecode::DecodeOpcode(bytecode_instr_));

    if (code_.is_closed()) {
      ASSERT(IsStackEmpty());
    }
  }

  // When compiling for OSR, use a depth first search to find the OSR
  // entry and make graph entry jump to it instead of normal entry.
  // Catch entries are always considered reachable, even if they
  // become unreachable after OSR.
  if (B->IsCompiledForOsr()) {
    graph_entry_->RelinkToOsrEntry(Z, B->last_used_block_id_ + 1);
  }

  FlowGraph* flow_graph = new (Z) FlowGraph(
      *parsed_function_, graph_entry_, B->last_used_block_id_, prologue_info_);

  if (FLAG_print_flow_graph_from_bytecode) {
    FlowGraphPrinter::PrintGraph("Constructed from bytecode", flow_graph);
  }

  return flow_graph;
}

}  // namespace kernel
}  // namespace dart

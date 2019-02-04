// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_FLOW_GRAPH_BUILDER_H_
#define RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_FLOW_GRAPH_BUILDER_H_

#include "vm/compiler/backend/il.h"
#include "vm/compiler/frontend/base_flow_graph_builder.h"
#include "vm/constants_kbc.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {
namespace kernel {

// This class builds flow graph from bytecode. It is used either to compile
// from bytecode, or generate bytecode interpreter (the latter is not
// fully implemented yet).
// TODO(alexmarkov): extend this class and IL to generate an interpreter in
// addition to compiling bytecode.
class BytecodeFlowGraphBuilder {
 public:
  BytecodeFlowGraphBuilder(BaseFlowGraphBuilder* flow_graph_builder,
                           ParsedFunction* parsed_function,
                           ZoneGrowableArray<const ICData*>* ic_data_array)
      : flow_graph_builder_(flow_graph_builder),
        zone_(flow_graph_builder->zone_),
        is_generating_interpreter_(
            false),  // TODO(alexmarkov): pass as argument
        parsed_function_(parsed_function),
        ic_data_array_(ic_data_array),
        object_pool_(ObjectPool::Handle(zone_)),
        raw_bytecode_(nullptr),
        bytecode_length_(0),
        pc_(0),
        bytecode_instr_(KernelBytecode::kTrap),
        position_(TokenPosition::kNoSource),
        local_vars_(zone_, 0),
        parameters_(zone_, 0),
        exception_var_(nullptr),
        stacktrace_var_(nullptr),
        scratch_var_(nullptr),
        prologue_info_(-1, -1),
        throw_no_such_method_(nullptr) {}

  FlowGraph* BuildGraph();

 protected:
  // Returns `true` if building a flow graph for a bytecode interpreter, or
  // `false` if compiling a function from bytecode.
  bool is_generating_interpreter() const { return is_generating_interpreter_; }

 private:
  // Operand of bytecode instruction, either intptr_t value (if compiling
  // bytecode) or Definition (if generating interpreter).
  class Operand {
   public:
    explicit Operand(Definition* definition)
        : definition_(definition), value_(0) {
      ASSERT(definition != nullptr);
    }

    explicit Operand(intptr_t value) : definition_(nullptr), value_(value) {}

    Definition* definition() const {
      ASSERT(definition_ != nullptr);
      return definition_;
    }

    intptr_t value() const {
      ASSERT(definition_ == nullptr);
      return value_;
    }

   private:
    Definition* definition_;
    intptr_t value_;
  };

  // Constant from a constant pool.
  // It is either Object (if compiling bytecode) or Definition
  // (if generating interpreter).
  class Constant {
   public:
    explicit Constant(Definition* definition)
        : definition_(definition), value_(Object::null_object()) {
      ASSERT(definition != nullptr);
    }

    explicit Constant(Zone* zone, const Object& value)
        : definition_(nullptr), value_(value) {}

    Definition* definition() const {
      ASSERT(definition_ != nullptr);
      return definition_;
    }

    const Object& value() const {
      ASSERT(definition_ == nullptr);
      return value_;
    }

   private:
    Definition* definition_;
    const Object& value_;
  };

  Operand DecodeOperandA();
  Operand DecodeOperandB();
  Operand DecodeOperandC();
  Operand DecodeOperandD();
  Operand DecodeOperandX();
  Operand DecodeOperandT();
  KBCInstr InstructionAt(intptr_t pc, KernelBytecode::Opcode expect_opcode);
  Constant ConstantAt(Operand entry_index, intptr_t add_index = 0);
  void PushConstant(Constant constant);
  Constant PopConstant();
  void LoadStackSlots(intptr_t num_slots);
  void AllocateLocalVariables(Operand frame_size,
                              intptr_t num_param_locals = 0);
  LocalVariable* AllocateParameter(intptr_t param_index,
                                   VariableIndex var_index);
  void AllocateFixedParameters();
  LocalVariable* LocalVariableAt(intptr_t local_index);
  void StoreLocal(Operand local_index);
  void LoadLocal(Operand local_index);
  Value* Pop();
  ArgumentArray GetArguments(int count);
  void PropagateStackState(intptr_t target_pc);
  void BuildJumpIfStrictCompare(Token::Kind cmp_kind);
  void BuildIntOp(const String& name, Token::Kind token_kind, int num_args);

  void BuildInstruction(KernelBytecode::Opcode opcode);

#define DECLARE_BUILD_METHOD(name, encoding, op1, op2, op3) void Build##name();
  KERNEL_BYTECODES_LIST(DECLARE_BUILD_METHOD)
#undef DECLARE_BUILD_METHOD

  void ProcessICDataInObjectPool(const ObjectPool& object_pool);
  intptr_t GetTryIndex(const PcDescriptors& descriptors, intptr_t pc);
  JoinEntryInstr* EnsureControlFlowJoin(const PcDescriptors& descriptors,
                                        intptr_t pc);
  bool RequiresScratchVar(KBCInstr instr);
  void CollectControlFlow(const PcDescriptors& descriptors,
                          const ExceptionHandlers& handlers,
                          GraphEntryInstr* graph_entry);

  Thread* thread() const { return flow_graph_builder_->thread_; }
  Isolate* isolate() const { return thread()->isolate(); }

  ParsedFunction* parsed_function() {
    ASSERT(!is_generating_interpreter());
    return parsed_function_;
  }
  const Function& function() { return parsed_function()->function(); }

  BaseFlowGraphBuilder* flow_graph_builder_;
  Zone* zone_;
  bool is_generating_interpreter_;

  // The following members are available only when compiling bytecode.

  ParsedFunction* parsed_function_;
  ZoneGrowableArray<const ICData*>* ic_data_array_;
  ObjectPool& object_pool_;
  KBCInstr* raw_bytecode_;
  intptr_t bytecode_length_;
  intptr_t pc_;
  KBCInstr bytecode_instr_;
  TokenPosition position_;  // TODO(alexmarkov): Set/update.
  Fragment code_;
  ZoneGrowableArray<LocalVariable*> local_vars_;
  ZoneGrowableArray<LocalVariable*> parameters_;
  LocalVariable* exception_var_;
  LocalVariable* stacktrace_var_;
  LocalVariable* scratch_var_;
  IntMap<JoinEntryInstr*> jump_targets_;
  IntMap<Value*> stack_states_;
  PrologueInfo prologue_info_;
  JoinEntryInstr* throw_no_such_method_;
};

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_FLOW_GRAPH_BUILDER_H_

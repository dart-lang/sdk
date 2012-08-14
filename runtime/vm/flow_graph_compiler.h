// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_COMPILER_H_
#define VM_FLOW_GRAPH_COMPILER_H_

#include "vm/allocation.h"
#include "vm/assembler.h"
#include "vm/assembler_macros.h"
#include "vm/code_descriptors.h"
#include "vm/code_generator.h"
#include "vm/intermediate_language.h"

namespace dart {

// Forward declarations.
class FlowGraphCompiler;
class DeoptimizationStub;


// FrameRegisterAllocator is a simple local register allocator that tries to
// keep values in registers by delaying pushing them to the stack after they
// were produced by Bind instruction.  FrameRegisterAllocator relies on the
// fact that IR is stack based and a value produced by a bind instruction
// will be used only once.  For the register allocator every Bind is a push and
// every UseVal of a bind is a pop.
// It can also operate in a non-optimizing mode when every value is pushed
// to the stack immediately after it is produced.
// TODO(vegorov): replace with a linear scan register allocator once SSA is
// available.
class FrameRegisterAllocator : public ValueObject {
 public:
  FrameRegisterAllocator(FlowGraphCompiler* compiler,
                         bool keep_values_in_registers,
                         bool is_ssa)
      : compiler_(compiler),
        stack_(kNumberOfCpuRegisters),
        registers_(),
        keep_values_in_registers_(keep_values_in_registers && !is_ssa),
        is_ssa_(is_ssa) {
    for (int i = 0; i < kNumberOfCpuRegisters; i++) {
      registers_[i] = NULL;
    }
  }

  // Notify register allocator that given instruction produced a value
  // in the given register.
  void Push(Register reg, BindInstr* val);

  // Perform a greedy local register allocation.  Consider all register free.
  void AllocateRegisters(Instruction* instr);

  // Spill all live registers to the stack in order from oldest to newest.
  void Spill();

  // Returns true if all live values are stored on the stack.
  // Code generator expects no live values in registers at call sites and
  // branches.
  bool IsSpilled() const { return stack_.is_empty(); }

  // Popuplate deoptimization stub with live registers to ensure
  // that they will be pushed to the stack when deoptimization happens.
  void SpillInDeoptStub(DeoptimizationStub* stub);

 private:
  // Pop a value from the place where it is currently stored (either register
  // or top of the stack) into a given register.  If value is in the register
  // verify that passed use corresponds to the instruction that produced the
  // value.
  void Pop(Register reg, Value* use);

  // Allocate a register that is not explicitly blocked.
  // Spills a value if all non-blocked registers contain values.
  Register AllocateFreeRegister(bool* blocked_registers);

  // Ensure that given register is free for allocation.
  void SpillRegister(Register reg);

  // Spill the oldest live value from register to the stack.
  Register SpillFirst();

  FlowGraphCompiler* compiler() { return compiler_; }

  FlowGraphCompiler* compiler_;

  // List of registers with live values in order from oldest to newest.
  GrowableArray<Register> stack_;

  // Mapping between live registers and instructions that produced values
  // in them.  Contains NULL for registers do not have corresponding live value.
  BindInstr* registers_[kNumberOfCpuRegisters];

  const bool keep_values_in_registers_;
  const bool is_ssa_;

  DISALLOW_COPY_AND_ASSIGN(FrameRegisterAllocator);
};


class ParallelMoveResolver : public ValueObject {
 public:
  explicit ParallelMoveResolver(FlowGraphCompiler* compiler);

  // Resolve a set of parallel moves, emitting assembler instructions.
  void EmitNativeCode(ParallelMoveInstr* parallel_move);

 private:
  // Build the initial list of moves.
  void BuildInitialMoveList(ParallelMoveInstr* parallel_move);

  // Perform the move at the moves_ index in question (possibly requiring
  // other moves to satisfy dependencies).
  void PerformMove(int index);

  // Emit a move and remove it from the move graph.
  void EmitMove(int index);

  // Execute a move by emitting a swap of two operands.  The move from
  // source to destination is removed from the move graph.
  void EmitSwap(int index);

  // Verify the move list before performing moves.
  void Verify();

  // Helpers for non-trivial source-destination combinations that cannot
  // be handled by a single instruction.
  void MoveMemoryToMemory(const Address& dst, const Address& src);
  void StoreObject(const Address& dst, const Object& obj);
  void Exchange(Register reg, const Address& mem);
  void Exchange(const Address& mem1, const Address& mem2);

  FlowGraphCompiler* compiler_;

  // List of moves not yet resolved.
  GrowableArray<MoveOperands*> moves_;
};


class DeoptimizationStub : public ZoneAllocated {
 public:
  DeoptimizationStub(intptr_t deopt_id,
                     intptr_t try_index,
                     DeoptReasonId reason)
      : deopt_id_(deopt_id),
        try_index_(try_index),
        reason_(reason),
        registers_(2),
        deoptimization_env_(NULL),
        entry_label_() {}

  void Push(Register reg) { registers_.Add(reg); }
  Label* entry_label() { return &entry_label_; }

  // Implementation is in architecture specific file.
  void GenerateCode(FlowGraphCompiler* compiler, intptr_t stub_ix);

  void set_deoptimization_env(Environment* env) {
    deoptimization_env_ = env;
  }

  RawDeoptInfo* CreateDeoptInfo(FlowGraphCompiler* compiler);

 private:
  const intptr_t deopt_id_;
  const intptr_t try_index_;
  const DeoptReasonId reason_;
  GrowableArray<Register> registers_;
  const Environment* deoptimization_env_;
  Label entry_label_;

  DISALLOW_COPY_AND_ASSIGN(DeoptimizationStub);
};


class SlowPathCode : public ZoneAllocated {
 public:
  SlowPathCode() : entry_label_(), exit_label_() { }

  Label* entry_label() { return &entry_label_; }
  Label* exit_label() { return &exit_label_; }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) = 0;

 private:
  Label entry_label_;
  Label exit_label_;

  DISALLOW_COPY_AND_ASSIGN(SlowPathCode);
};


}  // namespace dart

#if defined(TARGET_ARCH_IA32)
#include "vm/flow_graph_compiler_ia32.h"
#elif defined(TARGET_ARCH_X64)
#include "vm/flow_graph_compiler_x64.h"
#elif defined(TARGET_ARCH_ARM)
#include "vm/flow_graph_compiler_arm.h"
#else
#error Unknown architecture.
#endif

#endif  // VM_FLOW_GRAPH_COMPILER_H_

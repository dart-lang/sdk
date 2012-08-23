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
        deoptimization_env_(NULL),
        entry_label_() {}

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

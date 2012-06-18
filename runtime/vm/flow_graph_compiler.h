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
                         bool keep_values_in_registers)
      : compiler_(compiler),
        stack_(kNumberOfCpuRegisters),
        registers_(),
        keep_values_in_registers_(keep_values_in_registers) {
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
  bool IsSpilled() const { return stack_.length() == 0; }

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

  DISALLOW_COPY_AND_ASSIGN(FrameRegisterAllocator);
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

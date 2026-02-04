// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/instructions.dart';

/// Visitor over [Instruction].
abstract interface class InstructionVisitor<R> {
  // Basic blocks.
  R visitEntryBlock(EntryBlock instr);
  R visitJoinBlock(JoinBlock instr);
  R visitTargetBlock(TargetBlock instr);
  R visitCatchBlock(CatchBlock instr);
  // Regular instructions.
  R visitGoto(Goto instr);
  R visitBranch(Branch instr);
  R visitTryEntry(TryEntry instr);
  R visitPhi(Phi instr);
  R visitReturn(Return instr);
  R visitComparison(Comparison instr);
  R visitConstant(Constant instr);
  R visitDirectCall(DirectCall instr);
  R visitInterfaceCall(InterfaceCall instr);
  R visitDynamicCall(DynamicCall instr);
  R visitParameter(Parameter instr);
  R visitLoadLocal(LoadLocal instr);
  R visitStoreLocal(StoreLocal instr);
  R visitLoadInstanceField(LoadInstanceField instr);
  R visitStoreInstanceField(StoreInstanceField instr);
  R visitLoadStaticField(LoadStaticField instr);
  R visitStoreStaticField(StoreStaticField instr);
  R visitThrow(Throw instr);
  R visitTypeParameters(TypeParameters instr);
  R visitTypeCast(TypeCast instr);
  R visitTypeTest(TypeTest instr);
  R visitTypeArguments(TypeArguments instr);
  R visitAllocateObject(AllocateObject instr);
  R visitBinaryIntOp(BinaryIntOp instr);
  R visitUnaryIntOp(UnaryIntOp instr);
  R visitBinaryDoubleOp(BinaryDoubleOp instr);
  R visitUnaryDoubleOp(UnaryDoubleOp instr);
  // Back-end specific instructions.
  R visitCompareAndBranch(CompareAndBranch instr);
  R visitParallelMove(ParallelMove instr);
}

/// Visitor over [Instruction] which has an overridable default behavior for
/// different categories of instructions.
abstract mixin class DefaultInstructionVisitor<R>
    implements InstructionVisitor<R> {
  /// Default behavior for all instructions.
  R defaultInstruction(Instruction instr);

  /// Default behavior for basic blocks.
  R defaultBlock(Block instr) => defaultInstruction(instr);

  /// Default behavior for back-end specific instructions.
  R defaultBackendInstruction(BackendInstruction instr) =>
      defaultInstruction(instr);

  // Basic blocks.
  R visitEntryBlock(EntryBlock instr) => defaultBlock(instr);
  R visitJoinBlock(JoinBlock instr) => defaultBlock(instr);
  R visitTargetBlock(TargetBlock instr) => defaultBlock(instr);
  R visitCatchBlock(CatchBlock instr) => defaultBlock(instr);
  // Regular instructions.
  R visitGoto(Goto instr) => defaultInstruction(instr);
  R visitBranch(Branch instr) => defaultInstruction(instr);
  R visitTryEntry(TryEntry instr) => defaultInstruction(instr);
  R visitPhi(Phi instr) => defaultInstruction(instr);
  R visitReturn(Return instr) => defaultInstruction(instr);
  R visitComparison(Comparison instr) => defaultInstruction(instr);
  R visitConstant(Constant instr) => defaultInstruction(instr);
  R visitDirectCall(DirectCall instr) => defaultInstruction(instr);
  R visitInterfaceCall(InterfaceCall instr) => defaultInstruction(instr);
  R visitDynamicCall(DynamicCall instr) => defaultInstruction(instr);
  R visitParameter(Parameter instr) => defaultInstruction(instr);
  R visitLoadLocal(LoadLocal instr) => defaultInstruction(instr);
  R visitStoreLocal(StoreLocal instr) => defaultInstruction(instr);
  R visitLoadInstanceField(LoadInstanceField instr) =>
      defaultInstruction(instr);
  R visitStoreInstanceField(StoreInstanceField instr) =>
      defaultInstruction(instr);
  R visitLoadStaticField(LoadStaticField instr) => defaultInstruction(instr);
  R visitStoreStaticField(StoreStaticField instr) => defaultInstruction(instr);
  R visitThrow(Throw instr) => defaultInstruction(instr);
  R visitTypeParameters(TypeParameters instr) => defaultInstruction(instr);
  R visitTypeCast(TypeCast instr) => defaultInstruction(instr);
  R visitTypeTest(TypeTest instr) => defaultInstruction(instr);
  R visitTypeArguments(TypeArguments instr) => defaultInstruction(instr);
  R visitAllocateObject(AllocateObject instr) => defaultInstruction(instr);
  R visitBinaryIntOp(BinaryIntOp instr) => defaultInstruction(instr);
  R visitUnaryIntOp(UnaryIntOp instr) => defaultInstruction(instr);
  R visitBinaryDoubleOp(BinaryDoubleOp instr) => defaultInstruction(instr);
  R visitUnaryDoubleOp(UnaryDoubleOp instr) => defaultInstruction(instr);
  // Back-end specific instructions.
  R visitCompareAndBranch(CompareAndBranch instr) =>
      defaultBackendInstruction(instr);
  R visitParallelMove(ParallelMove instr) => defaultBackendInstruction(instr);
}

/// Visitor over [Instruction] which does not yield a value.
base class VoidInstructionVisitor extends DefaultInstructionVisitor<void> {
  void defaultInstruction(Instruction instr) {}
}

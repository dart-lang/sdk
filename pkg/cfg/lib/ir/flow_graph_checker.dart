// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/ir_to_text.dart';
import 'package:cfg/ir/types.dart';
import 'package:cfg/ir/use_lists.dart';
import 'package:cfg/ir/visitor.dart';
import 'package:cfg/passes/pass.dart';

/// Check integrity of the flow graph.
final class FlowGraphChecker extends Pass implements InstructionVisitor<void> {
  bool constantsAllowed = false;
  bool parametersAllowed = false;
  bool phisAllowed = false;

  FlowGraphChecker([super.name = 'FlowGraphChecker']);

  @override
  void run() {
    assert(graph.postorder.length == graph.preorder.length);
    assert(graph.reversePostorder.length == graph.preorder.length);

    for (final block in graph.preorder) {
      currentBlock = block;
      block.accept(this);
    }
  }

  void visitBlock(Block block) {
    assert(block.previous == null);
    assert(block.block == block);
    assert(block.graph == graph);
    assert(graph.preorder[block.preorderNumber] == block);
    assert(graph.postorder[block.postorderNumber] == block);

    // Constants are only allowed at the beginning of EntryBlock.
    constantsAllowed = block is EntryBlock;
    // Parameters are allowed in the beginning of CatchBlock, or
    // after Constants in the EntryBlock.
    parametersAllowed = block is CatchBlock;
    // Phis are only allowed at the beginning of JoinBlock.
    phisAllowed = block is JoinBlock;

    Instruction previous = block;
    for (final instr in block) {
      currentInstruction = instr;
      assert(graph.instructions[instr.id] == instr);
      assert(instr.previous == previous);
      assert(previous.next == instr);
      assert(instr.block == block);
      assert(instr.graph == graph);
      assert(instr.isInGraph);
      if (constantsAllowed && instr is! Constant) {
        constantsAllowed = false;
        parametersAllowed = true;
      }
      if (parametersAllowed && instr is! Parameter && instr is! ParallelMove) {
        parametersAllowed = false;
      }
      if (phisAllowed && instr is! Phi) {
        phisAllowed = false;
      }
      instr.accept(this);
      verifyInputs(instr);
      if (instr is Definition) {
        verifyUses(instr);
      }
      previous = instr;
    }
    assert(previous is ControlFlowInstruction);
    assert(previous.next == null);
    assert(previous == block.lastInstruction);
    currentInstruction = null;
  }

  void verifyInputs(Instruction instr) {
    for (int i = 0, n = instr.inputCount; i < n; ++i) {
      final input = instr.inputAt(i);
      assert(input.getInstruction(graph) == instr);
      final def = input.getDefinition(graph);
      // Check that input can be found in the use list of 'def'.
      var seen = false;
      for (final use in def.inputUses) {
        if (use == input) {
          assert(!seen);
          seen = true;
        }
      }
      assert(seen);
      // Check that every use is dominated by def.
      if (instr is Phi) {
        assert(instr.block!.predecessors[i].lastInstruction.isDominatedBy(def));
      } else {
        assert(instr.isDominatedBy(def));
      }
    }
  }

  void verifyUses(Definition def) {
    Use previous = Use.Null;
    for (final use in def.inputUses) {
      assert(use != Use.Null);
      assert(use.getDefinition(graph) == def);
      assert(use.getPrevious(graph) == previous);
      if (previous != Use.Null) {
        assert(previous.getNext(graph) == use);
      }
      previous = use;
    }
    if (previous != Use.Null) {
      assert(previous.getNext(graph) == Use.Null);
    }
  }

  void verifyTypeArguments(Definition typeArguments, Definition user) {
    switch (typeArguments) {
      case TypeArguments():
      case Constant(value: ConstantValue(constant: TypeArgumentsConstant())):
        assert(typeArguments.type is TypeArgumentsType);
        return;
      default:
        throw 'Unexpected type arguments ${IrToText.instruction(typeArguments)} in ${IrToText.instruction(user)}';
    }
  }

  void verifyCall(CallInstruction instr) {
    if (instr.hasTypeArguments) {
      verifyTypeArguments(instr.typeArguments!, instr);
    }
  }

  @override
  void visitEntryBlock(EntryBlock block) {
    assert(block == graph.entryBlock);
    assert(block.predecessors.isEmpty);
    assert(graph.preorder.first == block);
    assert(graph.postorder.last == block);
    assert(graph.reversePostorder.first == block);
    visitBlock(block);
  }

  @override
  void visitJoinBlock(JoinBlock block) {
    assert(block.predecessors.isNotEmpty);
    for (final pred in block.predecessors) {
      assert(pred.lastInstruction is Goto);
      assert(pred.successors.single == block);
    }
    visitBlock(block);
  }

  @override
  void visitTargetBlock(TargetBlock block) {
    final predecessor = block.predecessors.single;
    assert(block.dominator == predecessor);
    final predLast = predecessor.lastInstruction;
    switch (predLast) {
      case Goto():
        assert(predLast.target == block);
      case Branch():
        assert(
          predLast.trueSuccessor == block || predLast.falseSuccessor == block,
        );
      case CompareAndBranch():
        assert(
          predLast.trueSuccessor == block || predLast.falseSuccessor == block,
        );
      case TryEntry():
        assert(predLast.tryBody == block);
      default:
        assert(false);
    }
    visitBlock(block);
  }

  @override
  void visitCatchBlock(CatchBlock block) {
    final predecessor = block.predecessors.single;
    assert(block.dominator == predecessor);
    final predLast = predecessor.lastInstruction as TryEntry;
    assert(predLast.catchBlock == block);
    visitBlock(block);
  }

  @override
  void visitGoto(Goto instr) {
    assert(instr.next == null);
    final target = instr.target;
    assert(instr.block!.successors.single == target);
    assert(target is TargetBlock || target is JoinBlock);
  }

  @override
  void visitBranch(Branch instr) {
    assert(instr.condition.type is BoolType);
    assert(instr.next == null);
    final trueSuccessor = instr.trueSuccessor;
    final falseSuccessor = instr.falseSuccessor;
    assert(instr.block!.successors.length == 2);
    assert(instr.block!.successors[0] == trueSuccessor);
    assert(instr.block!.successors[1] == falseSuccessor);
  }

  @override
  void visitCompareAndBranch(CompareAndBranch instr) {
    if (instr.op.isIntComparison) {
      assert(instr.left.type is IntType);
      assert(instr.right.type is IntType);
    } else if (instr.op.isDoubleComparison) {
      assert(instr.left.type is DoubleType);
      assert(instr.right.type is DoubleType);
    }
    assert(instr.next == null);
    final trueSuccessor = instr.trueSuccessor;
    final falseSuccessor = instr.falseSuccessor;
    assert(instr.block!.successors.length == 2);
    assert(instr.block!.successors[0] == trueSuccessor);
    assert(instr.block!.successors[1] == falseSuccessor);
  }

  @override
  void visitTryEntry(TryEntry instr) {
    assert(instr.next == null);
    final tryBody = instr.tryBody;
    final catchBlock = instr.catchBlock;
    assert(instr.block!.successors.length == 2);
    assert(instr.block!.successors[0] == tryBody);
    assert(instr.block!.successors[1] == catchBlock);
  }

  @override
  void visitPhi(Phi instr) {
    assert(phisAllowed);
    assert(instr.block is JoinBlock);
    assert(instr.inputCount == instr.block!.predecessors.length);
    assert(instr.variable == graph.localVariables[instr.variable.index]);
  }

  @override
  void visitReturn(Return instr) {
    assert(instr.next == null);
    assert(instr.block!.successors.isEmpty);
  }

  @override
  void visitConstant(Constant instr) {
    assert(constantsAllowed);
    assert(instr.block is EntryBlock);
    assert(graph.getConstant(instr.value) == instr);
  }

  @override
  void visitDirectCall(DirectCall instr) {
    verifyCall(instr);
  }

  @override
  void visitInterfaceCall(InterfaceCall instr) {
    verifyCall(instr);
  }

  @override
  void visitClosureCall(ClosureCall instr) {
    verifyCall(instr);
  }

  @override
  void visitDynamicCall(DynamicCall instr) {
    verifyCall(instr);
  }

  @override
  void visitParameter(Parameter instr) {
    assert(parametersAllowed);
    final block = instr.block!;
    assert(block is EntryBlock || block is CatchBlock);
    assert(instr.variable == graph.localVariables[instr.variable.index]);
  }

  @override
  void visitLoadLocal(LoadLocal instr) {
    assert(!graph.inSSAForm);
    assert(instr.variable == graph.localVariables[instr.variable.index]);
  }

  @override
  void visitStoreLocal(StoreLocal instr) {
    assert(!graph.inSSAForm);
    assert(instr.variable == graph.localVariables[instr.variable.index]);
  }

  @override
  void visitLoadInstanceField(LoadInstanceField instr) {}

  @override
  void visitStoreInstanceField(StoreInstanceField instr) {}

  @override
  void visitLoadStaticField(LoadStaticField instr) {}

  @override
  void visitStoreStaticField(StoreStaticField instr) {}

  @override
  void visitThrow(Throw instr) {
    assert(instr.next == null);
    assert(instr.block!.successors.isEmpty);
    assert(instr.canThrow);
  }

  @override
  void visitNullCheck(NullCheck instr) {}

  @override
  void visitTypeParameters(TypeParameters instr) {
    assert(instr.block is EntryBlock);
    // TypeParameters can only be used in TypeCast, TypeTest,
    // TypeArguments and TypeLiteral.
    for (final use in instr.inputUses) {
      final user = use.getInstruction(graph);
      switch (user) {
        case TypeCast() || TypeTest() || TypeArguments() || TypeLiteral():
          break;
        default:
          throw 'Unexpected user ${IrToText.instruction(user)} of TypeParameters';
      }
    }
  }

  @override
  void visitTypeCast(TypeCast instr) {
    assert(instr.testedType is! TopType);
    assert(instr.testedType is! ExtendedType);
  }

  @override
  void visitTypeTest(TypeTest instr) {
    assert(instr.testedType is! TopType);
    assert(instr.testedType is! ExtendedType);
  }

  @override
  void visitTypeArguments(TypeArguments instr) {
    // TypeArguments can only be used as the first input in a call or AllocateObject.
    for (final use in instr.inputUses) {
      final user = use.getInstruction(graph);
      switch (user) {
        case CallInstruction():
          assert(user.hasTypeArguments);
          assert(user.typeArguments == instr);
        case AllocateObject():
          assert(user.typeArguments == instr);
        case AllocateListLiteral():
          assert(user.typeArguments == instr);
        case AllocateMapLiteral():
          assert(user.typeArguments == instr);
        default:
          throw 'Unexpected user ${IrToText.instruction(user)} of TypeArguments';
      }
    }
  }

  @override
  void visitTypeLiteral(TypeLiteral instr) {}

  @override
  void visitAllocateObject(AllocateObject instr) {
    if (instr.hasTypeArguments) {
      verifyTypeArguments(instr.typeArguments!, instr);
    }
  }

  @override
  void visitAllocateClosure(AllocateClosure instr) {}

  @override
  void visitAllocateListLiteral(AllocateListLiteral instr) {
    verifyTypeArguments(instr.typeArguments, instr);
  }

  @override
  void visitAllocateMapLiteral(AllocateMapLiteral instr) {
    verifyTypeArguments(instr.typeArguments, instr);
  }

  @override
  void visitStringInterpolation(StringInterpolation instr) {}

  @override
  void visitComparison(Comparison instr) {
    if (instr.op.isIntComparison) {
      assert(instr.left.type is IntType);
      assert(instr.right.type is IntType);
    } else if (instr.op.isDoubleComparison) {
      assert(instr.left.type is DoubleType);
      assert(instr.right.type is DoubleType);
    }
  }

  @override
  void visitBinaryIntOp(BinaryIntOp instr) {
    assert(instr.left.type is IntType);
    assert(instr.right.type is IntType);
  }

  @override
  void visitUnaryIntOp(UnaryIntOp instr) {
    assert(instr.operand.type is IntType);
  }

  @override
  void visitBinaryDoubleOp(BinaryDoubleOp instr) {
    assert(instr.left.type is DoubleType);
    assert(instr.right.type is DoubleType);
  }

  @override
  void visitUnaryDoubleOp(UnaryDoubleOp instr) {
    assert(instr.operand.type is DoubleType);
  }

  @override
  void visitUnaryBoolOp(UnaryBoolOp instr) {
    assert(instr.operand.type is BoolType);
  }

  @override
  void visitAllocateList(AllocateList instr) {}

  @override
  void visitSetListElement(SetListElement instr) {}

  @override
  void visitParallelMove(ParallelMove instr) {}
}

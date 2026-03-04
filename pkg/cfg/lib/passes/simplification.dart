// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/types.dart';
import 'package:cfg/ir/visitor.dart';
import 'package:cfg/passes/pass.dart';
import 'package:cfg/utils/misc.dart';

/// IR simplification / canonicalization pass. Includes constant folding.
final class Simplification extends Pass
    implements InstructionVisitor<Instruction> {
  final ConstantFolding constantFolding = ConstantFolding();

  Simplification() : super('Simplification');

  @override
  void run() {
    for (final block in graph.reversePostorder) {
      currentBlock = block;
      for (final instr in block) {
        simplify(instr);
      }
    }
    graph.invalidateInstructionNumbering();
  }

  /// Simplify given instruction.
  ///
  /// Can modify instruction in place (e.g. swap inputs),
  /// replace instruction with existing instruction
  /// (e.g. one of its inputs or an existing Constant), or
  /// replace instruction with a new, simpler instruction.
  Instruction simplify(Instruction instr) {
    currentInstruction = instr;
    final replacement = instr.accept(this);
    if (replacement == instr) {
      return instr;
    }
    if (!replacement.isInGraph) {
      replacement.insertBefore(instr);
    }
    if (instr is Definition) {
      instr.replaceUsesWith(replacement as Definition);
    }
    instr.removeFromGraph();
    return replacement;
  }

  @override
  Instruction visitEntryBlock(EntryBlock instr) => instr;

  @override
  Instruction visitJoinBlock(JoinBlock instr) => instr;

  @override
  Instruction visitTargetBlock(TargetBlock instr) => instr;

  @override
  Instruction visitCatchBlock(CatchBlock instr) => instr;

  @override
  Instruction visitGoto(Goto instr) => instr;

  @override
  Instruction visitBranch(Branch instr) => instr;

  @override
  Instruction visitCompareAndBranch(CompareAndBranch instr) => instr;

  @override
  Instruction visitTryEntry(TryEntry instr) => instr;

  @override
  Instruction visitPhi(Phi instr) {
    // Replace 'y = phi(x|y, ...., x|y)' with 'x'.
    Definition? replacement;
    for (int i = 0, n = instr.inputCount; i < n; ++i) {
      final input = instr.inputDefAt(i);
      // Ignore all self-references.
      if (input == instr) {
        continue;
      }
      if (replacement == null) {
        replacement = input;
      } else if (input != replacement) {
        // Phi has at least two distinct inputs.
        return instr;
      }
    }
    // Phi takes only one distinct input.
    return replacement!;
  }

  @override
  Instruction visitReturn(Return instr) => instr;

  @override
  Instruction visitComparison(Comparison instr) {
    Definition left = instr.left;
    Definition right = instr.right;
    // Constant folding.
    if (left is Constant && right is Constant) {
      ConstantValue result = constantFolding.comparison(
        instr.op,
        left.value,
        right.value,
      );
      return graph.getConstant(result);
    }
    // Move constant operand to the right.
    if (left is Constant) {
      instr.op = instr.op.flipOperands();
      instr.replaceInputAt(0, right);
      instr.replaceInputAt(1, left);
      left = instr.left;
      right = instr.right;
    }
    // Comparison with itself.
    if (left == right) {
      switch (instr.op) {
        case ComparisonOpcode.identical:
        case ComparisonOpcode.equal:
        case ComparisonOpcode.intEqual:
        case ComparisonOpcode.intLessOrEqual:
        case ComparisonOpcode.intGreaterOrEqual:
          return graph.getConstant(ConstantValue.fromBool(true));
        case ComparisonOpcode.notIdentical:
        case ComparisonOpcode.notEqual:
        case ComparisonOpcode.intNotEqual:
        case ComparisonOpcode.intLess:
        case ComparisonOpcode.intGreater:
          return graph.getConstant(ConstantValue.fromBool(false));
        default:
      }
    }
    return instr;
  }

  @override
  Instruction visitConstant(Constant instr) => instr;

  @override
  Instruction visitDirectCall(DirectCall instr) => instr;

  @override
  Instruction visitInterfaceCall(InterfaceCall instr) => instr;

  @override
  Instruction visitClosureCall(ClosureCall instr) {
    final closure = instr.closure;
    if (closure is AllocateClosure) {
      final replacement = DirectCall(
        graph,
        instr.sourcePosition,
        closure.function,
        instr.type,
        inputCount: instr.inputCount,
        argumentsShape: instr.argumentsShape,
      );
      for (int i = 0, n = instr.inputCount; i < n; ++i) {
        replacement.setInputAt(i, instr.inputDefAt(i));
      }
      return replacement;
    }
    return instr;
  }

  @override
  Instruction visitDynamicCall(DynamicCall instr) => instr;

  @override
  Instruction visitParameter(Parameter instr) => instr;

  @override
  Instruction visitLoadLocal(LoadLocal instr) => instr;

  @override
  Instruction visitStoreLocal(StoreLocal instr) => instr;

  @override
  Instruction visitLoadInstanceField(LoadInstanceField instr) => instr;

  @override
  Instruction visitStoreInstanceField(StoreInstanceField instr) => instr;

  @override
  Instruction visitLoadStaticField(LoadStaticField instr) => instr;

  @override
  Instruction visitStoreStaticField(StoreStaticField instr) => instr;

  @override
  Instruction visitThrow(Throw instr) => instr;

  @override
  Instruction visitNullCheck(NullCheck instr) {
    final operand = instr.operand;
    if (!operand.type.isNullable) {
      return operand;
    }
    return instr;
  }

  @override
  Instruction visitTypeParameters(TypeParameters instr) => instr;

  @override
  Instruction visitTypeCast(TypeCast instr) {
    final operand = instr.operand;
    if (operand.type.isSubtypeOf(instr.testedType)) {
      return operand;
    }
    return instr;
  }

  @override
  Instruction visitTypeTest(TypeTest instr) {
    final operand = instr.operand;
    if (operand.type.isSubtypeOf(instr.testedType)) {
      return graph.getConstant(ConstantValue.fromBool(true));
    }
    return instr;
  }

  @override
  Instruction visitTypeArguments(TypeArguments instr) => instr;

  @override
  Instruction visitTypeLiteral(TypeLiteral instr) => instr;

  @override
  Instruction visitAllocateObject(AllocateObject instr) => instr;

  @override
  Instruction visitAllocateClosure(AllocateClosure instr) => instr;

  @override
  Instruction visitAllocateListLiteral(AllocateListLiteral instr) => instr;

  @override
  Instruction visitAllocateMapLiteral(AllocateMapLiteral instr) => instr;

  @override
  Instruction visitStringInterpolation(StringInterpolation instr) {
    final buf = _StringInterpolationBuffer(constantFolding);
    buf.addStringInterpolation(instr);
    if (buf.inputs.length == 1) {
      final input = buf.inputs.single;
      if (input is String) {
        return graph.getConstant(ConstantValue.fromString(input));
      } else if ((input as Definition).type is StringType) {
        return input;
      }
    }
    if (!buf.optimized) {
      return instr;
    }
    final replacement = StringInterpolation(
      graph,
      instr.sourcePosition,
      inputCount: buf.inputs.length,
    );
    for (int i = 0, n = buf.inputs.length; i < n; ++i) {
      final input = buf.inputs[i];
      final inputDef = input is String
          ? graph.getConstant(ConstantValue.fromString(input))
          : input as Definition;
      replacement.setInputAt(i, inputDef);
    }
    return replacement;
  }

  @override
  Instruction visitAllocateList(AllocateList instr) => instr;

  @override
  Instruction visitSetListElement(SetListElement instr) => instr;

  @override
  Instruction visitParallelMove(ParallelMove instr) => instr;

  @override
  Instruction visitBinaryIntOp(BinaryIntOp instr) {
    Definition left = instr.left;
    Definition right = instr.right;
    // Constant folding.
    if (left is Constant && right is Constant) {
      ConstantValue? result = constantFolding.binaryIntOp(
        instr.op,
        left.value,
        right.value,
      );
      if (result != null) {
        return graph.getConstant(result);
      }
      return instr;
    }
    // Patterns with constant lhs.
    if (left is Constant) {
      if (instr.op.isCommutative) {
        // Move constant operands of commutative operations to the right.
        instr.replaceInputAt(0, right);
        instr.replaceInputAt(1, left);
        left = instr.left;
        right = instr.right;
      } else {
        final int leftVal = left.value.intValue;
        switch (instr.op) {
          case BinaryIntOpcode.sub when leftVal == 0:
            // 0 - x == -x
            return UnaryIntOp(
              graph,
              instr.sourcePosition,
              UnaryIntOpcode.neg,
              right,
            );
          default:
        }
      }
    }
    // Patterns with constant rhs.
    if (right is Constant) {
      final int rightVal = right.value.intValue;
      switch (instr.op) {
        case BinaryIntOpcode.add when rightVal == 0:
          // x + 0 == x
          return left;
        case BinaryIntOpcode.sub:
          if (rightVal == 0) {
            // x - 0 == x
            return left;
          } else {
            // x - c == x + (-c)
            final minusRight = graph.getConstant(
              ConstantValue.fromInt(-rightVal),
            );
            return BinaryIntOp(
              graph,
              instr.sourcePosition,
              BinaryIntOpcode.add,
              left,
              minusRight,
            );
          }
        case BinaryIntOpcode.mul when rightVal == 0:
          // x * 0 == 0
          return graph.getConstant(ConstantValue.fromInt(0));
        case BinaryIntOpcode.mul when rightVal == 1:
          // x * 1 == x
          return left;
        case BinaryIntOpcode.mul when rightVal == -1:
          // x * (-1) == -x
          return UnaryIntOp(
            graph,
            instr.sourcePosition,
            UnaryIntOpcode.neg,
            left,
          );
        case BinaryIntOpcode.mul when isPowerOf2(rightVal) && rightVal > 0:
          // x * power(2, y) == x << y
          final log2right = graph.getConstant(
            ConstantValue.fromInt(log2OfPowerOf2(rightVal)),
          );
          return BinaryIntOp(
            graph,
            instr.sourcePosition,
            BinaryIntOpcode.shiftLeft,
            left,
            log2right,
          );
        case BinaryIntOpcode.truncatingDiv when rightVal == 1:
          // x ~/ 1 == x
          return left;
        case BinaryIntOpcode.truncatingDiv when rightVal == -1:
          // x ~/ (-1) == -x
          return UnaryIntOp(
            graph,
            instr.sourcePosition,
            UnaryIntOpcode.neg,
            left,
          );
        case BinaryIntOpcode.truncatingDiv
            when isPowerOf2(rightVal) && rightVal > 0:
          // Adjust negative lhs to round result towards zero:
          //
          // x ~/ power(2, y) == (x + (x >> 63) & (power(2, y) - 1)) >> y
          //
          // For non-negative lhs:
          //
          // x ~/ power(2, y) == x >> y
          if (left.canBeNegative) {
            final signMask = BinaryIntOp(
              graph,
              instr.sourcePosition,
              BinaryIntOpcode.shiftRight,
              left,
              graph.getConstant(ConstantValue.fromInt(63)),
            );
            signMask.insertBefore(instr);
            final adjustment = BinaryIntOp(
              graph,
              instr.sourcePosition,
              BinaryIntOpcode.bitAnd,
              signMask,
              graph.getConstant(ConstantValue.fromInt(rightVal - 1)),
            );
            adjustment.insertBefore(instr);
            left = BinaryIntOp(
              graph,
              instr.sourcePosition,
              BinaryIntOpcode.add,
              left,
              adjustment,
            );
            left.insertBefore(instr);
          }
          final log2right = graph.getConstant(
            ConstantValue.fromInt(log2OfPowerOf2(rightVal)),
          );
          return BinaryIntOp(
            graph,
            instr.sourcePosition,
            BinaryIntOpcode.shiftRight,
            left,
            log2right,
          );
        case BinaryIntOpcode.mod when (rightVal == 1 || rightVal == -1):
          // x % 1 == 0, x % (-1) == 0
          return graph.getConstant(ConstantValue.fromInt(0));
        case BinaryIntOpcode.rem when (rightVal == 1 || rightVal == -1):
          // remainder(x, 1) == 0, remainder(x, -1) == 0
          return graph.getConstant(ConstantValue.fromInt(0));
        case BinaryIntOpcode.bitAnd when rightVal == 0:
          // x & 0 == 0
          return graph.getConstant(ConstantValue.fromInt(0));
        case BinaryIntOpcode.bitAnd when rightVal == -1:
          // x & (-1) == x
          return left;
        case BinaryIntOpcode.bitOr when rightVal == 0:
          // x | 0 == x
          return left;
        case BinaryIntOpcode.bitOr when rightVal == -1:
          // x | (-1) == (-1)
          return graph.getConstant(ConstantValue.fromInt(-1));
        case BinaryIntOpcode.bitXor when rightVal == 0:
          // x ^ 0 == x
          return left;
        case BinaryIntOpcode.bitXor when rightVal == -1:
          // x ^ (-1) == ~x
          return UnaryIntOp(
            graph,
            instr.sourcePosition,
            UnaryIntOpcode.bitNot,
            left,
          );
        case BinaryIntOpcode.shiftLeft when rightVal == 0:
          // x << 0 == x
          return left;
        case BinaryIntOpcode.shiftLeft when rightVal >= 64:
          // x << n == 0 if n >= 64
          return graph.getConstant(ConstantValue.fromInt(0));
        case BinaryIntOpcode.shiftRight when rightVal == 0:
          // x >> 0 == x
          return left;
        case BinaryIntOpcode.shiftRight when rightVal >= 64:
          // x >> n == x >> 63 if n >= 64
          instr.replaceInputAt(1, graph.getConstant(ConstantValue.fromInt(63)));
          right = instr.right;
          break;
        case BinaryIntOpcode.unsignedShiftRight when rightVal == 0:
          // x >>> 0 == x
          return left;
        case BinaryIntOpcode.unsignedShiftRight when rightVal >= 64:
          // x >>> n == 0 if n >= 64
          return graph.getConstant(ConstantValue.fromInt(0));
        default:
      }
    }
    // Patterns with same lhs and rhs.
    if (left == right) {
      switch (instr.op) {
        case BinaryIntOpcode.bitAnd:
        case BinaryIntOpcode.bitOr:
          // x & x == x, x | x == x
          return left;
        case BinaryIntOpcode.sub:
        case BinaryIntOpcode.bitXor:
          // x - x == 0, x ^ x == 0
          return graph.getConstant(ConstantValue.fromInt(0));
        default:
      }
    }
    return instr;
  }

  @override
  Instruction visitUnaryIntOp(UnaryIntOp instr) {
    final operand = instr.operand;
    // Constant folding.
    if (operand is Constant) {
      ConstantValue? result = constantFolding.unaryIntOp(
        instr.op,
        operand.value,
      );
      if (result != null) {
        return graph.getConstant(result);
      }
    }
    return instr;
  }

  @override
  Instruction visitBinaryDoubleOp(BinaryDoubleOp instr) {
    Definition left = instr.left;
    Definition right = instr.right;
    // Constant folding.
    if (left is Constant && right is Constant) {
      ConstantValue? result = constantFolding.binaryDoubleOp(
        instr.op,
        left.value,
        right.value,
      );
      if (result != null) {
        return graph.getConstant(result);
      }
      return instr;
    }
    // Move constant operands of commutative operations to the right.
    if (instr.op.isCommutative && left is Constant) {
      instr.replaceInputAt(0, right);
      instr.replaceInputAt(1, left);
      left = instr.left;
      right = instr.right;
    }
    // Patterns with constant rhs.
    if (right is Constant) {
      final double rightVal = right.value.doubleValue;
      switch (instr.op) {
        case BinaryDoubleOpcode.mul when rightVal == 1.0:
          // x * 1.0 == x
          return left;
        default:
      }
    }
    // Patterns with same lhs and rhs.
    if (left == right) {
      switch (instr.op) {
        case BinaryDoubleOpcode.mul:
          // x * x == power(x, 2)
          return UnaryDoubleOp(
            graph,
            instr.sourcePosition,
            UnaryDoubleOpcode.square,
            left,
          );
        default:
      }
    }
    return instr;
  }

  @override
  Instruction visitUnaryDoubleOp(UnaryDoubleOp instr) {
    final operand = instr.operand;
    // Constant folding.
    if (operand is Constant) {
      ConstantValue? result = constantFolding.unaryDoubleOp(
        instr.op,
        operand.value,
      );
      if (result != null) {
        return graph.getConstant(result);
      }
    }
    return instr;
  }

  @override
  Instruction visitUnaryBoolOp(UnaryBoolOp instr) {
    final operand = instr.operand;
    // Constant folding.
    if (operand is Constant) {
      ConstantValue? result = constantFolding.unaryBoolOp(
        instr.op,
        operand.value,
      );
      if (result != null) {
        return graph.getConstant(result);
      }
    }
    return instr;
  }
}

/// Collects strings participating in the string interpolation.
class _StringInterpolationBuffer {
  final ConstantFolding constantFolding;

  // Contains either String or Definition.
  final List<Object> inputs = [];

  bool optimized = false;

  _StringInterpolationBuffer(this.constantFolding);

  void addString(String str) {
    // Skip empty strings.
    if (str.isEmpty) {
      optimized = true;
      return;
    }
    // Append string to the last string, if any.
    if (inputs.isNotEmpty) {
      final last = inputs.last;
      if (last is String) {
        inputs.last = last + str;
        optimized = true;
        return;
      }
    }
    inputs.add(str);
  }

  void addStringInterpolation(StringInterpolation instr) {
    for (int i = 0, n = instr.inputCount; i < n; ++i) {
      final input = instr.inputDefAt(i);
      switch (input) {
        case Constant():
          final str = constantFolding.computeToString(input.value);
          if (str != null) {
            addString(str);
          } else {
            inputs.add(input);
          }
          break;
        case StringInterpolation() when input.singleUser == instr:
          addStringInterpolation(input);
          input.removeFromGraph();
          optimized = true;
          break;
        default:
          inputs.add(input);
      }
    }
  }
}

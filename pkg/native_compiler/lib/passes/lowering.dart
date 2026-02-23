// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/global_context.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/types.dart';
import 'package:cfg/ir/visitor.dart';
import 'package:cfg/passes/pass.dart';
import 'package:cfg/utils/misc.dart';
import 'package:kernel/ast.dart' as ast;

/// IR lowering for native back-end.
///
/// Can replace instructions with multiple low-level
/// instructions or combine instructions and their inputs
/// into a single low-level instruction.
///
/// TODO: insert boxing/unboxing
final class Lowering extends Pass with DefaultInstructionVisitor<void> {
  final FunctionRegistry functionRegistry;

  Lowering(this.functionRegistry) : super('Lowering');

  late final CFunction _growableListLiteral = functionRegistry.getFunction(
    GlobalContext.instance.coreTypes.index.getProcedure(
      'dart:core',
      '_GrowableList',
      '_literal',
    ),
  );

  late final CFunction _mapFromLiteral = functionRegistry.getFunction(
    GlobalContext.instance.coreTypes.index.getProcedure(
      'dart:core',
      'Map',
      '_fromLiteral',
    ),
  );

  late final CFunction _interpolateSingle = functionRegistry.getFunction(
    GlobalContext.instance.coreTypes.index.getProcedure(
      'dart:core',
      '_StringBase',
      '_interpolateSingle',
    ),
  );

  late final CFunction _interpolate = functionRegistry.getFunction(
    GlobalContext.instance.coreTypes.index.getProcedure(
      'dart:core',
      '_StringBase',
      '_interpolate',
    ),
  );

  late final _emptyList = ConstantValue(
    ast.InstanceConstant(
      GlobalContext.instance.coreTypes.listClass.reference,
      const <ast.DartType>[const ast.DynamicType()],
      const {},
    ),
  );

  @override
  void run() {
    for (final block in graph.reversePostorder) {
      currentBlock = block;
      for (final instr in block) {
        currentInstruction = instr;
        instr.accept(this);
      }
    }
    graph.invalidateInstructionNumbering();
  }

  @override
  void defaultInstruction(Instruction instr) {}

  @override
  void visitComparison(Comparison instr) {
    // Combine (a & b) == 0, (a & b) != 0, (a & bit) == bit, (a & bit) != bit
    // into an intTestIsZero/intTestIsNotZero comparison.
    final op = instr.op;
    if (op == ComparisonOpcode.intEqual || op == ComparisonOpcode.intNotEqual) {
      final left = instr.left;
      if (left is BinaryIntOp &&
          left.op == BinaryIntOpcode.bitAnd &&
          left.singleUser == instr) {
        final right = instr.right;
        if (right is Constant) {
          final value = right.value.intValue;
          if (value == 0 || (isPowerOf2(value) && left.right == right)) {
            instr.op = ((op == ComparisonOpcode.intEqual) == (value == 0))
                ? ComparisonOpcode.intTestIsZero
                : ComparisonOpcode.intTestIsNotZero;
            instr.replaceInputAt(0, left.left);
            instr.replaceInputAt(1, left.right);
            left.removeFromGraph();
          }
        }
      }
    }
  }

  @override
  void visitBranch(Branch instr) {
    // Combine comparisons and branches.
    final condition = instr.condition;
    if (condition is Comparison && condition.singleUser == instr) {
      final op = condition.op;
      switch (condition.op) {
        // TODO(alexmarkov): support double comparisons
        case ComparisonOpcode.equal:
        case ComparisonOpcode.notEqual:
        case ComparisonOpcode.intEqual:
        case ComparisonOpcode.intNotEqual:
        case ComparisonOpcode.intLess:
        case ComparisonOpcode.intLessOrEqual:
        case ComparisonOpcode.intGreater:
        case ComparisonOpcode.intGreaterOrEqual:
        case ComparisonOpcode.intTestIsZero:
        case ComparisonOpcode.intTestIsNotZero:
          final left = condition.left;
          final right = condition.right;
          condition.removeFromGraph();
          final block = instr.block!;
          final sourcePosition = instr.sourcePosition;
          instr.removeFromGraph();
          block.lastInstruction.appendInstruction(
            CompareAndBranch(graph, sourcePosition, op, left, right),
          );
          break;
        default:
          break;
      }
    }
  }

  @override
  void visitAllocateListLiteral(AllocateListLiteral instr) {
    // List literals up to 8 elements are lowered in the front-end
    // (pkg/vm/lib/transformations/list_literals_lowering.dart)
    assert(instr.length > 8);
    final argument = AllocateList(
      graph,
      instr.sourcePosition,
      graph.getConstant(ConstantValue.fromInt(instr.length)),
    );
    argument.insertBefore(instr);
    for (int i = 0, n = instr.length; i < n; ++i) {
      final setElem = SetListElement(
        graph,
        instr.sourcePosition,
        argument,
        graph.getConstant(ConstantValue.fromInt(i)),
        instr.elementAt(i),
      );
      setElem.insertBefore(instr);
    }
    final replacement = DirectCall(
      graph,
      instr.sourcePosition,
      _growableListLiteral,
      instr.type,
      inputCount: 2,
      argumentsShape: functionRegistry.getArgumentsShape(1, types: 1),
    );
    replacement.setInputAt(0, instr.typeArguments);
    replacement.setInputAt(1, argument);
    replacement.insertBefore(instr);
    instr.replaceUsesWith(replacement);
    instr.removeFromGraph();
  }

  @override
  void visitAllocateMapLiteral(AllocateMapLiteral instr) {
    Definition argument;
    if (instr.length == 0) {
      argument = graph.getConstant(_emptyList);
    } else {
      argument = AllocateList(
        graph,
        instr.sourcePosition,
        graph.getConstant(ConstantValue.fromInt(instr.length << 1)),
      );
      argument.insertBefore(instr);
      for (int i = 0, n = instr.length; i < n; ++i) {
        final setKey = SetListElement(
          graph,
          instr.sourcePosition,
          argument,
          graph.getConstant(ConstantValue.fromInt((i << 1) + 0)),
          instr.keyAt(i),
        );
        setKey.insertBefore(instr);
        final setValue = SetListElement(
          graph,
          instr.sourcePosition,
          argument,
          graph.getConstant(ConstantValue.fromInt((i << 1) + 1)),
          instr.valueAt(i),
        );
        setValue.insertBefore(instr);
      }
    }
    final replacement = DirectCall(
      graph,
      instr.sourcePosition,
      _mapFromLiteral,
      instr.type,
      inputCount: 2,
      argumentsShape: functionRegistry.getArgumentsShape(1, types: 2),
    );
    replacement.setInputAt(0, instr.typeArguments);
    replacement.setInputAt(1, argument);
    replacement.insertBefore(instr);
    instr.replaceUsesWith(replacement);
    instr.removeFromGraph();
  }

  @override
  void visitStringInterpolation(StringInterpolation instr) {
    assert(instr.inputCount > 0);
    final isSingle = (instr.inputCount == 1);
    final CFunction target = isSingle ? _interpolateSingle : _interpolate;
    Definition argument;
    if (isSingle) {
      argument = instr.inputDefAt(0);
    } else {
      argument = AllocateList(
        graph,
        instr.sourcePosition,
        graph.getConstant(ConstantValue.fromInt(instr.inputCount)),
      );
      argument.insertBefore(instr);
      for (int i = 0, n = instr.inputCount; i < n; ++i) {
        final setElem = SetListElement(
          graph,
          instr.sourcePosition,
          argument,
          graph.getConstant(ConstantValue.fromInt(i)),
          instr.inputDefAt(i),
        );
        setElem.insertBefore(instr);
      }
    }
    final replacement = DirectCall(
      graph,
      instr.sourcePosition,
      target,
      const StringType(),
      inputCount: 1,
      argumentsShape: functionRegistry.getArgumentsShape(1),
    );
    replacement.setInputAt(0, argument);
    replacement.insertBefore(instr);
    instr.replaceUsesWith(replacement);
    instr.removeFromGraph();
  }
}

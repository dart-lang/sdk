// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/field.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/global_context.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/ir_to_text.dart';
import 'package:cfg/ir/types.dart';
import 'package:cfg/ir/visitor.dart';
import 'package:cfg/passes/pass.dart';
import 'package:cfg/utils/misc.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:native_compiler/runtime/object_layout.dart';
import 'package:native_compiler/runtime/type_utils.dart';

/// IR lowering for native back-end.
///
/// Can replace instructions with multiple low-level
/// instructions or combine instructions and their inputs
/// into a single low-level instruction.
final class Lowering extends Pass with DefaultInstructionVisitor<void> {
  final FunctionRegistry functionRegistry;
  final ObjectLayout objectLayout;

  Lowering(this.functionRegistry, this.objectLayout) : super('Lowering');

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

  late final CFunction _prependTypeArguments = functionRegistry.getFunction(
    GlobalContext.instance.coreTypes.index.getTopLevelProcedure(
      'dart:_internal',
      '_prependTypeArguments',
    ),
  );

  late final CFunction _instantiateClosure = functionRegistry.getFunction(
    GlobalContext.instance.coreTypes.index.getTopLevelProcedure(
      'dart:_internal',
      '_instantiateClosure',
    ),
  );

  late final _emptyList = ConstantValue(
    ast.ListConstant(const ast.DynamicType(), const []),
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
  void visitTypeParameters(TypeParameters instr) {
    switch (instr.kind) {
      case .classTypeParameters:
        final receiver = instr.inputDefAt(0);
        final receiverClass =
            (receiver.type.dartType as ast.InterfaceType).classNode;
        final typeArgsField = objectLayout.getTypeArgumentsField(
          receiverClass,
        )!;
        for (final use in instr.inputUses) {
          final user = use.getInstruction(graph);
          final load = LoadInstanceField(
            graph,
            user.sourcePosition,
            typeArgsField,
            receiver,
          );
          load.insertBefore(user);
          user.replaceInputAt(user.getInputIndex(use), load);
        }
      case .functionTypeParameters:
        switch (instr.inputCount) {
          case 1:
            final replacement = instr.inputDefAt(0);
            instr.replaceUsesWith(replacement);
            break;
          case 2:
            final function = graph.function;
            final numEnclosingTypeParameters =
                function.numberOfEnclosingFunctionTypeParameters;
            final numTotalTypeParameters =
                numEnclosingTypeParameters +
                function.numberOfFunctionTypeParameters;
            final replacement = DirectCall(
              graph,
              instr.sourcePosition,
              _prependTypeArguments,
              instr.type,
              inputCount: 4,
              argumentsShape: functionRegistry.getArgumentsShape(4),
            );
            replacement.setInputAt(0, instr.inputDefAt(0));
            replacement.setInputAt(1, instr.inputDefAt(1));
            replacement.setInputAt(
              2,
              graph.getConstant(
                ConstantValue.fromInt(numEnclosingTypeParameters),
              ),
            );
            replacement.setInputAt(
              3,
              graph.getConstant(ConstantValue.fromInt(numTotalTypeParameters)),
            );
            replacement.insertBefore(instr);
            instr.replaceUsesWith(replacement);
            break;
          default:
            throw 'Unexpected number of inputs in ${IrToText.instruction(instr)}';
        }
        break;
    }
    instr.removeFromGraph();
  }

  @override
  void visitAllocateObject(AllocateObject instr) {
    // Convert type arguments to the instance type arguments.
    final cls = (instr.type.dartType as ast.InterfaceType).classNode;
    if (!hasInstantiatorTypeArguments(cls)) {
      assert(!instr.hasTypeArguments);
      return;
    }
    final typeArgs = instr.typeArguments;
    final types = switch (typeArgs) {
      TypeArguments() => typeArgs.types,
      Constant(
        value: ConstantValue(constant: TypeArgumentsConstant(:var types)),
      ) =>
        types,
      Null() => const <ast.DartType>[],
      _ =>
        throw 'Unexpected type arguments ${typeArgs.runtimeType} ${IrToText.instruction(typeArgs)}',
    };
    assert(types.length == cls.typeParameters.length);
    final instanceTypes = flattenInstantiatorTypeArguments(cls, types);
    if (typeArgs is TypeArguments) {
      final instanceTypeArgs = TypeArguments(
        graph,
        instr.sourcePosition,
        instanceTypes,
        inputCount: typeArgs.inputCount,
      );
      for (var i = 0, n = typeArgs.inputCount; i < n; ++i) {
        instanceTypeArgs.setInputAt(i, typeArgs.inputDefAt(i));
      }
      instanceTypeArgs.insertBefore(instr);
      instr.replaceInputAt(0, instanceTypeArgs);
    } else {
      final instanceTypeArgs = instr.graph.getConstant(
        ConstantValue(TypeArgumentsConstant(instanceTypes)),
      );
      if (instr.hasTypeArguments) {
        instr.replaceInputAt(0, instanceTypeArgs);
      } else {
        final replacement = AllocateObject(
          graph,
          instr.sourcePosition,
          instr.type,
          instanceTypeArgs,
        );
        replacement.insertBefore(instr);
        instr.replaceUsesWith(replacement);
        instr.removeFromGraph();
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
  void visitAllocateRecordLiteral(AllocateRecordLiteral instr) {
    final obj = AllocateRecord(graph, instr.sourcePosition, instr.type);
    obj.insertBefore(instr);
    for (int i = 0, n = instr.inputCount; i < n; ++i) {
      final element = instr.elementAt(i);
      // TODO: canonicalize record fields
      final setElem = StoreInstanceField(
        graph,
        instr.sourcePosition,
        CField(RecordField(instr.type.shape, i)),
        obj,
        element,
      );
      setElem.insertBefore(instr);
    }
    instr.replaceUsesWith(obj);
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

  @override
  void visitInstantiateClosure(InstantiateClosure instr) {
    final replacement = DirectCall(
      graph,
      instr.sourcePosition,
      _instantiateClosure,
      instr.type,
      inputCount: 2,
      argumentsShape: functionRegistry.getArgumentsShape(2),
    );
    replacement.setInputAt(0, instr.closure);
    replacement.setInputAt(1, instr.typeArguments);
    replacement.insertBefore(instr);
    instr.replaceUsesWith(replacement);
    instr.removeFromGraph();
  }
}

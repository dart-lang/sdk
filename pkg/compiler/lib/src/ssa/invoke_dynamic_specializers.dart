// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common_elements.dart' show CommonElements;
import '../constants/constant_system.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/names.dart';
import '../options.dart';
import '../types/types.dart';
import '../universe/call_structure.dart';
import '../universe/selector.dart';
import '../world.dart' show ClosedWorld;
import 'nodes.dart';
import 'types.dart';

/**
 * [InvokeDynamicSpecializer] and its subclasses are helpers to
 * optimize intercepted dynamic calls. It knows what input types
 * would be beneficial for performance, and how to change a invoke
 * dynamic to a builtin instruction (e.g. HIndex, HBitNot).
 */
class InvokeDynamicSpecializer {
  const InvokeDynamicSpecializer();

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    return TypeMaskFactory.inferredTypeForSelector(
        instruction.selector, instruction.mask, results);
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      ClosedWorld closedWorld) {
    return null;
  }

  void clearAllSideEffects(HInstruction instruction) {
    instruction.sideEffects.clearAllSideEffects();
    instruction.sideEffects.clearAllDependencies();
    instruction.setUseGvn();
  }

  Selector renameToOptimizedSelector(
      String name, Selector selector, CommonElements commonElements) {
    if (selector.name == name) return selector;
    return new Selector.call(new Name(name, commonElements.interceptorsLibrary),
        new CallStructure(selector.argumentCount));
  }

  Operation operation(ConstantSystem constantSystem) => null;

  static InvokeDynamicSpecializer lookupSpecializer(Selector selector) {
    if (selector.isIndex) return const IndexSpecializer();
    if (selector.isIndexSet) return const IndexAssignSpecializer();
    String name = selector.name;
    if (selector.isOperator) {
      if (name == 'unary-') return const UnaryNegateSpecializer();
      if (name == '~') return const BitNotSpecializer();
      if (name == '+') return const AddSpecializer();
      if (name == '-') return const SubtractSpecializer();
      if (name == '*') return const MultiplySpecializer();
      if (name == '/') return const DivideSpecializer();
      if (name == '~/') return const TruncatingDivideSpecializer();
      if (name == '%') return const ModuloSpecializer();
      if (name == '>>') return const ShiftRightSpecializer();
      if (name == '<<') return const ShiftLeftSpecializer();
      if (name == '&') return const BitAndSpecializer();
      if (name == '|') return const BitOrSpecializer();
      if (name == '^') return const BitXorSpecializer();
      if (name == '==') return const EqualsSpecializer();
      if (name == '<') return const LessSpecializer();
      if (name == '<=') return const LessEqualSpecializer();
      if (name == '>') return const GreaterSpecializer();
      if (name == '>=') return const GreaterEqualSpecializer();
      return const InvokeDynamicSpecializer();
    }
    if (selector.isCall) {
      if (selector.namedArguments.length == 0) {
        int argumentCount = selector.argumentCount;
        if (argumentCount == 0) {
          if (name == 'round') return const RoundSpecializer();
          if (name == 'trim') return const TrimSpecializer();
        } else if (argumentCount == 1) {
          if (name == 'codeUnitAt') return const CodeUnitAtSpecializer();
          if (name == 'compareTo') return const CompareToSpecializer();
          if (name == 'remainder') return const RemainderSpecializer();
          if (name == 'substring') return const SubstringSpecializer();
          if (name == 'contains') return const PatternMatchSpecializer();
          if (name == 'indexOf') return const PatternMatchSpecializer();
          if (name == 'startsWith') return const PatternMatchSpecializer();
          if (name == 'endsWith') return const PatternMatchSpecializer();
        } else if (argumentCount == 2) {
          if (name == 'substring') return const SubstringSpecializer();
          if (name == 'contains') return const PatternMatchSpecializer();
          if (name == 'indexOf') return const PatternMatchSpecializer();
          if (name == 'startsWith') return const PatternMatchSpecializer();
          if (name == 'endsWith') return const PatternMatchSpecializer();
        }
      }
    }
    return const InvokeDynamicSpecializer();
  }
}

class IndexAssignSpecializer extends InvokeDynamicSpecializer {
  const IndexAssignSpecializer();

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      ClosedWorld closedWorld) {
    if (instruction.inputs[1].isMutableIndexable(closedWorld)) {
      if (!instruction.inputs[2].isInteger(closedWorld) &&
          options.enableTypeAssertions) {
        // We want the right checked mode error.
        return null;
      }
      return new HIndexAssign(instruction.inputs[1], instruction.inputs[2],
          instruction.inputs[3], instruction.selector);
    }
    return null;
  }
}

class IndexSpecializer extends InvokeDynamicSpecializer {
  const IndexSpecializer();

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      ClosedWorld closedWorld) {
    if (!instruction.inputs[1].isIndexablePrimitive(closedWorld)) return null;
    if (!instruction.inputs[2].isInteger(closedWorld) &&
        options.enableTypeAssertions) {
      // We want the right checked mode error.
      return null;
    }
    TypeMask receiverType =
        instruction.getDartReceiver(closedWorld).instructionType;
    TypeMask type = TypeMaskFactory.inferredTypeForSelector(
        instruction.selector, receiverType, results);
    return new HIndex(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, type);
  }
}

class BitNotSpecializer extends InvokeDynamicSpecializer {
  const BitNotSpecializer();

  UnaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.bitNot;
  }

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    // All bitwise operations on primitive types either produce an
    // integer or throw an error.
    if (instruction.inputs[1].isPrimitiveOrNull(closedWorld)) {
      return closedWorld.commonMasks.uint32Type;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      ClosedWorld closedWorld) {
    HInstruction input = instruction.inputs[1];
    if (input.isNumber(closedWorld)) {
      return new HBitNot(
          input,
          instruction.selector,
          computeTypeFromInputTypes(
              instruction, results, options, closedWorld));
    }
    return null;
  }
}

class UnaryNegateSpecializer extends InvokeDynamicSpecializer {
  const UnaryNegateSpecializer();

  UnaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.negate;
  }

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    TypeMask operandType = instruction.inputs[1].instructionType;
    if (instruction.inputs[1].isNumberOrNull(closedWorld)) return operandType;
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      ClosedWorld closedWorld) {
    HInstruction input = instruction.inputs[1];
    if (input.isNumber(closedWorld)) {
      return new HNegate(input, instruction.selector, input.instructionType);
    }
    return null;
  }
}

abstract class BinaryArithmeticSpecializer extends InvokeDynamicSpecializer {
  const BinaryArithmeticSpecializer();

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isIntegerOrNull(closedWorld) &&
        right.isIntegerOrNull(closedWorld)) {
      return closedWorld.commonMasks.intType;
    }
    if (left.isNumberOrNull(closedWorld)) {
      if (left.isDoubleOrNull(closedWorld) ||
          right.isDoubleOrNull(closedWorld)) {
        return closedWorld.commonMasks.doubleType;
      }
      return closedWorld.commonMasks.numType;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  bool isBuiltin(HInvokeDynamic instruction, ClosedWorld closedWorld) {
    return instruction.inputs[1].isNumber(closedWorld) &&
        instruction.inputs[2].isNumber(closedWorld);
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      ClosedWorld closedWorld) {
    if (isBuiltin(instruction, closedWorld)) {
      HInstruction builtin =
          newBuiltinVariant(instruction, results, options, closedWorld);
      if (builtin != null) return builtin;
      // Even if there is no builtin equivalent instruction, we know
      // the instruction does not have any side effect, and that it
      // can be GVN'ed.
      clearAllSideEffects(instruction);
    }
    return null;
  }

  bool inputsArePositiveIntegers(
      HInstruction instruction, ClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    return left.isPositiveIntegerOrNull(closedWorld) &&
        right.isPositiveIntegerOrNull(closedWorld);
  }

  bool inputsAreUInt31(HInstruction instruction, ClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    return left.isUInt31(closedWorld) && right.isUInt31(closedWorld);
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld);
}

class AddSpecializer extends BinaryArithmeticSpecializer {
  const AddSpecializer();

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    if (inputsAreUInt31(instruction, closedWorld)) {
      return closedWorld.commonMasks.uint32Type;
    }
    if (inputsArePositiveIntegers(instruction, closedWorld)) {
      return closedWorld.commonMasks.positiveIntType;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.add;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    return new HAdd(
        instruction.inputs[1],
        instruction.inputs[2],
        instruction.selector,
        computeTypeFromInputTypes(instruction, results, options, closedWorld));
  }
}

class DivideSpecializer extends BinaryArithmeticSpecializer {
  const DivideSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.divide;
  }

  TypeMask computeTypeFromInputTypes(
      HInstruction instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    if (left.isNumberOrNull(closedWorld)) {
      return closedWorld.commonMasks.doubleType;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    return new HDivide(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, closedWorld.commonMasks.doubleType);
  }
}

class ModuloSpecializer extends BinaryArithmeticSpecializer {
  const ModuloSpecializer();

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    if (inputsArePositiveIntegers(instruction, closedWorld)) {
      return closedWorld.commonMasks.positiveIntType;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.modulo;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    // Modulo cannot be mapped to the native operator (different semantics).

    // We can use HRemainder if both inputs are non-negative and the receiver
    // cannot be -0.0.  Note that -0.0 is considered to be an int, so until we
    // track -0.0 precisely, we have to syntatically filter inputs that cannot
    // generate -0.0.
    bool canBePositiveZero(HInstruction input) {
      if (input is HConstant) {
        ConstantValue value = input.constant;
        if (value is DoubleConstantValue && value.isZero) return true;
        if (value is IntConstantValue && value.isZero) return true;
        return false;
      }
      return true;
    }

    bool inPhi = false;
    bool canBeNegativeZero(HInstruction input) {
      if (input is HConstant) {
        ConstantValue value = input.constant;
        if (value is DoubleConstantValue && value.isMinusZero) return true;
        return false;
      }
      if (input is HAdd) {
        // '+' can only generate -0.0 when both inputs are -0.0.
        return canBeNegativeZero(input.left) && canBeNegativeZero(input.right);
      }
      if (input is HSubtract) {
        return canBeNegativeZero(input.left) && canBePositiveZero(input.right);
      }
      if (input is HPhi) {
        if (inPhi) return true;
        inPhi = true;
        bool result = input.inputs.any(canBeNegativeZero);
        inPhi = false;
        return result;
      }
      return true;
    }

    if (inputsArePositiveIntegers(instruction, closedWorld) &&
        !canBeNegativeZero(instruction.getDartReceiver(closedWorld))) {
      return new HRemainder(
          instruction.inputs[1],
          instruction.inputs[2],
          instruction.selector,
          computeTypeFromInputTypes(
              instruction, results, options, closedWorld));
    }
    // TODO(sra):
    //   a % N -->  a & (N-1), N=2^k, where a>=0, does not have -0.0 problem.

    // TODO(sra): We could avoid problems with -0.0 if we generate x % y as (x +
    // 0) % y, but we would have to fix HAdd optimizations.

    // TODO(sra): We could replace $mod with HRemainder when we don't care about
    // a -0.0 result (e.g. a % 10 == 0, a[i % 3]). This is tricky, since we
    // don't want to ruin GVN opportunities.
    return null;
  }
}

class RemainderSpecializer extends BinaryArithmeticSpecializer {
  const RemainderSpecializer();

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    if (inputsArePositiveIntegers(instruction, closedWorld)) {
      return closedWorld.commonMasks.positiveIntType;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.remainder;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    return new HRemainder(
        instruction.inputs[1],
        instruction.inputs[2],
        instruction.selector,
        computeTypeFromInputTypes(instruction, results, options, closedWorld));
  }
}

class MultiplySpecializer extends BinaryArithmeticSpecializer {
  const MultiplySpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.multiply;
  }

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    if (inputsArePositiveIntegers(instruction, closedWorld)) {
      return closedWorld.commonMasks.positiveIntType;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    return new HMultiply(
        instruction.inputs[1],
        instruction.inputs[2],
        instruction.selector,
        computeTypeFromInputTypes(instruction, results, options, closedWorld));
  }
}

class SubtractSpecializer extends BinaryArithmeticSpecializer {
  const SubtractSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.subtract;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    return new HSubtract(
        instruction.inputs[1],
        instruction.inputs[2],
        instruction.selector,
        computeTypeFromInputTypes(instruction, results, options, closedWorld));
  }
}

class TruncatingDivideSpecializer extends BinaryArithmeticSpecializer {
  const TruncatingDivideSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.truncatingDivide;
  }

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    if (hasUint31Result(instruction, closedWorld)) {
      return closedWorld.commonMasks.uint31Type;
    }
    if (inputsArePositiveIntegers(instruction, closedWorld)) {
      return closedWorld.commonMasks.positiveIntType;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  bool isNotZero(HInstruction instruction) {
    if (!instruction.isConstantInteger()) return false;
    HConstant rightConstant = instruction;
    IntConstantValue intConstant = rightConstant.constant;
    int count = intConstant.primitiveValue;
    return count != 0;
  }

  bool isTwoOrGreater(HInstruction instruction) {
    if (!instruction.isConstantInteger()) return false;
    HConstant rightConstant = instruction;
    IntConstantValue intConstant = rightConstant.constant;
    int count = intConstant.primitiveValue;
    return count >= 2;
  }

  bool hasUint31Result(HInstruction instruction, ClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (right.isPositiveInteger(closedWorld)) {
      if (left.isUInt31(closedWorld) && isNotZero(right)) {
        return true;
      }
      if (left.isUInt32(closedWorld) && isTwoOrGreater(right)) {
        return true;
      }
    }
    return false;
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      ClosedWorld closedWorld) {
    HInstruction right = instruction.inputs[2];
    if (isBuiltin(instruction, closedWorld)) {
      if (right.isPositiveInteger(closedWorld) && isNotZero(right)) {
        if (hasUint31Result(instruction, closedWorld)) {
          return newBuiltinVariant(instruction, results, options, closedWorld);
        }
        // We can call _tdivFast because the rhs is a 32bit integer
        // and not 0, nor -1.
        instruction.selector = renameToOptimizedSelector(
            '_tdivFast', instruction.selector, commonElements);
      }
      clearAllSideEffects(instruction);
    }
    return null;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    return new HTruncatingDivide(
        instruction.inputs[1],
        instruction.inputs[2],
        instruction.selector,
        computeTypeFromInputTypes(instruction, results, options, closedWorld));
  }
}

abstract class BinaryBitOpSpecializer extends BinaryArithmeticSpecializer {
  const BinaryBitOpSpecializer();

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    // All bitwise operations on primitive types either produce an
    // integer or throw an error.
    HInstruction left = instruction.inputs[1];
    if (left.isPrimitiveOrNull(closedWorld)) {
      return closedWorld.commonMasks.uint32Type;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  bool argumentLessThan32(HInstruction instruction) {
    return argumentInRange(instruction, 0, 31);
  }

  bool argumentInRange(HInstruction instruction, int low, int high) {
    if (instruction.isConstantInteger()) {
      HConstant rightConstant = instruction;
      IntConstantValue intConstant = rightConstant.constant;
      int value = intConstant.primitiveValue;
      return value >= low && value <= high;
    }
    // TODO(sra): Integrate with the bit-width analysis in codegen.dart.
    if (instruction is HBitAnd) {
      return low == 0 &&
          (argumentInRange(instruction.inputs[0], low, high) ||
              argumentInRange(instruction.inputs[1], low, high));
    }
    return false;
  }

  bool isPositive(HInstruction instruction, ClosedWorld closedWorld) {
    // TODO: We should use the value range analysis. Currently, ranges
    // are discarded just after the analysis.
    return instruction.isPositiveInteger(closedWorld);
  }
}

class ShiftLeftSpecializer extends BinaryBitOpSpecializer {
  const ShiftLeftSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.shiftLeft;
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      ClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isNumber(closedWorld)) {
      if (argumentLessThan32(right)) {
        return newBuiltinVariant(instruction, results, options, closedWorld);
      }
      // Even if there is no builtin equivalent instruction, we know
      // the instruction does not have any side effect, and that it
      // can be GVN'ed.
      clearAllSideEffects(instruction);
      if (isPositive(right, closedWorld)) {
        instruction.selector = renameToOptimizedSelector(
            '_shlPositive', instruction.selector, commonElements);
      }
    }
    return null;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    return new HShiftLeft(
        instruction.inputs[1],
        instruction.inputs[2],
        instruction.selector,
        computeTypeFromInputTypes(instruction, results, options, closedWorld));
  }
}

class ShiftRightSpecializer extends BinaryBitOpSpecializer {
  const ShiftRightSpecializer();

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    if (left.isUInt32(closedWorld)) return left.instructionType;
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      ClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isNumber(closedWorld)) {
      if (argumentLessThan32(right) && isPositive(left, closedWorld)) {
        return newBuiltinVariant(instruction, results, options, closedWorld);
      }
      // Even if there is no builtin equivalent instruction, we know
      // the instruction does not have any side effect, and that it
      // can be GVN'ed.
      clearAllSideEffects(instruction);
      if (isPositive(right, closedWorld) && isPositive(left, closedWorld)) {
        instruction.selector = renameToOptimizedSelector(
            '_shrBothPositive', instruction.selector, commonElements);
      } else if (isPositive(left, closedWorld) && right.isNumber(closedWorld)) {
        instruction.selector = renameToOptimizedSelector(
            '_shrReceiverPositive', instruction.selector, commonElements);
      } else if (isPositive(right, closedWorld)) {
        instruction.selector = renameToOptimizedSelector(
            '_shrOtherPositive', instruction.selector, commonElements);
      }
    }
    return null;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    return new HShiftRight(
        instruction.inputs[1],
        instruction.inputs[2],
        instruction.selector,
        computeTypeFromInputTypes(instruction, results, options, closedWorld));
  }

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.shiftRight;
  }
}

class BitOrSpecializer extends BinaryBitOpSpecializer {
  const BitOrSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.bitOr;
  }

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isUInt31(closedWorld) && right.isUInt31(closedWorld)) {
      return closedWorld.commonMasks.uint31Type;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    return new HBitOr(
        instruction.inputs[1],
        instruction.inputs[2],
        instruction.selector,
        computeTypeFromInputTypes(instruction, results, options, closedWorld));
  }
}

class BitAndSpecializer extends BinaryBitOpSpecializer {
  const BitAndSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.bitAnd;
  }

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isPrimitiveOrNull(closedWorld) &&
        (left.isUInt31(closedWorld) || right.isUInt31(closedWorld))) {
      return closedWorld.commonMasks.uint31Type;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    return new HBitAnd(
        instruction.inputs[1],
        instruction.inputs[2],
        instruction.selector,
        computeTypeFromInputTypes(instruction, results, options, closedWorld));
  }
}

class BitXorSpecializer extends BinaryBitOpSpecializer {
  const BitXorSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.bitXor;
  }

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isUInt31(closedWorld) && right.isUInt31(closedWorld)) {
      return closedWorld.commonMasks.uint31Type;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    return new HBitXor(
        instruction.inputs[1],
        instruction.inputs[2],
        instruction.selector,
        computeTypeFromInputTypes(instruction, results, options, closedWorld));
  }
}

abstract class RelationalSpecializer extends InvokeDynamicSpecializer {
  const RelationalSpecializer();

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      ClosedWorld closedWorld) {
    if (instruction.inputs[1].isPrimitiveOrNull(closedWorld)) {
      return closedWorld.commonMasks.boolType;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      ClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isNumber(closedWorld) && right.isNumber(closedWorld)) {
      return newBuiltinVariant(instruction, closedWorld);
    }
    return null;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, ClosedWorld closedWorld);
}

class EqualsSpecializer extends RelationalSpecializer {
  const EqualsSpecializer();

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      ClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    TypeMask instructionType = left.instructionType;
    if (right.isConstantNull() || left.isPrimitiveOrNull(closedWorld)) {
      return newBuiltinVariant(instruction, closedWorld);
    }
    Iterable<MemberEntity> matches =
        closedWorld.locateMembers(instruction.selector, instructionType);
    // This test relies on `Object.==` and `Interceptor.==` always being
    // implemented because if the selector matches by subtype, it still will be
    // a regular object or an interceptor.
    if (matches
        .every(closedWorld.commonElements.isDefaultEqualityImplementation)) {
      return newBuiltinVariant(instruction, closedWorld);
    }
    return null;
  }

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.equal;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, ClosedWorld closedWorld) {
    return new HIdentity(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, closedWorld.commonMasks.boolType);
  }
}

class LessSpecializer extends RelationalSpecializer {
  const LessSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.less;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, ClosedWorld closedWorld) {
    return new HLess(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, closedWorld.commonMasks.boolType);
  }
}

class GreaterSpecializer extends RelationalSpecializer {
  const GreaterSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.greater;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, ClosedWorld closedWorld) {
    return new HGreater(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, closedWorld.commonMasks.boolType);
  }
}

class GreaterEqualSpecializer extends RelationalSpecializer {
  const GreaterEqualSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.greaterEqual;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, ClosedWorld closedWorld) {
    return new HGreaterEqual(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, closedWorld.commonMasks.boolType);
  }
}

class LessEqualSpecializer extends RelationalSpecializer {
  const LessEqualSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.lessEqual;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, ClosedWorld closedWorld) {
    return new HLessEqual(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, closedWorld.commonMasks.boolType);
  }
}

class CodeUnitAtSpecializer extends InvokeDynamicSpecializer {
  const CodeUnitAtSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.codeUnitAt;
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      ClosedWorld closedWorld) {
    // TODO(sra): Implement a builtin HCodeUnitAt instruction and the same index
    // bounds checking optimizations as for HIndex.
    HInstruction receiver = instruction.getDartReceiver(closedWorld);
    if (receiver.isStringOrNull(closedWorld)) {
      // Even if there is no builtin equivalent instruction, we know
      // String.codeUnitAt does not have any side effect (other than throwing),
      // and that it can be GVN'ed.
      clearAllSideEffects(instruction);
      if (instruction.inputs.last.isPositiveInteger(closedWorld)) {
        instruction.selector = renameToOptimizedSelector(
            '_codeUnitAt', instruction.selector, commonElements);
      }
    }
    return null;
  }
}

class CompareToSpecializer extends InvokeDynamicSpecializer {
  const CompareToSpecializer();

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      ClosedWorld closedWorld) {
    HInstruction receiver = instruction.getDartReceiver(closedWorld);
    // `compareTo` has no side-effect (other than throwing) and can be GVN'ed
    // for some known types.
    if (receiver.isStringOrNull(closedWorld) ||
        receiver.isNumberOrNull(closedWorld)) {
      // Replace `a.compareTo(a)` with `0`, but only if receiver and argument
      // are such that no exceptions can be thrown.
      HInstruction argument = instruction.inputs.last;
      if ((receiver.isNumber(closedWorld) && argument.isNumber(closedWorld)) ||
          (receiver.isString(closedWorld) && argument.isString(closedWorld))) {
        if (identical(receiver.nonCheck(), argument.nonCheck())) {
          return graph.addConstantInt(0, closedWorld);
        }
      }
      clearAllSideEffects(instruction);
    }
    return null;
  }
}

class IdempotentStringOperationSpecializer extends InvokeDynamicSpecializer {
  const IdempotentStringOperationSpecializer();

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      ClosedWorld closedWorld) {
    HInstruction receiver = instruction.getDartReceiver(closedWorld);
    if (receiver.isStringOrNull(closedWorld)) {
      // String.xxx does not have any side effect (other than throwing), and it
      // can be GVN'ed.
      clearAllSideEffects(instruction);
    }
    return null;
  }
}

class SubstringSpecializer extends IdempotentStringOperationSpecializer {
  const SubstringSpecializer();
}

class TrimSpecializer extends IdempotentStringOperationSpecializer {
  const TrimSpecializer();
}

class PatternMatchSpecializer extends InvokeDynamicSpecializer {
  const PatternMatchSpecializer();

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      ClosedWorld closedWorld) {
    HInstruction receiver = instruction.getDartReceiver(closedWorld);
    HInstruction pattern = instruction.inputs[2];
    if (receiver.isStringOrNull(closedWorld) &&
        pattern.isStringOrNull(closedWorld)) {
      // String.contains(String s) does not have any side effect (other than
      // throwing), and it can be GVN'ed.
      clearAllSideEffects(instruction);
    }
    return null;
  }
}

class RoundSpecializer extends InvokeDynamicSpecializer {
  const RoundSpecializer();

  UnaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.round;
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      ClosedWorld closedWorld) {
    HInstruction receiver = instruction.getDartReceiver(closedWorld);
    if (receiver.isNumberOrNull(closedWorld)) {
      // Even if there is no builtin equivalent instruction, we know the
      // instruction does not have any side effect, and that it can be GVN'ed.
      clearAllSideEffects(instruction);
    }
    return null;
  }
}

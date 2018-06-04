// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common_elements.dart' show CommonElements;
import '../constants/constant_system.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/names.dart';
import '../options.dart';
import '../types/abstract_value_domain.dart';
import '../types/types.dart';
import '../universe/call_structure.dart';
import '../universe/selector.dart';
import '../world.dart' show JClosedWorld;
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

  AbstractValue computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
    return AbstractValueFactory.inferredTypeForSelector(
        instruction.selector, instruction.mask, results);
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      JClosedWorld closedWorld) {
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
          if (name == 'abs') return const AbsSpecializer();
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
      JClosedWorld closedWorld) {
    HInstruction receiver = instruction.inputs[1];
    HInstruction index = instruction.inputs[2];
    if (!receiver.isMutableIndexable(closedWorld.abstractValueDomain))
      return null;
    if (!index.isInteger(closedWorld.abstractValueDomain) &&
        options.enableTypeAssertions) {
      // We want the right checked mode error.
      return null;
    }

    HInstruction value = instruction.inputs[3];
    if (options.parameterCheckPolicy.isEmitted) {
      if (!_valueParameterCheckAlwaysSucceeds(
          instruction, receiver, value, commonElements, closedWorld)) {
        return null;
      }
    }
    return new HIndexAssign(closedWorld.abstractValueDomain, receiver, index,
        value, instruction.selector);
  }

  /// Returns [true] if [value] meets the requirements for being stored into
  /// indexable [receiver].
  bool _valueParameterCheckAlwaysSucceeds(
      HInvokeDynamic instruction,
      HInstruction receiver,
      HInstruction value,
      CommonElements commonElements,
      JClosedWorld closedWorld) {
    // Handle typed arrays by recognizing the exact implementation of `[]=` and
    // checking if [value] has the appropriate type.
    if (instruction.element != null) {
      ClassEntity cls = instruction.element.enclosingClass;
      if (cls == commonElements.typedArrayOfIntClass) {
        return value.isInteger(closedWorld.abstractValueDomain);
      } else if (cls == commonElements.typedArrayOfDoubleClass) {
        return value.isNumber(closedWorld.abstractValueDomain);
      }
    }

    // The type check will pass if it passed before. We know it passed before if
    // the value was loaded from the same indexable.
    if (value is HIndex) {
      if (value.receiver.nonCheck() == receiver.nonCheck()) {
        return true;
      }
    }

    return false;
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
      JClosedWorld closedWorld) {
    if (!instruction.inputs[1]
        .isIndexablePrimitive(closedWorld.abstractValueDomain)) return null;
    if (!instruction.inputs[2].isInteger(closedWorld.abstractValueDomain) &&
        options.enableTypeAssertions) {
      // We want the right checked mode error.
      return null;
    }
    AbstractValue receiverType =
        instruction.getDartReceiver(closedWorld).instructionType;
    AbstractValue type = AbstractValueFactory.inferredTypeForSelector(
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

  AbstractValue computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
    // All bitwise operations on primitive types either produce an
    // integer or throw an error.
    if (instruction.inputs[1]
        .isPrimitiveOrNull(closedWorld.abstractValueDomain)) {
      return closedWorld.abstractValueDomain.uint32Type;
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
      JClosedWorld closedWorld) {
    HInstruction input = instruction.inputs[1];
    if (input.isNumber(closedWorld.abstractValueDomain)) {
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

  AbstractValue computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
    HInstruction operand = instruction.inputs[1];
    if (operand.isNumberOrNull(closedWorld.abstractValueDomain)) {
      // We have integer subclasses that represent ranges, so widen any int
      // subclass to full integer.
      if (operand.isIntegerOrNull(closedWorld.abstractValueDomain)) {
        return closedWorld.abstractValueDomain.intType;
      }
      if (operand.isDoubleOrNull(closedWorld.abstractValueDomain)) {
        return closedWorld.abstractValueDomain.doubleType;
      }
      return closedWorld.abstractValueDomain.numType;
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
      JClosedWorld closedWorld) {
    HInstruction input = instruction.inputs[1];
    if (input.isNumber(closedWorld.abstractValueDomain)) {
      return new HNegate(
          input,
          instruction.selector,
          computeTypeFromInputTypes(
              instruction, results, options, closedWorld));
    }
    return null;
  }
}

class AbsSpecializer extends InvokeDynamicSpecializer {
  const AbsSpecializer();

  UnaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.abs;
  }

  AbstractValue computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
    HInstruction input = instruction.inputs[1];
    if (input.isNumberOrNull(closedWorld.abstractValueDomain)) {
      return closedWorld.abstractValueDomain.excludeNull(input.instructionType);
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
      JClosedWorld closedWorld) {
    HInstruction input = instruction.inputs[1];
    if (input.isNumber(closedWorld.abstractValueDomain)) {
      return new HAbs(
          input,
          instruction.selector,
          computeTypeFromInputTypes(
              instruction, results, options, closedWorld));
    }
    return null;
  }
}

abstract class BinaryArithmeticSpecializer extends InvokeDynamicSpecializer {
  const BinaryArithmeticSpecializer();

  AbstractValue computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isIntegerOrNull(closedWorld.abstractValueDomain) &&
        right.isIntegerOrNull(closedWorld.abstractValueDomain)) {
      return closedWorld.abstractValueDomain.intType;
    }
    if (left.isNumberOrNull(closedWorld.abstractValueDomain)) {
      if (left.isDoubleOrNull(closedWorld.abstractValueDomain) ||
          right.isDoubleOrNull(closedWorld.abstractValueDomain)) {
        return closedWorld.abstractValueDomain.doubleType;
      }
      return closedWorld.abstractValueDomain.numType;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  bool isBuiltin(HInvokeDynamic instruction, JClosedWorld closedWorld) {
    return instruction.inputs[1].isNumber(closedWorld.abstractValueDomain) &&
        instruction.inputs[2].isNumber(closedWorld.abstractValueDomain);
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      JClosedWorld closedWorld) {
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
      HInstruction instruction, JClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    return left.isPositiveIntegerOrNull(closedWorld.abstractValueDomain) &&
        right.isPositiveIntegerOrNull(closedWorld.abstractValueDomain);
  }

  bool inputsAreUInt31(HInstruction instruction, JClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    return left.isUInt31(closedWorld.abstractValueDomain) &&
        right.isUInt31(closedWorld.abstractValueDomain);
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld);
}

class AddSpecializer extends BinaryArithmeticSpecializer {
  const AddSpecializer();

  AbstractValue computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
    if (inputsAreUInt31(instruction, closedWorld)) {
      return closedWorld.abstractValueDomain.uint32Type;
    }
    if (inputsArePositiveIntegers(instruction, closedWorld)) {
      return closedWorld.abstractValueDomain.positiveIntType;
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
      JClosedWorld closedWorld) {
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

  AbstractValue computeTypeFromInputTypes(
      HInstruction instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    if (left.isNumberOrNull(closedWorld.abstractValueDomain)) {
      return closedWorld.abstractValueDomain.doubleType;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
    return new HDivide(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, closedWorld.abstractValueDomain.doubleType);
  }
}

class ModuloSpecializer extends BinaryArithmeticSpecializer {
  const ModuloSpecializer();

  AbstractValue computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
    if (inputsArePositiveIntegers(instruction, closedWorld)) {
      return closedWorld.abstractValueDomain.positiveIntType;
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
      JClosedWorld closedWorld) {
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

  AbstractValue computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
    if (inputsArePositiveIntegers(instruction, closedWorld)) {
      return closedWorld.abstractValueDomain.positiveIntType;
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
      JClosedWorld closedWorld) {
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

  AbstractValue computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
    if (inputsArePositiveIntegers(instruction, closedWorld)) {
      return closedWorld.abstractValueDomain.positiveIntType;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
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
      JClosedWorld closedWorld) {
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

  AbstractValue computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
    if (hasUint31Result(instruction, closedWorld)) {
      return closedWorld.abstractValueDomain.uint31Type;
    }
    if (inputsArePositiveIntegers(instruction, closedWorld)) {
      return closedWorld.abstractValueDomain.positiveIntType;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  bool isNotZero(HInstruction instruction) {
    if (!instruction.isConstantInteger()) return false;
    HConstant rightConstant = instruction;
    IntConstantValue intConstant = rightConstant.constant;
    BigInt count = intConstant.intValue;
    return count != BigInt.zero;
  }

  bool isTwoOrGreater(HInstruction instruction) {
    if (!instruction.isConstantInteger()) return false;
    HConstant rightConstant = instruction;
    IntConstantValue intConstant = rightConstant.constant;
    BigInt count = intConstant.intValue;
    return count >= BigInt.two;
  }

  bool hasUint31Result(HInstruction instruction, JClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (right.isPositiveInteger(closedWorld.abstractValueDomain)) {
      if (left.isUInt31(closedWorld.abstractValueDomain) && isNotZero(right)) {
        return true;
      }
      if (left.isUInt32(closedWorld.abstractValueDomain) &&
          isTwoOrGreater(right)) {
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
      JClosedWorld closedWorld) {
    HInstruction right = instruction.inputs[2];
    if (isBuiltin(instruction, closedWorld)) {
      if (right.isPositiveInteger(closedWorld.abstractValueDomain) &&
          isNotZero(right)) {
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
      JClosedWorld closedWorld) {
    return new HTruncatingDivide(
        instruction.inputs[1],
        instruction.inputs[2],
        instruction.selector,
        computeTypeFromInputTypes(instruction, results, options, closedWorld));
  }
}

abstract class BinaryBitOpSpecializer extends BinaryArithmeticSpecializer {
  const BinaryBitOpSpecializer();

  AbstractValue computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
    // All bitwise operations on primitive types either produce an
    // integer or throw an error.
    HInstruction left = instruction.inputs[1];
    if (left.isPrimitiveOrNull(closedWorld.abstractValueDomain)) {
      return closedWorld.abstractValueDomain.uint32Type;
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
      int value = intConstant.intValue.toInt();
      assert(intConstant.intValue ==
          new BigInt.from(intConstant.intValue.toInt()));
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

  bool isPositive(HInstruction instruction, JClosedWorld closedWorld) {
    // TODO: We should use the value range analysis. Currently, ranges
    // are discarded just after the analysis.
    return instruction.isPositiveInteger(closedWorld.abstractValueDomain);
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
      JClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isNumber(closedWorld.abstractValueDomain)) {
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
      JClosedWorld closedWorld) {
    return new HShiftLeft(
        instruction.inputs[1],
        instruction.inputs[2],
        instruction.selector,
        computeTypeFromInputTypes(instruction, results, options, closedWorld));
  }
}

class ShiftRightSpecializer extends BinaryBitOpSpecializer {
  const ShiftRightSpecializer();

  AbstractValue computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    if (left.isUInt32(closedWorld.abstractValueDomain))
      return left.instructionType;
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      JClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isNumber(closedWorld.abstractValueDomain)) {
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
      } else if (isPositive(left, closedWorld) &&
          right.isNumber(closedWorld.abstractValueDomain)) {
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
      JClosedWorld closedWorld) {
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

  AbstractValue computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isUInt31(closedWorld.abstractValueDomain) &&
        right.isUInt31(closedWorld.abstractValueDomain)) {
      return closedWorld.abstractValueDomain.uint31Type;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
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

  AbstractValue computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isPrimitiveOrNull(closedWorld.abstractValueDomain) &&
        (left.isUInt31(closedWorld.abstractValueDomain) ||
            right.isUInt31(closedWorld.abstractValueDomain))) {
      return closedWorld.abstractValueDomain.uint31Type;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
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

  AbstractValue computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isUInt31(closedWorld.abstractValueDomain) &&
        right.isUInt31(closedWorld.abstractValueDomain)) {
      return closedWorld.abstractValueDomain.uint31Type;
    }
    return super
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
    return new HBitXor(
        instruction.inputs[1],
        instruction.inputs[2],
        instruction.selector,
        computeTypeFromInputTypes(instruction, results, options, closedWorld));
  }
}

abstract class RelationalSpecializer extends InvokeDynamicSpecializer {
  const RelationalSpecializer();

  AbstractValue computeTypeFromInputTypes(
      HInvokeDynamic instruction,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      JClosedWorld closedWorld) {
    if (instruction.inputs[1]
        .isPrimitiveOrNull(closedWorld.abstractValueDomain)) {
      return closedWorld.abstractValueDomain.boolType;
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
      JClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isNumber(closedWorld.abstractValueDomain) &&
        right.isNumber(closedWorld.abstractValueDomain)) {
      return newBuiltinVariant(instruction, closedWorld);
    }
    return null;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, JClosedWorld closedWorld);
}

class EqualsSpecializer extends RelationalSpecializer {
  const EqualsSpecializer();

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction,
      HGraph graph,
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      CommonElements commonElements,
      JClosedWorld closedWorld) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    AbstractValue instructionType = left.instructionType;
    if (right.isConstantNull() ||
        left.isPrimitiveOrNull(closedWorld.abstractValueDomain)) {
      return newBuiltinVariant(instruction, closedWorld);
    }
    if (closedWorld.includesClosureCall(
        instruction.selector, instructionType)) {
      return null;
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
      HInvokeDynamic instruction, JClosedWorld closedWorld) {
    return new HIdentity(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, closedWorld.abstractValueDomain.boolType);
  }
}

class LessSpecializer extends RelationalSpecializer {
  const LessSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.less;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, JClosedWorld closedWorld) {
    return new HLess(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, closedWorld.abstractValueDomain.boolType);
  }
}

class GreaterSpecializer extends RelationalSpecializer {
  const GreaterSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.greater;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, JClosedWorld closedWorld) {
    return new HGreater(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, closedWorld.abstractValueDomain.boolType);
  }
}

class GreaterEqualSpecializer extends RelationalSpecializer {
  const GreaterEqualSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.greaterEqual;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, JClosedWorld closedWorld) {
    return new HGreaterEqual(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, closedWorld.abstractValueDomain.boolType);
  }
}

class LessEqualSpecializer extends RelationalSpecializer {
  const LessEqualSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.lessEqual;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, JClosedWorld closedWorld) {
    return new HLessEqual(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, closedWorld.abstractValueDomain.boolType);
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
      JClosedWorld closedWorld) {
    // TODO(sra): Implement a builtin HCodeUnitAt instruction and the same index
    // bounds checking optimizations as for HIndex.
    HInstruction receiver = instruction.getDartReceiver(closedWorld);
    if (receiver.isStringOrNull(closedWorld.abstractValueDomain)) {
      // Even if there is no builtin equivalent instruction, we know
      // String.codeUnitAt does not have any side effect (other than throwing),
      // and that it can be GVN'ed.
      clearAllSideEffects(instruction);
      if (instruction.inputs.last
          .isPositiveInteger(closedWorld.abstractValueDomain)) {
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
      JClosedWorld closedWorld) {
    HInstruction receiver = instruction.getDartReceiver(closedWorld);
    // `compareTo` has no side-effect (other than throwing) and can be GVN'ed
    // for some known types.
    if (receiver.isStringOrNull(closedWorld.abstractValueDomain) ||
        receiver.isNumberOrNull(closedWorld.abstractValueDomain)) {
      // Replace `a.compareTo(a)` with `0`, but only if receiver and argument
      // are such that no exceptions can be thrown.
      HInstruction argument = instruction.inputs.last;
      if ((receiver.isNumber(closedWorld.abstractValueDomain) &&
              argument.isNumber(closedWorld.abstractValueDomain)) ||
          (receiver.isString(closedWorld.abstractValueDomain) &&
              argument.isString(closedWorld.abstractValueDomain))) {
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
      JClosedWorld closedWorld) {
    HInstruction receiver = instruction.getDartReceiver(closedWorld);
    if (receiver.isStringOrNull(closedWorld.abstractValueDomain)) {
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
      JClosedWorld closedWorld) {
    HInstruction receiver = instruction.getDartReceiver(closedWorld);
    HInstruction pattern = instruction.inputs[2];
    if (receiver.isStringOrNull(closedWorld.abstractValueDomain) &&
        pattern.isStringOrNull(closedWorld.abstractValueDomain)) {
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
      JClosedWorld closedWorld) {
    HInstruction receiver = instruction.getDartReceiver(closedWorld);
    if (receiver.isNumberOrNull(closedWorld.abstractValueDomain)) {
      // Even if there is no builtin equivalent instruction, we know the
      // instruction does not have any side effect, and that it can be GVN'ed.
      clearAllSideEffects(instruction);
    }
    return null;
  }
}

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../compiler.dart' show Compiler;
import '../constants/constant_system.dart';
import '../constants/values.dart';
import '../elements/elements.dart';
import '../js_backend/js_backend.dart';
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
      HInvokeDynamic instruction, Compiler compiler) {
    return TypeMaskFactory.inferredTypeForSelector(
        instruction.selector, instruction.mask, compiler);
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction, Compiler compiler) {
    return null;
  }

  void clearAllSideEffects(HInstruction instruction) {
    instruction.sideEffects.clearAllSideEffects();
    instruction.sideEffects.clearAllDependencies();
    instruction.setUseGvn();
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
        } else if (argumentCount == 1) {
          if (name == 'codeUnitAt') return const CodeUnitAtSpecializer();
        }
      }
    }
    return const InvokeDynamicSpecializer();
  }
}

class IndexAssignSpecializer extends InvokeDynamicSpecializer {
  const IndexAssignSpecializer();

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction, Compiler compiler) {
    if (instruction.inputs[1].isMutableIndexable(compiler)) {
      if (!instruction.inputs[2].isInteger(compiler) &&
          compiler.options.enableTypeAssertions) {
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
      HInvokeDynamic instruction, Compiler compiler) {
    if (!instruction.inputs[1].isIndexablePrimitive(compiler)) return null;
    if (!instruction.inputs[2].isInteger(compiler) &&
        compiler.options.enableTypeAssertions) {
      // We want the right checked mode error.
      return null;
    }
    TypeMask receiverType =
        instruction.getDartReceiver(compiler).instructionType;
    TypeMask type = TypeMaskFactory.inferredTypeForSelector(
        instruction.selector, receiverType, compiler);
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
      HInvokeDynamic instruction, Compiler compiler) {
    // All bitwise operations on primitive types either produce an
    // integer or throw an error.
    JavaScriptBackend backend = compiler.backend;
    if (instruction.inputs[1].isPrimitiveOrNull(compiler)) {
      return backend.uint32Type;
    }
    return super.computeTypeFromInputTypes(instruction, compiler);
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction, Compiler compiler) {
    HInstruction input = instruction.inputs[1];
    if (input.isNumber(compiler)) {
      return new HBitNot(input, instruction.selector,
          computeTypeFromInputTypes(instruction, compiler));
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
      HInvokeDynamic instruction, Compiler compiler) {
    TypeMask operandType = instruction.inputs[1].instructionType;
    if (instruction.inputs[1].isNumberOrNull(compiler)) return operandType;
    return super.computeTypeFromInputTypes(instruction, compiler);
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction, Compiler compiler) {
    HInstruction input = instruction.inputs[1];
    if (input.isNumber(compiler)) {
      return new HNegate(input, instruction.selector, input.instructionType);
    }
    return null;
  }
}

abstract class BinaryArithmeticSpecializer extends InvokeDynamicSpecializer {
  const BinaryArithmeticSpecializer();

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction, Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    JavaScriptBackend backend = compiler.backend;
    if (left.isIntegerOrNull(compiler) && right.isIntegerOrNull(compiler)) {
      return backend.intType;
    }
    if (left.isNumberOrNull(compiler)) {
      if (left.isDoubleOrNull(compiler) || right.isDoubleOrNull(compiler)) {
        return backend.doubleType;
      }
      return backend.numType;
    }
    return super.computeTypeFromInputTypes(instruction, compiler);
  }

  bool isBuiltin(HInvokeDynamic instruction, Compiler compiler) {
    return instruction.inputs[1].isNumber(compiler) &&
        instruction.inputs[2].isNumber(compiler);
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction, Compiler compiler) {
    if (isBuiltin(instruction, compiler)) {
      HInstruction builtin = newBuiltinVariant(instruction, compiler);
      if (builtin != null) return builtin;
      // Even if there is no builtin equivalent instruction, we know
      // the instruction does not have any side effect, and that it
      // can be GVN'ed.
      clearAllSideEffects(instruction);
    }
    return null;
  }

  bool inputsArePositiveIntegers(HInstruction instruction, Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    return left.isPositiveIntegerOrNull(compiler) &&
        right.isPositiveIntegerOrNull(compiler);
  }

  bool inputsAreUInt31(HInstruction instruction, Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    return left.isUInt31(compiler) && right.isUInt31(compiler);
  }

  HInstruction newBuiltinVariant(HInvokeDynamic instruction, Compiler compiler);

  Selector renameToOptimizedSelector(
      String name, Selector selector, Compiler compiler) {
    if (selector.name == name) return selector;
    JavaScriptBackend backend = compiler.backend;
    return new Selector.call(
        new Name(name, backend.helpers.interceptorsLibrary),
        new CallStructure(selector.argumentCount));
  }
}

class AddSpecializer extends BinaryArithmeticSpecializer {
  const AddSpecializer();

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction, Compiler compiler) {
    if (inputsAreUInt31(instruction, compiler)) {
      JavaScriptBackend backend = compiler.backend;
      return backend.uint32Type;
    }
    if (inputsArePositiveIntegers(instruction, compiler)) {
      JavaScriptBackend backend = compiler.backend;
      return backend.positiveIntType;
    }
    return super.computeTypeFromInputTypes(instruction, compiler);
  }

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.add;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, Compiler compiler) {
    return new HAdd(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, computeTypeFromInputTypes(instruction, compiler));
  }
}

class DivideSpecializer extends BinaryArithmeticSpecializer {
  const DivideSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.divide;
  }

  TypeMask computeTypeFromInputTypes(
      HInstruction instruction, Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    JavaScriptBackend backend = compiler.backend;
    if (left.isNumberOrNull(compiler)) {
      return backend.doubleType;
    }
    return super.computeTypeFromInputTypes(instruction, compiler);
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return new HDivide(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, backend.doubleType);
  }
}

class ModuloSpecializer extends BinaryArithmeticSpecializer {
  const ModuloSpecializer();

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction, Compiler compiler) {
    if (inputsArePositiveIntegers(instruction, compiler)) {
      JavaScriptBackend backend = compiler.backend;
      return backend.positiveIntType;
    }
    return super.computeTypeFromInputTypes(instruction, compiler);
  }

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.modulo;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, Compiler compiler) {
    // Modulo cannot be mapped to the native operator (different semantics).
    // TODO(sra): For non-negative values we can use JavaScript's %.
    return null;
  }
}

class MultiplySpecializer extends BinaryArithmeticSpecializer {
  const MultiplySpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.multiply;
  }

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction, Compiler compiler) {
    if (inputsArePositiveIntegers(instruction, compiler)) {
      JavaScriptBackend backend = compiler.backend;
      return backend.positiveIntType;
    }
    return super.computeTypeFromInputTypes(instruction, compiler);
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, Compiler compiler) {
    return new HMultiply(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, computeTypeFromInputTypes(instruction, compiler));
  }
}

class SubtractSpecializer extends BinaryArithmeticSpecializer {
  const SubtractSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.subtract;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, Compiler compiler) {
    return new HSubtract(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, computeTypeFromInputTypes(instruction, compiler));
  }
}

class TruncatingDivideSpecializer extends BinaryArithmeticSpecializer {
  const TruncatingDivideSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.truncatingDivide;
  }

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction, Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    if (hasUint31Result(instruction, compiler)) {
      return backend.uint31Type;
    }
    if (inputsArePositiveIntegers(instruction, compiler)) {
      return backend.positiveIntType;
    }
    return super.computeTypeFromInputTypes(instruction, compiler);
  }

  bool isNotZero(HInstruction instruction, Compiler compiler) {
    if (!instruction.isConstantInteger()) return false;
    HConstant rightConstant = instruction;
    IntConstantValue intConstant = rightConstant.constant;
    int count = intConstant.primitiveValue;
    return count != 0;
  }

  bool isTwoOrGreater(HInstruction instruction, Compiler compiler) {
    if (!instruction.isConstantInteger()) return false;
    HConstant rightConstant = instruction;
    IntConstantValue intConstant = rightConstant.constant;
    int count = intConstant.primitiveValue;
    return count >= 2;
  }

  bool hasUint31Result(HInstruction instruction, Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (right.isPositiveInteger(compiler)) {
      if (left.isUInt31(compiler) && isNotZero(right, compiler)) {
        return true;
      }
      if (left.isUInt32(compiler) && isTwoOrGreater(right, compiler)) {
        return true;
      }
    }
    return false;
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction, Compiler compiler) {
    HInstruction right = instruction.inputs[2];
    if (isBuiltin(instruction, compiler)) {
      if (right.isPositiveInteger(compiler) && isNotZero(right, compiler)) {
        if (hasUint31Result(instruction, compiler)) {
          return newBuiltinVariant(instruction, compiler);
        }
        // We can call _tdivFast because the rhs is a 32bit integer
        // and not 0, nor -1.
        instruction.selector = renameToOptimizedSelector(
            '_tdivFast', instruction.selector, compiler);
      }
      clearAllSideEffects(instruction);
    }
    return null;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, Compiler compiler) {
    return new HTruncatingDivide(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, computeTypeFromInputTypes(instruction, compiler));
  }
}

abstract class BinaryBitOpSpecializer extends BinaryArithmeticSpecializer {
  const BinaryBitOpSpecializer();

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction, Compiler compiler) {
    // All bitwise operations on primitive types either produce an
    // integer or throw an error.
    HInstruction left = instruction.inputs[1];
    JavaScriptBackend backend = compiler.backend;
    if (left.isPrimitiveOrNull(compiler)) {
      return backend.uint32Type;
    }
    return super.computeTypeFromInputTypes(instruction, compiler);
  }

  bool argumentLessThan32(HInstruction instruction) {
    if (!instruction.isConstantInteger()) return false;
    HConstant rightConstant = instruction;
    IntConstantValue intConstant = rightConstant.constant;
    int count = intConstant.primitiveValue;
    return count >= 0 && count <= 31;
  }

  bool isPositive(HInstruction instruction, Compiler compiler) {
    // TODO: We should use the value range analysis. Currently, ranges
    // are discarded just after the analysis.
    return instruction.isPositiveInteger(compiler);
  }
}

class ShiftLeftSpecializer extends BinaryBitOpSpecializer {
  const ShiftLeftSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.shiftLeft;
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction, Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isNumber(compiler)) {
      if (argumentLessThan32(right)) {
        return newBuiltinVariant(instruction, compiler);
      }
      // Even if there is no builtin equivalent instruction, we know
      // the instruction does not have any side effect, and that it
      // can be GVN'ed.
      clearAllSideEffects(instruction);
      if (isPositive(right, compiler)) {
        instruction.selector = renameToOptimizedSelector(
            '_shlPositive', instruction.selector, compiler);
      }
    }
    return null;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, Compiler compiler) {
    return new HShiftLeft(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, computeTypeFromInputTypes(instruction, compiler));
  }
}

class ShiftRightSpecializer extends BinaryBitOpSpecializer {
  const ShiftRightSpecializer();

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction, Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    if (left.isUInt32(compiler)) return left.instructionType;
    return super.computeTypeFromInputTypes(instruction, compiler);
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction, Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isNumber(compiler)) {
      if (argumentLessThan32(right) && isPositive(left, compiler)) {
        return newBuiltinVariant(instruction, compiler);
      }
      // Even if there is no builtin equivalent instruction, we know
      // the instruction does not have any side effect, and that it
      // can be GVN'ed.
      clearAllSideEffects(instruction);
      if (isPositive(right, compiler) && isPositive(left, compiler)) {
        instruction.selector = renameToOptimizedSelector(
            '_shrBothPositive', instruction.selector, compiler);
      } else if (isPositive(left, compiler) && right.isNumber(compiler)) {
        instruction.selector = renameToOptimizedSelector(
            '_shrReceiverPositive', instruction.selector, compiler);
      } else if (isPositive(right, compiler)) {
        instruction.selector = renameToOptimizedSelector(
            '_shrOtherPositive', instruction.selector, compiler);
      }
    }
    return null;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, Compiler compiler) {
    return new HShiftRight(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, computeTypeFromInputTypes(instruction, compiler));
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
      HInvokeDynamic instruction, Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    JavaScriptBackend backend = compiler.backend;
    if (left.isUInt31(compiler) && right.isUInt31(compiler)) {
      return backend.uint31Type;
    }
    return super.computeTypeFromInputTypes(instruction, compiler);
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, Compiler compiler) {
    return new HBitOr(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, computeTypeFromInputTypes(instruction, compiler));
  }
}

class BitAndSpecializer extends BinaryBitOpSpecializer {
  const BitAndSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.bitAnd;
  }

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction, Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    JavaScriptBackend backend = compiler.backend;
    if (left.isPrimitiveOrNull(compiler) &&
        (left.isUInt31(compiler) || right.isUInt31(compiler))) {
      return backend.uint31Type;
    }
    return super.computeTypeFromInputTypes(instruction, compiler);
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, Compiler compiler) {
    return new HBitAnd(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, computeTypeFromInputTypes(instruction, compiler));
  }
}

class BitXorSpecializer extends BinaryBitOpSpecializer {
  const BitXorSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.bitXor;
  }

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction, Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    JavaScriptBackend backend = compiler.backend;
    if (left.isUInt31(compiler) && right.isUInt31(compiler)) {
      return backend.uint31Type;
    }
    return super.computeTypeFromInputTypes(instruction, compiler);
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, Compiler compiler) {
    return new HBitXor(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, computeTypeFromInputTypes(instruction, compiler));
  }
}

abstract class RelationalSpecializer extends InvokeDynamicSpecializer {
  const RelationalSpecializer();

  TypeMask computeTypeFromInputTypes(
      HInvokeDynamic instruction, Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    if (instruction.inputs[1].isPrimitiveOrNull(compiler)) {
      return backend.boolType;
    }
    return super.computeTypeFromInputTypes(instruction, compiler);
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction, Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isNumber(compiler) && right.isNumber(compiler)) {
      return newBuiltinVariant(instruction, compiler);
    }
    return null;
  }

  HInstruction newBuiltinVariant(HInvokeDynamic instruction, Compiler compiler);
}

class EqualsSpecializer extends RelationalSpecializer {
  const EqualsSpecializer();

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction, Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    TypeMask instructionType = left.instructionType;
    if (right.isConstantNull() || left.isPrimitiveOrNull(compiler)) {
      return newBuiltinVariant(instruction, compiler);
    }
    ClosedWorld world = compiler.closedWorld;
    JavaScriptBackend backend = compiler.backend;
    Iterable<Element> matches =
        world.allFunctions.filter(instruction.selector, instructionType);
    // This test relies the on `Object.==` and `Interceptor.==` always being
    // implemented because if the selector matches by subtype, it still will be
    // a regular object or an interceptor.
    if (matches.every(backend.isDefaultEqualityImplementation)) {
      return newBuiltinVariant(instruction, compiler);
    }
    return null;
  }

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.equal;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return new HIdentity(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, backend.boolType);
  }
}

class LessSpecializer extends RelationalSpecializer {
  const LessSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.less;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return new HLess(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, backend.boolType);
  }
}

class GreaterSpecializer extends RelationalSpecializer {
  const GreaterSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.greater;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return new HGreater(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, backend.boolType);
  }
}

class GreaterEqualSpecializer extends RelationalSpecializer {
  const GreaterEqualSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.greaterEqual;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return new HGreaterEqual(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, backend.boolType);
  }
}

class LessEqualSpecializer extends RelationalSpecializer {
  const LessEqualSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.lessEqual;
  }

  HInstruction newBuiltinVariant(
      HInvokeDynamic instruction, Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return new HLessEqual(instruction.inputs[1], instruction.inputs[2],
        instruction.selector, backend.boolType);
  }
}

class CodeUnitAtSpecializer extends InvokeDynamicSpecializer {
  const CodeUnitAtSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.codeUnitAt;
  }

  HInstruction tryConvertToBuiltin(
      HInvokeDynamic instruction, Compiler compiler) {
    // TODO(sra): Implement a builtin HCodeUnitAt instruction and the same index
    // bounds checking optimizations as for HIndex.
    HInstruction receiver = instruction.getDartReceiver(compiler);
    if (receiver.isStringOrNull(compiler)) {
      // Even if there is no builtin equivalent instruction, we know
      // String.codeUnitAt does not have any side effect (other than throwing),
      // and that it can be GVN'ed.
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
      HInvokeDynamic instruction, Compiler compiler) {
    HInstruction receiver = instruction.getDartReceiver(compiler);
    if (receiver.isNumberOrNull(compiler)) {
      // Even if there is no builtin equivalent instruction, we know the
      // instruction does not have any side effect, and that it can be GVN'ed.
      clearAllSideEffects(instruction);
    }
    return null;
  }
}

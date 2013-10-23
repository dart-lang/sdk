// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

/**
 * [InvokeDynamicSpecializer] and its subclasses are helpers to
 * optimize intercepted dynamic calls. It knows what input types
 * would be beneficial for performance, and how to change a invoke
 * dynamic to a builtin instruction (e.g. HIndex, HBitNot).
 */
class InvokeDynamicSpecializer {
  const InvokeDynamicSpecializer();

  HType computeTypeFromInputTypes(HInvokeDynamic instruction,
                                  Compiler compiler) {
    HType receiverType = instruction.getDartReceiver(compiler).instructionType;
    Selector refined = receiverType.refine(instruction.selector, compiler);
    HType type = new HType.inferredTypeForSelector(refined, compiler);
    // TODO(ngeoffray): Because we don't know yet the side effects of
    // a JS call, we sometimes know more in the compiler about the
    // side effects of an element (for example operator% on the int
    // class). We should remove this check once we analyze JS calls.
    if (!instruction.useGvn()) {
      instruction.sideEffects =
          compiler.world.getSideEffectsOfSelector(refined);
    }
    return type;
  }

  HInstruction tryConvertToBuiltin(HInvokeDynamic instruction,
                                   Compiler compiler) {
    return null;
  }

  Operation operation(ConstantSystem constantSystem) => null;

  static InvokeDynamicSpecializer lookupSpecializer(Selector selector) {
    if (selector.kind == SelectorKind.INDEX) {
      return selector.name == '[]'
          ? const IndexSpecializer()
          : const IndexAssignSpecializer();
    } else if (selector.kind == SelectorKind.OPERATOR) {
      if (selector.name == 'unary-') {
        return const UnaryNegateSpecializer();
      } else if (selector.name == '~') {
        return const BitNotSpecializer();
      } else if (selector.name == '+') {
        return const AddSpecializer();
      } else if (selector.name == '-') {
        return const SubtractSpecializer();
      } else if (selector.name == '*') {
        return const MultiplySpecializer();
      } else if (selector.name == '/') {
        return const DivideSpecializer();
      } else if (selector.name == '~/') {
        return const TruncatingDivideSpecializer();
      } else if (selector.name == '%') {
        return const ModuloSpecializer();
      } else if (selector.name == '>>') {
        return const ShiftRightSpecializer();
      } else if (selector.name == '<<') {
        return const ShiftLeftSpecializer();
      } else if (selector.name == '&') {
        return const BitAndSpecializer();
      } else if (selector.name == '|') {
        return const BitOrSpecializer();
      } else if (selector.name == '^') {
        return const BitXorSpecializer();
      } else if (selector.name == '==') {
        return const EqualsSpecializer();
      } else if (selector.name == '<') {
        return const LessSpecializer();
      } else if (selector.name == '<=') {
        return const LessEqualSpecializer();
      } else if (selector.name == '>') {
        return const GreaterSpecializer();
      } else if (selector.name == '>=') {
        return const GreaterEqualSpecializer();
      }
    }
    return const InvokeDynamicSpecializer();
  }
}

class IndexAssignSpecializer extends InvokeDynamicSpecializer {
  const IndexAssignSpecializer();

  HInstruction tryConvertToBuiltin(HInvokeDynamic instruction,
                                   Compiler compiler) {
    if (instruction.inputs[1].isMutableIndexable(compiler)) {
      if (!instruction.inputs[2].isInteger() && compiler.enableTypeAssertions) {
        // We want the right checked mode error.
        return null;
      }
      return new HIndexAssign(instruction.inputs[1],
                              instruction.inputs[2],
                              instruction.inputs[3],
                              instruction.selector);
    }
    return null;
  }
}

class IndexSpecializer extends InvokeDynamicSpecializer {
  const IndexSpecializer();

  HInstruction tryConvertToBuiltin(HInvokeDynamic instruction,
                                   Compiler compiler) {
    if (!instruction.inputs[1].isIndexable(compiler)) return null;
    if (!instruction.inputs[2].isInteger() && compiler.enableTypeAssertions) {
      // We want the right checked mode error.
      return null;
    }
    HInstruction index = new HIndex(
        instruction.inputs[1], instruction.inputs[2], instruction.selector);
    HType receiverType = instruction.getDartReceiver(compiler).instructionType;
    Selector refined = receiverType.refine(instruction.selector, compiler);
    HType type = new HType.inferredTypeForSelector(refined, compiler);
    index.instructionType = type;
    return index;
  }
}

class BitNotSpecializer extends InvokeDynamicSpecializer {
  const BitNotSpecializer();

  UnaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.bitNot;
  }

  HType computeTypeFromInputTypes(HInvokeDynamic instruction,
                                  Compiler compiler) {
    // All bitwise operations on primitive types either produce an
    // integer or throw an error.
    if (instruction.inputs[1].isPrimitiveOrNull(compiler)) return HType.INTEGER;
    return super.computeTypeFromInputTypes(instruction, compiler);
  }

  HInstruction tryConvertToBuiltin(HInvokeDynamic instruction,
                                   Compiler compiler) {
    HInstruction input = instruction.inputs[1];
    if (input.isNumber()) return new HBitNot(input, instruction.selector);
    return null;
  }
}

class UnaryNegateSpecializer extends InvokeDynamicSpecializer {
  const UnaryNegateSpecializer();

  UnaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.negate;
  }

  HType computeTypeFromInputTypes(HInvokeDynamic instruction,
                                  Compiler compiler) {
    HType operandType = instruction.inputs[1].instructionType;
    if (operandType.isNumberOrNull()) return operandType;
    return super.computeTypeFromInputTypes(instruction, compiler);
  }

  HInstruction tryConvertToBuiltin(HInvokeDynamic instruction,
                                   Compiler compiler) {
    HInstruction input = instruction.inputs[1];
    if (input.isNumber()) return new HNegate(input, instruction.selector);
    return null;
  }
}

abstract class BinaryArithmeticSpecializer extends InvokeDynamicSpecializer {
  const BinaryArithmeticSpecializer();

  HType computeTypeFromInputTypes(HInvokeDynamic instruction,
                                  Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isIntegerOrNull() && right.isIntegerOrNull()) return HType.INTEGER;
    if (left.isNumberOrNull()) {
      if (left.isDoubleOrNull() || right.isDoubleOrNull()) return HType.DOUBLE;
      return HType.NUMBER;
    }
    return super.computeTypeFromInputTypes(instruction, compiler);
  }

  bool isBuiltin(HInvokeDynamic instruction) {
    return instruction.inputs[1].isNumber()
        && instruction.inputs[2].isNumber();
  }

  HInstruction tryConvertToBuiltin(HInvokeDynamic instruction,
                                   Compiler compiler) {
    if (isBuiltin(instruction)) {
      HInstruction builtin = newBuiltinVariant(instruction);
      if (builtin != null) return builtin;
      // Even if there is no builtin equivalent instruction, we know
      // the instruction does not have any side effect, and that it
      // can be GVN'ed.
      instruction.sideEffects.clearAllSideEffects();
      instruction.sideEffects.clearAllDependencies();
      instruction.setUseGvn();
    }
    return null;
  }

  HInstruction newBuiltinVariant(HInvokeDynamic instruction);
}

class AddSpecializer extends BinaryArithmeticSpecializer {
  const AddSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.add;
  }

  HInstruction newBuiltinVariant(HInvokeDynamic instruction) {
    return new HAdd(
        instruction.inputs[1], instruction.inputs[2], instruction.selector);
  }
}

class DivideSpecializer extends BinaryArithmeticSpecializer {
  const DivideSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.divide;
  }

  HType computeTypeFromInputTypes(HInstruction instruction,
                                  Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    if (left.isNumberOrNull()) return HType.DOUBLE;
    return super.computeTypeFromInputTypes(instruction, compiler);
  }

  HInstruction newBuiltinVariant(HInvokeDynamic instruction) {
    return new HDivide(
        instruction.inputs[1], instruction.inputs[2], instruction.selector);
  }
}

class ModuloSpecializer extends BinaryArithmeticSpecializer {
  const ModuloSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.modulo;
  }

  HInstruction newBuiltinVariant(HInvokeDynamic instruction) {
    // Modulo cannot be mapped to the native operator (different semantics).
    return null;
  }
}

class MultiplySpecializer extends BinaryArithmeticSpecializer {
  const MultiplySpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.multiply;
  }

  HInstruction newBuiltinVariant(HInvokeDynamic instruction) {
    return new HMultiply(
        instruction.inputs[1], instruction.inputs[2], instruction.selector);
  }
}

class SubtractSpecializer extends BinaryArithmeticSpecializer {
  const SubtractSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.subtract;
  }

  HInstruction newBuiltinVariant(HInvokeDynamic instruction) {
    return new HSubtract(
        instruction.inputs[1], instruction.inputs[2], instruction.selector);
  }
}

class TruncatingDivideSpecializer extends BinaryArithmeticSpecializer {
  const TruncatingDivideSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.truncatingDivide;
  }

  HInstruction newBuiltinVariant(HInvokeDynamic instruction) {
    // Truncating divide does not have a JS equivalent.    
    return null;
  }
}

abstract class BinaryBitOpSpecializer extends BinaryArithmeticSpecializer {
  const BinaryBitOpSpecializer();

  HType computeTypeFromInputTypes(HInvokeDynamic instruction,
                                  Compiler compiler) {
    // All bitwise operations on primitive types either produce an
    // integer or throw an error.
    HInstruction left = instruction.inputs[1];
    if (left.isPrimitiveOrNull(compiler)) return HType.INTEGER;
    return super.computeTypeFromInputTypes(instruction, compiler);
  }
}

class ShiftLeftSpecializer extends BinaryBitOpSpecializer {
  const ShiftLeftSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.shiftLeft;
  }

  HInstruction tryConvertToBuiltin(HInvokeDynamic instruction,
                                   Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (!left.isNumber()) return null;
    if (argumentLessThan32(right)) {
      return newBuiltinVariant(instruction);
    }
    return null;
  }

  HInstruction newBuiltinVariant(HInvokeDynamic instruction) {
    return new HShiftLeft(
        instruction.inputs[1], instruction.inputs[2], instruction.selector);
  }

  bool argumentLessThan32(HInstruction instruction) {
    if (!instruction.isConstantInteger()) return false;
    HConstant rightConstant = instruction;
    IntConstant intConstant = rightConstant.constant;
    int count = intConstant.value;
    return count >= 0 && count <= 31;
  }
}

class ShiftRightSpecializer extends BinaryBitOpSpecializer {
  const ShiftRightSpecializer();

  HInstruction newBuiltinVariant(HInvokeDynamic instruction) {
    // Shift right cannot be mapped to the native operator easily.    
    return null;
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

  HInstruction newBuiltinVariant(HInvokeDynamic instruction) {
    return new HBitOr(
        instruction.inputs[1], instruction.inputs[2], instruction.selector);
  }
}

class BitAndSpecializer extends BinaryBitOpSpecializer {
  const BitAndSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.bitAnd;
  }

  HInstruction newBuiltinVariant(HInvokeDynamic instruction) {
    return new HBitAnd(
        instruction.inputs[1], instruction.inputs[2], instruction.selector);
  }
}

class BitXorSpecializer extends BinaryBitOpSpecializer {
  const BitXorSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.bitXor;
  }

  HInstruction newBuiltinVariant(HInvokeDynamic instruction) {
    return new HBitXor(
        instruction.inputs[1], instruction.inputs[2], instruction.selector);
  }
}

abstract class RelationalSpecializer extends InvokeDynamicSpecializer {
  const RelationalSpecializer();

  HType computeTypeFromInputTypes(HInvokeDynamic instruction,
                                  Compiler compiler) {
    if (instruction.inputs[1].instructionType.isPrimitiveOrNull(compiler)) {
      return HType.BOOLEAN;
    }
    return super.computeTypeFromInputTypes(instruction, compiler);
  }

  HInstruction tryConvertToBuiltin(HInvokeDynamic instruction,
                                   Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isNumber() && right.isNumber()) {
      return newBuiltinVariant(instruction);
    }
    return null;
  }

  HInstruction newBuiltinVariant(HInvokeDynamic instruction);
}

class EqualsSpecializer extends RelationalSpecializer {
  const EqualsSpecializer();

  HInstruction tryConvertToBuiltin(HInvokeDynamic instruction,
                                   Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    HType instructionType = left.instructionType;
    if (right.isConstantNull() || instructionType.isPrimitiveOrNull(compiler)) {
      return newBuiltinVariant(instruction);
    }
    Selector selector = instructionType.refine(instruction.selector, compiler);
    World world = compiler.world;
    JavaScriptBackend backend = compiler.backend;
    Iterable<Element> matches = world.allFunctions.filter(selector);
    // This test relies the on `Object.==` and `Interceptor.==` always being
    // implemented because if the selector matches by subtype, it still will be
    // a regular object or an interceptor.
    if (matches.every(backend.isDefaultEqualityImplementation)) {
      return newBuiltinVariant(instruction);
    }
    return null;
  }

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.equal;
  }

  HInstruction newBuiltinVariant(HInvokeDynamic instruction) {
    return new HIdentity(
        instruction.inputs[1], instruction.inputs[2], instruction.selector);
  }
}

class LessSpecializer extends RelationalSpecializer {
  const LessSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.less;
  }

  HInstruction newBuiltinVariant(HInvokeDynamic instruction) {
    return new HLess(
        instruction.inputs[1], instruction.inputs[2], instruction.selector);
  }
}

class GreaterSpecializer extends RelationalSpecializer {
  const GreaterSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.greater;
  }

  HInstruction newBuiltinVariant(HInvokeDynamic instruction) {
    return new HGreater(
        instruction.inputs[1], instruction.inputs[2], instruction.selector);
  }
}

class GreaterEqualSpecializer extends RelationalSpecializer {
  const GreaterEqualSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.greaterEqual;
  }

  HInstruction newBuiltinVariant(HInvokeDynamic instruction) {
    return new HGreaterEqual(
        instruction.inputs[1], instruction.inputs[2], instruction.selector);
  }
}

class LessEqualSpecializer extends RelationalSpecializer {
  const LessEqualSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.lessEqual;
  }

  HInstruction newBuiltinVariant(HInvokeDynamic instruction) {
    return new HLessEqual(
        instruction.inputs[1], instruction.inputs[2], instruction.selector);
  }
}

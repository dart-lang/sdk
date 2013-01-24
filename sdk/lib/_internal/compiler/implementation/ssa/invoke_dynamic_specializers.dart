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

  HType computeDesiredTypeForInput(HInvokeDynamic instruction,
                                   HInstruction input,
                                   HTypeMap types,
                                   Compiler compiler) {
    return HType.UNKNOWN;
  }

  HType computeTypeFromInputTypes(HInvokeDynamic instruction,
                                  HTypeMap types,
                                  Compiler compiler) {
    return HType.UNKNOWN;
  }

  HInstruction tryConvertToBuiltin(HInvokeDynamic instruction,
                                   HTypeMap types) {
    return null;
  }

  Operation operation(ConstantSystem constantSystem) => null;

  static InvokeDynamicSpecializer lookupSpecializer(Selector selector) {
    if (selector.kind == SelectorKind.INDEX) {
      return selector.name == const SourceString('[]')
          ? const IndexSpecializer()
          : const IndexAssignSpecializer();
    } else if (selector.kind == SelectorKind.OPERATOR) {
      if (selector.name == const SourceString('unary-')) {
        return const UnaryNegateSpecializer();
      } else if (selector.name == const SourceString('~')) {
        return const BitNotSpecializer();
      } else if (selector.name == const SourceString('+')) {
        return const AddSpecializer();
      } else if (selector.name == const SourceString('-')) {
        return const SubtractSpecializer();
      } else if (selector.name == const SourceString('*')) {
        return const MultiplySpecializer();
      } else if (selector.name == const SourceString('/')) {
        return const DivideSpecializer();
      } else if (selector.name == const SourceString('~/')) {
        return const TruncatingDivideSpecializer();
      } else if (selector.name == const SourceString('%')) {
        return const ModuloSpecializer();
      } else if (selector.name == const SourceString('>>')) {
        return const ShiftRightSpecializer();
      } else if (selector.name == const SourceString('<<')) {
        return const ShiftLeftSpecializer();
      } else if (selector.name == const SourceString('&')) {
        return const BitAndSpecializer();
      } else if (selector.name == const SourceString('|')) {
        return const BitOrSpecializer();
      } else if (selector.name == const SourceString('^')) {
        return const BitXorSpecializer();
      } else if (selector.name == const SourceString('==')) {
        return const EqualsSpecializer();
      } else if (selector.name == const SourceString('<')) {
        return const LessSpecializer();
      } else if (selector.name == const SourceString('<=')) {
        return const LessEqualSpecializer();
      } else if (selector.name == const SourceString('>')) {
        return const GreaterSpecializer();
      } else if (selector.name == const SourceString('>=')) {
        return const GreaterEqualSpecializer();
      }
    }
    return const InvokeDynamicSpecializer();
  }
}

class IndexAssignSpecializer extends InvokeDynamicSpecializer {
  const IndexAssignSpecializer();

  HType computeDesiredTypeForInput(HInvokeDynamic instruction,
                                   HInstruction input,
                                   HTypeMap types,
                                   Compiler compiler) {
    HInstruction index = instruction.inputs[2];
    if (input == instruction.inputs[1] &&
        (index.isTypeUnknown(types) || index.isNumber(types))) {
      return HType.MUTABLE_ARRAY;
    }
    // The index should be an int when the receiver is a string or array.
    // However it turns out that inserting an integer check in the optimized
    // version is cheaper than having another bailout case. This is true,
    // because the integer check will simply throw if it fails.
    return HType.UNKNOWN;
  }

  HInstruction tryConvertToBuiltin(HInvokeDynamic instruction,
                                   HTypeMap types) {
    if (instruction.inputs[1].isMutableArray(types)) {
      return new HIndexAssign(instruction.inputs[1],
                              instruction.inputs[2],
                              instruction.inputs[3]);
    }
    return null;
  }
}

class IndexSpecializer extends InvokeDynamicSpecializer {
  const IndexSpecializer();

  HType computeDesiredTypeForInput(HInvokeDynamic instruction,
                                   HInstruction input,
                                   HTypeMap types,
                                   Compiler compiler) {
    HInstruction index = instruction.inputs[2];
    if (input == instruction.inputs[1] &&
        (index.isTypeUnknown(types) || index.isNumber(types))) {
      return HType.INDEXABLE_PRIMITIVE;
    }
    // The index should be an int when the receiver is a string or array.
    // However it turns out that inserting an integer check in the optimized
    // version is cheaper than having another bailout case. This is true,
    // because the integer check will simply throw if it fails.
    return HType.UNKNOWN;
  }

  HInstruction tryConvertToBuiltin(HInvokeDynamic instruction,
                                   HTypeMap types) {
    if (instruction.inputs[1].isIndexablePrimitive(types)) {
      return new HIndex(instruction.inputs[1], instruction.inputs[2]);
    }
    return null;
  }
}

class BitNotSpecializer extends InvokeDynamicSpecializer {
  const BitNotSpecializer();

  UnaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.bitNot;
  }

  HType computeDesiredTypeForInput(HInvokeDynamic instruction,
                                   HInstruction input,
                                   HTypeMap types,
                                   Compiler compiler) {
    if (input == instruction.inputs[1]) {
      HType propagatedType = types[instruction];
      if (propagatedType.isUnknown() || propagatedType.isNumber()) {
        return HType.INTEGER;
      }
    }
    return HType.UNKNOWN;
  }

  HType computeTypeFromInputTypes(HInvokeDynamic instruction,
                                  HTypeMap types,
                                  Compiler compiler) {
    // All bitwise operations on primitive types either produce an
    // integer or throw an error.
    if (instruction.inputs[1].isPrimitive(types)) return HType.INTEGER;
    return HType.UNKNOWN;
  }

  HInstruction tryConvertToBuiltin(HInvokeDynamic instruction,
                                   HTypeMap types) {
    HInstruction input = instruction.inputs[1];
    if (input.isNumber(types)) return new HBitNot(input);
    return null;
  }
}

class UnaryNegateSpecializer extends InvokeDynamicSpecializer {
  const UnaryNegateSpecializer();

  UnaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.negate;
  }

  HType computeDesiredTypeForInput(HInvokeDynamic instruction,
                                   HInstruction input,
                                   HTypeMap types,
                                   Compiler compiler) {
    if (input == instruction.inputs[1]) {
      HType propagatedType = types[instruction];
      // If the outgoing type should be a number (integer, double or both) we
      // want the outgoing type to be the input too.
      // If we don't know the outgoing type we try to make it a number.
      if (propagatedType.isNumber()) return propagatedType;
      if (propagatedType.isUnknown()) return HType.NUMBER;
    }
    return HType.UNKNOWN;
  }

  HType computeTypeFromInputTypes(HInvokeDynamic instruction,
                                  HTypeMap types,
                                  Compiler compiler) {
    HType operandType = types[instruction.inputs[1]];
    if (operandType.isNumber()) return operandType;
    return HType.UNKNOWN;
  }

  HInstruction tryConvertToBuiltin(HInvokeDynamic instruction,
                                   HTypeMap types) {
    HInstruction input = instruction.inputs[1];
    if (input.isNumber(types)) return new HNegate(input);
    return null;
  }
}

abstract class BinaryArithmeticSpecializer extends InvokeDynamicSpecializer {
  const BinaryArithmeticSpecializer();

  HType computeTypeFromInputTypes(HInvokeDynamic instruction,
                                  HTypeMap types,
                                  Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isInteger(types) && right.isInteger(types)) return HType.INTEGER;
    if (left.isNumber(types)) {
      if (left.isDouble(types) || right.isDouble(types)) return HType.DOUBLE;
      return HType.NUMBER;
    }
    return HType.UNKNOWN;
  }

  HType computeDesiredTypeForInput(HInvokeDynamic instruction,
                                   HInstruction input,
                                   HTypeMap types,
                                   Compiler compiler) {
    if (input == instruction.inputs[0]) return HType.UNKNOWN;

    HType propagatedType = types[instruction];
    // If the desired output type should be an integer we want to get two
    // integers as arguments.
    if (propagatedType.isInteger()) return HType.INTEGER;
    // If the outgoing type should be a number we can get that if both inputs
    // are numbers. If we don't know the outgoing type we try to make it a
    // number.
    if (propagatedType.isUnknown() || propagatedType.isNumber()) {
      return HType.NUMBER;
    }
    // Even if the desired outgoing type is not a number we still want the
    // second argument to be a number if the first one is a number. This will
    // not help for the outgoing type, but at least the binary arithmetic
    // operation will not have type problems.
    // TODO(floitsch): normally we shouldn't request a number, but simply
    // throw an ArgumentError if it isn't. This would be similar
    // to the array case.
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (input == right && left.isNumber(types)) return HType.NUMBER;
    return HType.UNKNOWN;
  }

  bool isBuiltin(HInvokeDynamic instruction, HTypeMap types) {
    return instruction.inputs[1].isNumber(types)
        && instruction.inputs[2].isNumber(types);
  }

  HInstruction tryConvertToBuiltin(HInvokeDynamic instruction,
                                   HTypeMap types) {
    if (isBuiltin(instruction, types)) {
      HInstruction builtin =
          newBuiltinVariant(instruction.inputs[1], instruction.inputs[2]);
      if (builtin != null) return builtin;
      // Even if there is no builtin equivalent instruction, we know
      // the instruction does not have any side effect, and that it
      // can be GVN'ed.
      instruction.clearAllSideEffects();
      instruction.clearAllDependencies();
      instruction.setUseGvn();
    }
    return null;
  }

  HInstruction newBuiltinVariant(HInstruction left, HInstruction right);
}

class AddSpecializer extends BinaryArithmeticSpecializer {
  const AddSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.add;
  }

  HInstruction newBuiltinVariant(HInstruction left, HInstruction right) {
    return new HAdd(left, right);
  }
}

class DivideSpecializer extends BinaryArithmeticSpecializer {
  const DivideSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.divide;
  }

  HType computeTypeFromInputTypes(HInstruction instruction,
                                  HTypeMap types,
                                  Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    if (left.isNumber(types)) return HType.DOUBLE;
    return HType.UNKNOWN;
  }

  HType computeDesiredTypeForInput(HInstruction instruction,
                                   HInstruction input,
                                   HTypeMap types,
                                   Compiler compiler) {
    if (input == instruction.inputs[0]) return HType.UNKNOWN;
    // A division can never return an integer. So don't ask for integer inputs.
    if (instruction.isInteger(types)) return HType.UNKNOWN;
    return super.computeDesiredTypeForInput(
        instruction, input, types, compiler);
  }

  HInstruction newBuiltinVariant(HInstruction left, HInstruction right) {
    return new HDivide(left, right);
  }
}

class ModuloSpecializer extends BinaryArithmeticSpecializer {
  const ModuloSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.modulo;
  }

  HInstruction newBuiltinVariant(HInstruction left, HInstruction right) {
    // Modulo cannot be mapped to the native operator (different semantics).    
    return null;
  }
}

class MultiplySpecializer extends BinaryArithmeticSpecializer {
  const MultiplySpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.multiply;
  }

  HInstruction newBuiltinVariant(HInstruction left, HInstruction right) {
    return new HMultiply(left, right);
  }
}

class SubtractSpecializer extends BinaryArithmeticSpecializer {
  const SubtractSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.subtract;
  }

  HInstruction newBuiltinVariant(HInstruction left, HInstruction right) {
    return new HSubtract(left, right);
  }
}

class TruncatingDivideSpecializer extends BinaryArithmeticSpecializer {
  const TruncatingDivideSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.truncatingDivide;
  }

  HInstruction newBuiltinVariant(HInstruction left, HInstruction right) {
    // Truncating divide does not have a JS equivalent.    
    return null;
  }
}

abstract class BinaryBitOpSpecializer extends BinaryArithmeticSpecializer {
  const BinaryBitOpSpecializer();

  HType computeTypeFromInputTypes(HInvokeDynamic instruction,
                                  HTypeMap types,
                                  Compiler compiler) {
    // All bitwise operations on primitive types either produce an
    // integer or throw an error.
    HInstruction left = instruction.inputs[1];
    if (left.isPrimitive(types)) return HType.INTEGER;
    return HType.UNKNOWN;
  }

  HType computeDesiredTypeForInput(HInvokeDynamic instruction,
                                   HInstruction input,
                                   HTypeMap types,
                                   Compiler compiler) {
    if (input == instruction.inputs[0]) return HType.UNKNOWN;
    HType propagatedType = types[instruction];
    // If the outgoing type should be a number we can get that only if both
    // inputs are integers. If we don't know the outgoing type we try to make
    // it an integer.
    if (propagatedType.isUnknown() || propagatedType.isNumber()) {
      return HType.INTEGER;
    }
    return HType.UNKNOWN;
  }
}

class ShiftLeftSpecializer extends BinaryBitOpSpecializer {
  const ShiftLeftSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.shiftLeft;
  }

  HInstruction tryConvertToBuiltin(HInvokeDynamic instruction,
                                   HTypeMap types) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (!left.isNumber(types) || !right.isConstantInteger()) return null;
    HConstant rightConstant = right;
    IntConstant intConstant = rightConstant.constant;
    int count = intConstant.value;
    if (count >= 0 && count <= 31) {
      return newBuiltinVariant(left, right);
    }
    return null;
  }

  HInstruction newBuiltinVariant(HInstruction left, HInstruction right) {
    return new HShiftLeft(left, right);
  }
}

class ShiftRightSpecializer extends BinaryBitOpSpecializer {
  const ShiftRightSpecializer();

  HInstruction newBuiltinVariant(HInstruction left, HInstruction right) {
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

  HInstruction newBuiltinVariant(HInstruction left, HInstruction right) {
    return new HBitOr(left, right);
  }
}

class BitAndSpecializer extends BinaryBitOpSpecializer {
  const BitAndSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.bitAnd;
  }

  HInstruction newBuiltinVariant(HInstruction left, HInstruction right) {
    return new HBitAnd(left, right);
  }
}

class BitXorSpecializer extends BinaryBitOpSpecializer {
  const BitXorSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.bitXor;
  }

  HInstruction newBuiltinVariant(HInstruction left, HInstruction right) {
    return new HBitXor(left, right);
  }
}

abstract class RelationalSpecializer extends InvokeDynamicSpecializer {
  const RelationalSpecializer();

  HType computeTypeFromInputTypes(HInvokeDynamic instruction,
                                  HTypeMap types,
                                  Compiler compiler) {
    if (types[instruction.inputs[1]].isPrimitiveOrNull()) return HType.BOOLEAN;
    return HType.UNKNOWN;
  }

  HType computeDesiredTypeForInput(HInvokeDynamic instruction,
                                   HInstruction input,
                                   HTypeMap types,
                                   Compiler compiler) {
    if (input == instruction.inputs[0]) return HType.UNKNOWN;
    HType propagatedType = types[instruction];
    // For all relational operations except HIdentity, we expect to get numbers
    // only. With numbers the outgoing type is a boolean. If something else
    // is desired, then numbers are incorrect, though.
    if (propagatedType.isUnknown() || propagatedType.isBoolean()) {
      HInstruction left = instruction.inputs[1];
      if (left.isTypeUnknown(types) || left.isNumber(types)) {
        return HType.NUMBER;
      }
    }
    return HType.UNKNOWN;
  }

  HInstruction tryConvertToBuiltin(HInvokeDynamic instruction,
                                   HTypeMap types) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (left.isNumber(types) && right.isNumber(types)) {
      return newBuiltinVariant(left, right);
    }
    return null;
  }

  HInstruction newBuiltinVariant(HInstruction left, HInstruction right);
}

class EqualsSpecializer extends RelationalSpecializer {
  const EqualsSpecializer();

  HType computeDesiredTypeForInput(HInvokeDynamic instruction,
                                   HInstruction input,
                                   HTypeMap types,
                                   Compiler compiler) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    HType propagatedType = types[instruction];
    if (input == left && types[right].isUseful()) {
      // All our useful types have 'identical' semantics. But we don't want to
      // speculatively test for all possible types. Therefore we try to match
      // the two types. That is, if we see x == 3, then we speculatively test
      // if x is a number and bailout if it isn't.
      // If right is a number we don't need more than a number (no need to match
      // the exact type of right).
      if (right.isNumber(types)) return HType.NUMBER;
      return types[right];
    }
    // String equality testing is much more common than array equality testing.
    if (input == left && left.isIndexablePrimitive(types)) {
      return HType.READABLE_ARRAY;
    }
    // String equality testing is much more common than array equality testing.
    if (input == right && right.isIndexablePrimitive(types)) {
      return HType.STRING;
    }
    return HType.UNKNOWN;
  }

  HInstruction tryConvertToBuiltin(HInvokeDynamic instruction,
                                   HTypeMap types) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];
    if (types[left].isPrimitiveOrNull() || right.isConstantNull()) {
      return newBuiltinVariant(left, right);
    }
    return null;
  }

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.equal;
  }

  HInstruction newBuiltinVariant(HInstruction left, HInstruction right) {
    return new HIdentity(left, right);
  }
}

class LessSpecializer extends RelationalSpecializer {
  const LessSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.less;
  }

  HInstruction newBuiltinVariant(HInstruction left, HInstruction right) {
    return new HLess(left, right);
  }
}

class GreaterSpecializer extends RelationalSpecializer {
  const GreaterSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.greater;
  }

  HInstruction newBuiltinVariant(HInstruction left, HInstruction right) {
    return new HGreater(left, right);
  }
}

class GreaterEqualSpecializer extends RelationalSpecializer {
  const GreaterEqualSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.greaterEqual;
  }

  HInstruction newBuiltinVariant(HInstruction left, HInstruction right) {
    return new HGreaterEqual(left, right);
  }
}

class LessEqualSpecializer extends RelationalSpecializer {
  const LessEqualSpecializer();

  BinaryOperation operation(ConstantSystem constantSystem) {
    return constantSystem.lessEqual;
  }

  HInstruction newBuiltinVariant(HInstruction left, HInstruction right) {
    return new HLessEqual(left, right);
  }
}

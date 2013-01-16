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

  HType computeDesiredTypeForInput(HInvokeDynamicMethod instruction,
                                   HInstruction input,
                                   HTypeMap types,
                                   Compiler compiler) {
    return HType.UNKNOWN;
  }

  HType computeTypeFromInputTypes(HInvokeDynamicMethod instruction,
                                  HTypeMap types,
                                  Compiler compiler) {
    return HType.UNKNOWN;
  }

  HInstruction tryConvertToBuiltin(HInvokeDynamicMethod instruction,
                                   HTypeMap types) {
    return null;
  }

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
      }
    }
    return const InvokeDynamicSpecializer();
  }
}

class IndexAssignSpecializer extends InvokeDynamicSpecializer {
  const IndexAssignSpecializer();

  HType computeDesiredTypeForInput(HInvokeDynamicMethod instruction,
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

  HInstruction tryConvertToBuiltin(HInvokeDynamicMethod instruction,
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

  HType computeDesiredTypeForInput(HInvokeDynamicMethod instruction,
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

  HInstruction tryConvertToBuiltin(HInvokeDynamicMethod instruction,
                                   HTypeMap types) {
    if (instruction.inputs[1].isIndexablePrimitive(types)) {
      return new HIndex(instruction.inputs[1], instruction.inputs[2]);
    }
    return null;
  }
}

class BitNotSpecializer extends InvokeDynamicSpecializer {
  const BitNotSpecializer();

  HType computeDesiredTypeForInput(HInvokeDynamicMethod instruction,
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

  HType computeTypeFromInputTypes(HInvokeDynamicMethod instruction,
                                  HTypeMap types,
                                  Compiler compiler) {
    // All bitwise operations on primitive types either produce an
    // integer or throw an error.
    if (instruction.inputs[1].isPrimitive(types)) return HType.INTEGER;
    return HType.UNKNOWN;
  }

  HInstruction tryConvertToBuiltin(HInvokeDynamicMethod instruction,
                                   HTypeMap types) {
    HInstruction input = instruction.inputs[1];
    if (input.isNumber(types)) return new HBitNot(input);
    return null;
  }
}

class UnaryNegateSpecializer extends InvokeDynamicSpecializer {
  const UnaryNegateSpecializer();

  HType computeDesiredTypeForInput(HInvokeDynamicMethod instruction,
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

  HType computeTypeFromInputTypes(HInvokeDynamicMethod instruction,
                                  HTypeMap types,
                                  Compiler compiler) {
    HType operandType = types[instruction.inputs[1]];
    if (operandType.isNumber()) return operandType;
    return HType.UNKNOWN;
  }

  HInstruction tryConvertToBuiltin(HInvokeDynamicMethod instruction,
                                   HTypeMap types) {
    HInstruction input = instruction.inputs[1];
    if (input.isNumber(types)) return new HNegate(input);
    return null;
  }
}

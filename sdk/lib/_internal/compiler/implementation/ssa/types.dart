// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

abstract class HType {
  const HType();

  /**
   * Returns an [HType] that represents [type] and all types that have
   * [type] as supertype.
   */
  factory HType.fromBoundedType(DartType type,
                                Compiler compiler,
                                [bool canBeNull = false]) {
    Element element = type.element;
    if (identical(element.kind, ElementKind.TYPE_VARIABLE)) {
      // TODO(ngeoffray): Replace object type with [type].
      return new HBoundedPotentialPrimitiveType(
          compiler.objectClass.computeType(compiler), canBeNull);
    }

    if (identical(element, compiler.intClass)) {
      return canBeNull ? HType.INTEGER_OR_NULL : HType.INTEGER;
    } else if (identical(element, compiler.numClass)) {
      return canBeNull ? HType.NUMBER_OR_NULL : HType.NUMBER;
    } else if (identical(element, compiler.doubleClass)) {
      return canBeNull ? HType.DOUBLE_OR_NULL : HType.DOUBLE;
    } else if (identical(element, compiler.stringClass)) {
      return canBeNull ? HType.STRING_OR_NULL : HType.STRING;
    } else if (identical(element, compiler.boolClass)) {
      return canBeNull ? HType.BOOLEAN_OR_NULL : HType.BOOLEAN;
    } else if (identical(element, compiler.listClass)
        || Elements.isListSupertype(element, compiler)) {
      return new HBoundedPotentialPrimitiveArray(type, canBeNull);
    } else if (Elements.isNumberOrStringSupertype(element, compiler)) {
      return new HBoundedPotentialPrimitiveNumberOrString(type, canBeNull);
    } else if (Elements.isStringOnlySupertype(element, compiler)) {
      return new HBoundedPotentialPrimitiveString(type, canBeNull);
    } else {
      return canBeNull ? new HBoundedType.withNull(type)
                       : new HBoundedType.nonNull(type);
    }
  }

  static const HType CONFLICTING = const HConflictingType();
  static const HType UNKNOWN = const HUnknownType();
  static const HType BOOLEAN = const HBooleanType();
  static const HType NUMBER = const HNumberType();
  static const HType INTEGER = const HIntegerType();
  static const HType DOUBLE = const HDoubleType();
  static const HType INDEXABLE_PRIMITIVE = const HIndexablePrimitiveType();
  static const HType STRING = const HStringType();
  static const HType READABLE_ARRAY = const HReadableArrayType();
  static const HType MUTABLE_ARRAY = const HMutableArrayType();
  static const HType FIXED_ARRAY = const HFixedArrayType();
  static const HType EXTENDABLE_ARRAY = const HExtendableArrayType();
  static const HType NULL = const HNullType();

  static const HType BOOLEAN_OR_NULL = const HBooleanOrNullType();
  static const HType NUMBER_OR_NULL = const HNumberOrNullType();
  static const HType INTEGER_OR_NULL = const HIntegerOrNullType();
  static const HType DOUBLE_OR_NULL = const HDoubleOrNullType();
  static const HType STRING_OR_NULL = const HStringOrNullType();

  bool isConflicting() => identical(this, CONFLICTING);
  bool isUnknown() => identical(this, UNKNOWN);
  bool isNull() => false;
  bool isBoolean() => false;
  bool isNumber() => false;
  bool isInteger() => false;
  bool isDouble() => false;
  bool isString() => false;
  bool isBooleanOrNull() => false;
  bool isNumberOrNull() => false;
  bool isIntegerOrNull() => false;
  bool isDoubleOrNull() => false;
  bool isStringOrNull() => false;
  bool isIndexablePrimitive() => false;
  bool isFixedArray() => false;
  bool isReadableArray() => false;
  bool isMutableArray() => false;
  bool isExtendableArray() => false;
  bool isPrimitive() => false;
  bool isExact() => false;
  bool isPrimitiveOrNull() => false;

  bool canBePrimitive() => false;
  bool canBeNull() => false;

  /** A type is useful it is not unknown, not conflicting, and not null. */
  bool isUseful() => !isUnknown() && !isConflicting() && !isNull();
  /** Alias for isReadableArray. */
  bool isArray() => isReadableArray();

  abstract DartType computeType(Compiler compiler);

  /**
   * The intersection of two types is the intersection of its values. For
   * example:
   *   * INTEGER.intersect(NUMBER) => INTEGER.
   *   * DOUBLE.intersect(INTEGER) => CONFLICTING.
   *   * MUTABLE_ARRAY.intersect(READABLE_ARRAY) => MUTABLE_ARRAY.
   *
   * When there is no predefined type to represent the intersection returns
   * [CONFLICTING].
   *
   * An intersection with [UNKNOWN] returns the non-UNKNOWN type. An
   * intersection with [CONFLICTING] returns [CONFLICTING].
   */
  abstract HType intersection(HType other, Compiler compiler);

  /**
   * The union of two types is the union of its values. For example:
   *   * INTEGER.union(NUMBER) => NUMBER.
   *   * DOUBLE.union(INTEGER) => NUMBER.
   *   * MUTABLE_ARRAY.union(READABLE_ARRAY) => READABLE_ARRAY.
   *
   * When there is no predefined type to represent the union returns
   * [UNKNOWN].
   *
   * A union with [UNKNOWN] returns [UNKNOWN].
   * A union of [CONFLICTING] with any other types returns the other type.
   */
  abstract HType union(HType other, Compiler compiler);
}

/** Used to represent [HType.UNKNOWN] and [HType.CONFLICTING]. */
abstract class HAnalysisType extends HType {
  final String name;
  const HAnalysisType(this.name);
  String toString() => name;

  DartType computeType(Compiler compiler) => null;
}

class HUnknownType extends HAnalysisType {
  const HUnknownType() : super("unknown");
  bool canBePrimitive() => true;
  bool canBeNull() => true;

  HType union(HType other, Compiler compiler) => this;
  HType intersection(HType other, Compiler compiler) => other;
}

class HConflictingType extends HAnalysisType {
  const HConflictingType() : super("conflicting");
  bool canBePrimitive() => true;
  bool canBeNull() => true;

  HType union(HType other, Compiler compiler) => other;
  HType intersection(HType other, Compiler compiler) => this;
}

abstract class HPrimitiveType extends HType {
  const HPrimitiveType();
  bool isPrimitive() => true;
  bool canBePrimitive() => true;
  bool isPrimitiveOrNull() => true;
}

class HNullType extends HPrimitiveType {
  const HNullType();
  bool canBeNull() => true;
  bool isNull() => true;
  String toString() => 'null';

  DartType computeType(Compiler compiler) => null;

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.NULL;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isString()) return HType.STRING_OR_NULL;
    if (other.isInteger()) return HType.INTEGER_OR_NULL;
    if (other.isDouble()) return HType.DOUBLE_OR_NULL;
    if (other.isNumber()) return HType.NUMBER_OR_NULL;
    if (other.isBoolean()) return HType.BOOLEAN_OR_NULL;
    if (!other.canBeNull()) return HType.UNKNOWN;
    return other;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isUnknown()) return HType.NULL;
    if (other.isConflicting()) return HType.CONFLICTING;
    if (!other.canBeNull()) return HType.CONFLICTING;
    return HType.NULL;
  }
}

abstract class HPrimitiveOrNullType extends HType {
  const HPrimitiveOrNullType();
  bool canBePrimitive() => true;
  bool canBeNull() => true;
  bool isPrimitiveOrNull() => true;
}

class HBooleanOrNullType extends HPrimitiveOrNullType {
  const HBooleanOrNullType();
  String toString() => "boolean or null";
  bool isBooleanOrNull() => true;

  DartType computeType(Compiler compiler) {
    return compiler.boolClass.computeType(compiler);
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.BOOLEAN_OR_NULL;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isBooleanOrNull()) return HType.BOOLEAN_OR_NULL;
    if (other.isBoolean()) return HType.BOOLEAN_OR_NULL;
    if (other.isNull()) return HType.BOOLEAN_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.BOOLEAN_OR_NULL;
    if (other.isBoolean()) return HType.BOOLEAN;
    if (other.isBooleanOrNull()) return HType.BOOLEAN_OR_NULL;
    if (other.canBeNull()) return HType.NULL;
    return HType.CONFLICTING;
  }
}

class HBooleanType extends HPrimitiveType {
  const HBooleanType();
  bool isBoolean() => true;
  bool isBooleanOrNull() => true;
  String toString() => "boolean";

  DartType computeType(Compiler compiler) {
    return compiler.boolClass.computeType(compiler);
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.BOOLEAN;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isBoolean()) return HType.BOOLEAN;
    if (other.isBooleanOrNull()) return HType.BOOLEAN_OR_NULL;
    if (other.isNull()) return HType.BOOLEAN_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.BOOLEAN;
    if (other.isBooleanOrNull()) return HType.BOOLEAN;
    if (other.isBoolean()) return HType.BOOLEAN;
    return HType.CONFLICTING;
  }
}

class HNumberOrNullType extends HPrimitiveOrNullType {
  const HNumberOrNullType();
  bool isNumberOrNull() => true;
  String toString() => "number or null";

  DartType computeType(Compiler compiler) {
    return compiler.numClass.computeType(compiler);
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.NUMBER_OR_NULL;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    if (other.isNumber()) return HType.NUMBER_OR_NULL;
    if (other.isNull()) return HType.NUMBER_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.NUMBER_OR_NULL;
    if (other.isInteger()) return HType.INTEGER;
    if (other.isDouble()) return HType.DOUBLE;
    if (other.isNumber()) return HType.NUMBER;
    if (other.isIntegerOrNull()) return HType.INTEGER_OR_NULL;
    if (other.isDoubleOrNull()) return HType.DOUBLE_OR_NULL;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    if (other.canBeNull()) return HType.NULL;
    return HType.CONFLICTING;
  }
}

class HNumberType extends HPrimitiveType {
  const HNumberType();
  bool isNumber() => true;
  bool isNumberOrNull() => true;
  String toString() => "number";

  DartType computeType(Compiler compiler) {
    return compiler.numClass.computeType(compiler);
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.NUMBER;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isNumber()) return HType.NUMBER;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    if (other.isNull()) return HType.NUMBER_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.NUMBER;
    if (other.isNumber()) return other;
    if (other.isIntegerOrNull()) return HType.INTEGER;
    if (other.isDoubleOrNull()) return HType.DOUBLE;
    if (other.isNumberOrNull()) return HType.NUMBER;
    return HType.CONFLICTING;
  }
}

class HIntegerOrNullType extends HNumberOrNullType {
  const HIntegerOrNullType();
  bool isIntegerOrNull() => true;
  String toString() => "integer or null";

  DartType computeType(Compiler compiler) {
    return compiler.intClass.computeType(compiler);
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.INTEGER_OR_NULL;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isIntegerOrNull()) return HType.INTEGER_OR_NULL;
    if (other.isInteger()) return HType.INTEGER_OR_NULL;
    if (other.isNumber()) return HType.NUMBER_OR_NULL;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    if (other.isNull()) return HType.INTEGER_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.INTEGER_OR_NULL;
    if (other.isInteger()) return HType.INTEGER;
    if (other.isIntegerOrNull()) return HType.INTEGER_OR_NULL;
    if (other.isDouble()) return HType.CONFLICTING;
    if (other.isDoubleOrNull()) return HType.NULL;
    if (other.isNumber()) return HType.INTEGER;
    if (other.isNumberOrNull()) return HType.INTEGER_OR_NULL;
    if (other.canBeNull()) return HType.NULL;
    return HType.CONFLICTING;
  }
}

class HIntegerType extends HNumberType {
  const HIntegerType();
  bool isInteger() => true;
  bool isIntegerOrNull() => true;
  String toString() => "integer";

  DartType computeType(Compiler compiler) {
    return compiler.intClass.computeType(compiler);
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.INTEGER;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isInteger()) return HType.INTEGER;
    if (other.isIntegerOrNull()) return HType.INTEGER_OR_NULL;
    if (other.isNumber()) return HType.NUMBER;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    if (other.isNull()) return HType.INTEGER_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.INTEGER;
    if (other.isIntegerOrNull()) return HType.INTEGER;
    if (other.isInteger()) return HType.INTEGER;
    if (other.isDouble()) return HType.CONFLICTING;
    if (other.isDoubleOrNull()) return HType.CONFLICTING;
    if (other.isNumber()) return HType.INTEGER;
    if (other.isNumberOrNull()) return HType.INTEGER;
    return HType.CONFLICTING;
  }
}

class HDoubleOrNullType extends HNumberOrNullType {
  const HDoubleOrNullType();
  bool isDoubleOrNull() => true;
  String toString() => "double or null";

  DartType computeType(Compiler compiler) {
    return compiler.doubleClass.computeType(compiler);
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.DOUBLE_OR_NULL;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isDoubleOrNull()) return HType.DOUBLE_OR_NULL;
    if (other.isDouble()) return HType.DOUBLE_OR_NULL;
    if (other.isNumber()) return HType.NUMBER_OR_NULL;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    if (other.isNull()) return HType.DOUBLE_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.DOUBLE_OR_NULL;
    if (other.isInteger()) return HType.CONFLICTING;
    if (other.isIntegerOrNull()) return HType.NULL;
    if (other.isDouble()) return HType.DOUBLE;
    if (other.isDoubleOrNull()) return HType.DOUBLE_OR_NULL;
    if (other.isNumber()) return HType.DOUBLE;
    if (other.isNumberOrNull()) return HType.DOUBLE_OR_NULL;
    if (other.canBeNull()) return HType.NULL;
    return HType.CONFLICTING;
  }
}

class HDoubleType extends HNumberType {
  const HDoubleType();
  bool isDouble() => true;
  bool isDoubleOrNull() => true;
  String toString() => "double";

  DartType computeType(Compiler compiler) {
    return compiler.doubleClass.computeType(compiler);
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.DOUBLE;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isDouble()) return HType.DOUBLE;
    if (other.isDoubleOrNull()) return HType.DOUBLE_OR_NULL;
    if (other.isNumber()) return HType.NUMBER;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    if (other.isNull()) return HType.DOUBLE_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.DOUBLE;
    if (other.isIntegerOrNull()) return HType.CONFLICTING;
    if (other.isInteger()) return HType.CONFLICTING;
    if (other.isDouble()) return HType.DOUBLE;
    if (other.isDoubleOrNull()) return HType.DOUBLE;
    if (other.isNumber()) return HType.DOUBLE;
    if (other.isNumberOrNull()) return HType.DOUBLE;
    return HType.CONFLICTING;
  }
}

class HIndexablePrimitiveType extends HPrimitiveType {
  const HIndexablePrimitiveType();
  bool isIndexablePrimitive() => true;
  String toString() => "indexable";

  DartType computeType(Compiler compiler) {
    // TODO(ngeoffray): Represent union types.
    return null;
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.INDEXABLE_PRIMITIVE;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    if (other is HBoundedPotentialPrimitiveString) {
      // TODO(ngeoffray): Represent union types.
      return HType.UNKNOWN;
    }
    if (other is HBoundedPotentialPrimitiveArray) {
      // TODO(ngeoffray): Represent union types.
      return HType.UNKNOWN;
    }
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.INDEXABLE_PRIMITIVE;
    if (other.isIndexablePrimitive()) return other;
    if (other is HBoundedPotentialPrimitiveString) return HType.STRING;
    if (other is HBoundedPotentialPrimitiveArray) return HType.READABLE_ARRAY;
    return HType.CONFLICTING;
  }
}

class HStringOrNullType extends HPrimitiveOrNullType {
  const HStringOrNullType();
  bool isStringOrNull() => true;
  String toString() => "String or null";

  DartType computeType(Compiler compiler) {
    return compiler.stringClass.computeType(compiler);
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.STRING_OR_NULL;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isString()) return HType.STRING_OR_NULL;
    if (other.isStringOrNull()) return HType.STRING_OR_NULL;
    if (other.isIndexablePrimitive()) {
      // We don't have a type that represents the nullable indexable
      // primitive.
      return HType.UNKNOWN;
    }
    if (other is HBoundedPotentialPrimitiveString) {
      if (other.canBeNull()) {
        return other;
      } else {
        HBoundedType boundedType = other;
        return new HBoundedPotentialPrimitiveString(boundedType.type, true);
      }
    }
    if (other.isNull()) return HType.STRING_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.STRING_OR_NULL;
    if (other.isString()) return HType.STRING;
    if (other.isStringOrNull()) return HType.STRING_OR_NULL;
    if (other.isArray()) return HType.CONFLICTING;
    if (other.isIndexablePrimitive()) return HType.STRING;
    if (other is HBoundedPotentialPrimitiveString) {
      return other.canBeNull() ? HType.STRING_OR_NULL : HType.STRING;
    }
    if (other.canBeNull()) return HType.NULL;
    return HType.CONFLICTING;
  }
}

class HStringType extends HIndexablePrimitiveType {
  const HStringType();
  bool isString() => true;
  bool isStringOrNull() => true;
  String toString() => "String";

  DartType computeType(Compiler compiler) {
    return compiler.stringClass.computeType(compiler);
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.STRING;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isString()) return HType.STRING;
    if (other.isStringOrNull()) return HType.STRING_OR_NULL;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    if (other is HBoundedPotentialPrimitiveString) return other;
    if (other.isNull()) return HType.STRING_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.STRING;
    if (other.isString()) return HType.STRING;
    if (other.isArray()) return HType.CONFLICTING;
    if (other.isIndexablePrimitive()) return HType.STRING;
    if (other.isStringOrNull()) return HType.STRING;
    if (other is HBoundedPotentialPrimitiveString) return HType.STRING;
    return HType.CONFLICTING;
  }
}

class HReadableArrayType extends HIndexablePrimitiveType {
  const HReadableArrayType();
  bool isReadableArray() => true;
  String toString() => "readable array";

  DartType computeType(Compiler compiler) {
    return compiler.listClass.computeType(compiler);
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.READABLE_ARRAY;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isReadableArray()) return HType.READABLE_ARRAY;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    if (other is HBoundedPotentialPrimitiveArray) return other;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.READABLE_ARRAY;
    if (other.isString()) return HType.CONFLICTING;
    if (other.isReadableArray()) return other;
    if (other.isIndexablePrimitive()) return HType.READABLE_ARRAY;
    if (other is HBoundedPotentialPrimitiveArray) return HType.READABLE_ARRAY;
    return HType.CONFLICTING;
  }
}

class HMutableArrayType extends HReadableArrayType {
  const HMutableArrayType();
  bool isMutableArray() => true;
  String toString() => "mutable array";

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.MUTABLE_ARRAY;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isMutableArray()) return HType.MUTABLE_ARRAY;
    if (other.isReadableArray()) return HType.READABLE_ARRAY;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    if (other is HBoundedPotentialPrimitiveArray) return other;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.MUTABLE_ARRAY;
    if (other.isMutableArray()) return other;
    if (other.isString()) return HType.CONFLICTING;
    if (other.isIndexablePrimitive()) return HType.MUTABLE_ARRAY;
    if (other is HBoundedPotentialPrimitiveArray) return HType.MUTABLE_ARRAY;
    return HType.CONFLICTING;
  }
}

class HFixedArrayType extends HMutableArrayType {
  const HFixedArrayType();
  bool isFixedArray() => true;
  String toString() => "fixed array";

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.FIXED_ARRAY;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isFixedArray()) return HType.FIXED_ARRAY;
    if (other.isMutableArray()) return HType.MUTABLE_ARRAY;
    if (other.isReadableArray()) return HType.READABLE_ARRAY;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    if (other is HBoundedPotentialPrimitiveArray) return other;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.FIXED_ARRAY;
    if (other.isFixedArray()) return HType.FIXED_ARRAY;
    if (other.isExtendableArray()) return HType.CONFLICTING;
    if (other.isString()) return HType.CONFLICTING;
    if (other.isIndexablePrimitive()) return HType.FIXED_ARRAY;
    if (other is HBoundedPotentialPrimitiveArray) return HType.FIXED_ARRAY;
    return HType.CONFLICTING;
  }
}

class HExtendableArrayType extends HMutableArrayType {
  const HExtendableArrayType();
  bool isExtendableArray() => true;
  String toString() => "extendable array";

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.EXTENDABLE_ARRAY;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isExtendableArray()) return HType.EXTENDABLE_ARRAY;
    if (other.isMutableArray()) return HType.MUTABLE_ARRAY;
    if (other.isReadableArray()) return HType.READABLE_ARRAY;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    if (other is HBoundedPotentialPrimitiveArray) return other;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.EXTENDABLE_ARRAY;
    if (other.isExtendableArray()) return HType.EXTENDABLE_ARRAY;
    if (other.isString()) return HType.CONFLICTING;
    if (other.isFixedArray()) return HType.CONFLICTING;
    if (other.isIndexablePrimitive()) return HType.EXTENDABLE_ARRAY;
    if (other is HBoundedPotentialPrimitiveArray) return HType.EXTENDABLE_ARRAY;
    return HType.CONFLICTING;
  }
}

class HBoundedType extends HType {
  final DartType type;
  final bool _canBeNull;
  final bool _isExact;

  toString() {
    return 'BoundedType($type, $_canBeNull, $_isExact)';
  }

  bool canBeNull() => _canBeNull;

  bool isExact() => _isExact;

  const HBoundedType(DartType this.type,
                     [bool canBeNull = false, isExact = false])
      : _canBeNull = canBeNull, _isExact = isExact;
  const HBoundedType.exact(DartType type) : this(type, false, true);
  const HBoundedType.withNull(DartType type) : this(type, true, false);
  const HBoundedType.nonNull(DartType type) : this(type);

  DartType computeType(Compiler compiler) => type;

  Element lookupMember(SourceString name) {
    if (!isExact()) return null;
    ClassElement classElement = type.element;
    return classElement.lookupMember(name);
  }

  HType intersection(HType other, Compiler compiler) {
    assert(!(isExact() && canBeNull()));
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isNull()) return canBeNull() ? HType.NULL : HType.CONFLICTING;

    if (other is HBoundedType) {
      HBoundedType temp = other;
      if (identical(this.type, temp.type)) {
        // If the types are the same, we return the [HBoundedType]
        // that has the most restrictive representation: if it's exact
        // (eg cannot be a subtype), and if it cannot be null.
        if (isExact()) {
          return this;
        } else if (other.isExact()) {
          return other;
        } else if (canBeNull()) {
          return other;
        } else {
          return this;
        }
      // If one type is a subtype of the other, we return the former,
      // which is the narrower type.
      } else if (compiler.types.isSubtype(type, other.type)) {
        return this;
      } else if (compiler.types.isSubtype(other.type, type)) {
        return other;
      }
    }
    if (other.isUnknown()) return this;
    if (other.canBeNull() && canBeNull()) return HType.NULL;
    return HType.CONFLICTING;
  }

  bool operator ==(HType other) {
    if (other is !HBoundedType) return false;
    HBoundedType bounded = other;
    return (identical(type, bounded.type)
            && identical(canBeNull(), bounded.canBeNull())
            && identical(isExact(), other.isExact()));
  }

  HType union(HType other, Compiler compiler) {
    if (other.isNull()) {
      if (canBeNull()) {
        return this;
      } else {
        return new HBoundedType.withNull(type);
      }
    }
    if (other is HBoundedType) {
      HBoundedType temp = other;
      if (!identical(type, temp.type)) return HType.UNKNOWN;
      if (isExact()) return other;
      if (other.isExact()) return this;
      return canBeNull() ? this : other;
    }
    if (other.isConflicting()) return this;
    return HType.UNKNOWN;
  }
}

class HBoundedPotentialPrimitiveType extends HBoundedType {
  const HBoundedPotentialPrimitiveType(DartType type, bool canBeNull)
      : super(type, canBeNull, false);
  bool canBePrimitive() => true;
}

class HBoundedPotentialPrimitiveNumberOrString
    extends HBoundedPotentialPrimitiveType {
  const HBoundedPotentialPrimitiveNumberOrString(DartType type, bool canBeNull)
      : super(type, canBeNull);

  HType union(HType other, Compiler compiler) {
    if (other.isNumber()) return this;
    if (other.isNumberOrNull()) {
      if (canBeNull()) return this;
      return new HBoundedPotentialPrimitiveNumberOrString(type, true);
    }

    if (other.isString()) return this;
    if (other.isStringOrNull()) {
      if (canBeNull()) return this;
      return new HBoundedPotentialPrimitiveNumberOrString(type, true);
    }

    if (other.isNull()) {
      if (canBeNull()) return this;
      return new HBoundedPotentialPrimitiveNumberOrString(type, true);
    }

    return super.union(other, compiler);
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isNumber()) return other;
    if (other.isNumberOrNull()) {
      if (!canBeNull()) return HType.NUMBER;
      return other;
    }
    if (other.isString()) return other;
    if (other.isStringOrNull()) {
      if (!canBeNull()) return HType.STRING;
      return other;
    }
    return super.intersection(other, compiler);
  }
}

class HBoundedPotentialPrimitiveArray extends HBoundedPotentialPrimitiveType {
  const HBoundedPotentialPrimitiveArray(DartType type, bool canBeNull)
      : super(type, canBeNull);

  HType union(HType other, Compiler compiler) {
    if (other.isString()) return HType.UNKNOWN;
    if (other.isReadableArray()) return this;
    // TODO(ngeoffray): implement union types.
    if (other.isIndexablePrimitive()) return HType.UNKNOWN;
    if (other.isNull()) {
      if (canBeNull()) {
        return this;
      } else {
        return new HBoundedPotentialPrimitiveArray(type, true);
      }
    }
    return super.union(other, compiler);
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isString()) return HType.CONFLICTING;
    if (other.isReadableArray()) return other;
    if (other.isIndexablePrimitive()) return HType.READABLE_ARRAY;
    return super.intersection(other, compiler);
  }
}

class HBoundedPotentialPrimitiveString extends HBoundedPotentialPrimitiveType {
  const HBoundedPotentialPrimitiveString(DartType type, bool canBeNull)
      : super(type, canBeNull);

  bool isPrimitiveOrNull() => true;

  HType union(HType other, Compiler compiler) {
    if (other.isString()) return this;
    if (other.isStringOrNull()) {
      if (canBeNull()) {
        return this;
      } else {
        return new HBoundedPotentialPrimitiveString(type, true);
      }
    }
    if (other.isNull()) {
      if (canBeNull()) {
        return this;
      } else {
        return new HBoundedPotentialPrimitiveString(type, true);
      }
    }
    // TODO(ngeoffray): implement union types.
    if (other.isIndexablePrimitive()) return HType.UNKNOWN;
    return super.union(other, compiler);
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isString()) return HType.STRING;
    if (other.isStringOrNull()) {
      return canBeNull() ? HType.STRING_OR_NULL : HType.STRING;
    }
    if (other.isReadableArray()) return HType.CONFLICTING;
    if (other.isIndexablePrimitive()) return HType.STRING;
    return super.intersection(other, compiler);
  }
}

class HTypeMap {
  Map<HInstruction, HType> _map;

  HTypeMap() : _map = new Map<HInstruction, HType>();

  operator [](HInstruction instruction) {
    HType result = _map[instruction];
    if (result == null) return instruction.guaranteedType;
    return result;
  }

  operator []=(HInstruction instruction, HType value) {
    _map[instruction] = value;
  }
}

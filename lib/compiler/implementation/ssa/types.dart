// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class HType {
  const HType();

  /**
   * Returns an [HType] that represents [type] and all types that have
   * [type] as supertype.
   */
  factory HType.fromBoundedType(Type type,
                                Compiler compiler,
                                [bool canBeNull = false]) {
    Element element = type.element;
    if (element.kind === ElementKind.TYPE_VARIABLE) {
      // TODO(ngeoffray): Replace object type with [type].
      return new HBoundedPotentialPrimitiveType(
          compiler.objectClass.computeType(compiler), canBeNull);
    }

    if (element === compiler.intClass) {
      return canBeNull ? HType.INTEGER_OR_NULL : HType.INTEGER;
    } else if (element === compiler.numClass) {
      return canBeNull ? HType.NUMBER_OR_NULL : HType.NUMBER;
    } else if (element === compiler.doubleClass) {
      return canBeNull ? HType.DOUBLE_OR_NULL : HType.DOUBLE;
    } else if (element === compiler.stringClass) {
      return canBeNull ? HType.STRING_OR_NULL : HType.STRING;
    } else if (element === compiler.boolClass) {
      return canBeNull ? HType.BOOLEAN_OR_NULL : HType.BOOLEAN;
    } else if (element === compiler.listClass
        || Elements.isListSupertype(element, compiler)) {
      return new HBoundedPotentialPrimitiveArray(type, canBeNull);
    } else if (Elements.isStringSupertype(element, compiler)) {
      return new HBoundedPotentialPrimitiveString(type, canBeNull);
    } else {
      return new HBoundedType(type, canBeNull);
    }
  }

  static final HType CONFLICTING = const HAnalysisType("conflicting");
  static final HType UNKNOWN = const HAnalysisType("unknown");
  static final HType BOOLEAN = const HBooleanType();
  static final HType NUMBER = const HNumberType();
  static final HType INTEGER = const HIntegerType();
  static final HType DOUBLE = const HDoubleType();
  static final HType INDEXABLE_PRIMITIVE = const HIndexablePrimitiveType();
  static final HType STRING = const HStringType();
  static final HType READABLE_ARRAY = const HReadableArrayType();
  static final HType MUTABLE_ARRAY = const HMutableArrayType();
  static final HType EXTENDABLE_ARRAY = const HExtendableArrayType();

  static final HType BOOLEAN_OR_NULL = const HBooleanOrNullType();
  static final HType NUMBER_OR_NULL = const HNumberOrNullType();
  static final HType INTEGER_OR_NULL = const HIntegerOrNullType();
  static final HType DOUBLE_OR_NULL = const HDoubleOrNullType();
  static final HType STRING_OR_NULL = const HStringOrNullType();

  bool isConflicting() => this === CONFLICTING;
  bool isUnknown() => this === UNKNOWN;
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
  bool isReadableArray() => false;
  bool isMutableArray() => false;
  bool isExtendableArray() => false;
  bool isPrimitive() => false;
  bool isExact() => false;

  bool canBePrimitive() => false;
  bool canBeNull() => false;

  /** A type is useful it is not unknown and not conflicting. */
  bool isUseful() => !isUnknown() && !isConflicting();
  /** Alias for isReadableArray. */
  bool isArray() => isReadableArray();

  abstract Type computeType(Compiler compiler);

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
  abstract HType intersection(HType other);

  /**
   * The union of two types is the union of its values. For example:
   *   * INTEGER.union(NUMBER) => NUMBER.
   *   * DOUBLE.union(INTEGER) => NUMBER.
   *   * MUTABLE_ARRAY.union(READABLE_ARRAY) => READABLE_ARRAY.
   *
   * When there is no predefined type to represent the union returns
   * [CONFLICTING].
   *
   * A union with [UNKNOWN] returns the non-UNKNOWN type. A union with
   * [CONFLICTING] returns [CONFLICTING].
   */
  abstract HType union(HType other);
}

/** Used to represent [HType.UNKNOWN] and [HType.CONFLICTING]. */
class HAnalysisType extends HType {
  final String name;
  const HAnalysisType(this.name);
  String toString() => name;
  bool canBePrimitive() => true;
  bool canBeNull() => true;

  Type computeType(Compiler compiler) => null;

  HType combine(HType other) {
    if (isUnknown()) return other;
    if (other.isUnknown()) return this;
    return HType.CONFLICTING;
  }

  HType union(HType other) => combine(other);
  HType intersection(HType other) => combine(other);
}

abstract class HPrimitiveType extends HType {
  const HPrimitiveType();
  bool isPrimitive() => true;
  bool canBePrimitive() => true;
}

abstract class HPrimitiveOrNullType extends HType {
  const HPrimitiveOrNullType();
  bool canBePrimitive() => true;
  bool canBeNull() => true;
}

class HBooleanOrNullType extends HPrimitiveOrNullType {
  const HBooleanOrNullType();
  String toString() => "boolean or null";
  bool isBooleanOrNull() => true;

  Type computeType(Compiler compiler) {
    return compiler.boolClass.computeType(compiler);
  }

  HType union(HType other) {
    if (other.isUnknown()) return HType.BOOLEAN_OR_NULL;
    if (other.isBooleanOrNull()) return HType.BOOLEAN_OR_NULL;
    if (other.isBoolean()) return HType.BOOLEAN_OR_NULL;
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
    if (other.isUnknown()) return HType.BOOLEAN_OR_NULL;
    if (other.isBooleanOrNull()) return HType.BOOLEAN_OR_NULL;
    if (other.isBoolean()) return HType.BOOLEAN;
    return HType.CONFLICTING;
  }
}

class HBooleanType extends HPrimitiveType {
  const HBooleanType();
  bool isBoolean() => true;
  String toString() => "boolean";

  Type computeType(Compiler compiler) {
    return compiler.boolClass.computeType(compiler);
  }

  HType union(HType other) {
    if (other.isUnknown()) return HType.BOOLEAN;
    if (other.isBoolean()) return HType.BOOLEAN;
    if (other.isBooleanOrNull()) return HType.BOOLEAN_OR_NULL;
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
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

  Type computeType(Compiler compiler) {
    return compiler.numClass.computeType(compiler);
  }

  HType union(HType other) {
    if (other.isUnknown()) return HType.NUMBER_OR_NULL;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    if (other.isNumber()) return HType.NUMBER_OR_NULL;
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
    if (other.isUnknown()) return HType.NUMBER_OR_NULL;
    if (other.isInteger()) return HType.INTEGER;
    if (other.isDouble()) return HType.DOUBLE;
    if (other.isNumber()) return HType.NUMBER;
    if (other.isIntegerOrNull()) return HType.INTEGER_OR_NULL;
    if (other.isDoubleOrNull()) return HType.DOUBLE_OR_NULL;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    return HType.CONFLICTING;
  }
}

class HNumberType extends HPrimitiveType {
  const HNumberType();
  bool isNumber() => true;
  String toString() => "number";

  Type computeType(Compiler compiler) {
    return compiler.numClass.computeType(compiler);
  }

  HType union(HType other) {
    if (other.isNumber()) return HType.NUMBER;
    if (other.isUnknown()) return HType.NUMBER;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
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

  Type computeType(Compiler compiler) {
    return compiler.intClass.computeType(compiler);
  }

  HType union(HType other) {
    if (other.isUnknown()) return HType.INTEGER_OR_NULL;
    if (other.isIntegerOrNull()) return HType.INTEGER_OR_NULL;
    if (other.isInteger()) return HType.INTEGER_OR_NULL;
    if (other.isNumber()) return HType.NUMBER_OR_NULL;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
    if (other.isUnknown()) return HType.INTEGER_OR_NULL;
    if (other.isIntegerOrNull()) return HType.INTEGER_OR_NULL;
    if (other.isInteger()) return HType.INTEGER;
    if (other.isDouble()) return HType.CONFLICTING;
    if (other.isDoubleOrNull()) return HType.CONFLICTING;
    if (other.isNumber()) return HType.INTEGER;
    if (other.isNumberOrNull()) return HType.INTEGER_OR_NULL;
    return HType.CONFLICTING;
  }
}

class HIntegerType extends HNumberType {
  const HIntegerType();
  bool isInteger() => true;
  String toString() => "integer";

  Type computeType(Compiler compiler) {
    return compiler.intClass.computeType(compiler);
  }

  HType union(HType other) {
    if (other.isUnknown()) return HType.INTEGER;
    if (other.isInteger()) return HType.INTEGER;
    if (other.isIntegerOrNull()) return HType.INTEGER_OR_NULL;
    if (other.isNumber()) return HType.NUMBER;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
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

  Type computeType(Compiler compiler) {
    return compiler.doubleClass.computeType(compiler);
  }

  HType union(HType other) {
    if (other.isUnknown()) return HType.DOUBLE_OR_NULL;
    if (other.isDoubleOrNull()) return HType.DOUBLE_OR_NULL;
    if (other.isDouble()) return HType.DOUBLE_OR_NULL;
    if (other.isNumber()) return HType.NUMBER_OR_NULL;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
    if (other.isUnknown()) return HType.DOUBLE_OR_NULL;
    if (other.isIntegerOrNull()) return HType.CONFLICTING;
    if (other.isInteger()) return HType.CONFLICTING;
    if (other.isDouble()) return HType.DOUBLE;
    if (other.isDoubleOrNull()) return HType.DOUBLE_OR_NULL;
    if (other.isNumber()) return HType.DOUBLE;
    if (other.isNumberOrNull()) return HType.DOUBLE_OR_NULL;
    return HType.CONFLICTING;
  }
}

class HDoubleType extends HNumberType {
  const HDoubleType();
  bool isDouble() => true;
  String toString() => "double";

  Type computeType(Compiler compiler) {
    return compiler.doubleClass.computeType(compiler);
  }

  HType union(HType other) {
    if (other.isUnknown()) return HType.DOUBLE;
    if (other.isDouble()) return HType.DOUBLE;
    if (other.isDoubleOrNull()) return HType.DOUBLE_OR_NULL;
    if (other.isNumber()) return HType.NUMBER;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
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

  Type computeType(Compiler compiler) {
    // TODO(ngeoffray): Represent union types.
    return null;
  }

  HType union(HType other) {
    if (other.isUnknown()) return HType.INDEXABLE_PRIMITIVE;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    if (other is HBoundedPotentialPrimitiveString) {
      // TODO(ngeoffray): Represent union types.
      return HType.CONFLICTING;
    }
    if (other is HBoundedPotentialPrimitiveArray) {
      // TODO(ngeoffray): Represent union types.
      return HType.CONFLICTING;
    }
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
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

  Type computeType(Compiler compiler) {
    return compiler.stringClass.computeType(compiler);
  }

  HType union(HType other) {
    if (other.isUnknown()) return HType.STRING_OR_NULL;
    if (other.isString()) return HType.STRING_OR_NULL;
    if (other.isStringOrNull()) return HType.STRING_OR_NULL;
    if (other.isIndexablePrimitive()) {
      // We don't have a type that represents the nullable indexable
      // primitive.
      return HType.CONFLICTING;
    }
    if (other is HBoundedPotentialPrimitiveString) {
      if (other.canBeNull()) {
        return other;
      } else {
        HBoundedType boundedType = other;
        return new HBoundedPotentialPrimitiveString(boundedType.type, true);
      }
    }
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
    if (other.isUnknown()) return HType.STRING_OR_NULL;
    if (other.isString()) return HType.STRING;
    if (other.isStringOrNull()) return HType.STRING_OR_NULL;
    if (other.isArray()) return HType.CONFLICTING;
    if (other.isIndexablePrimitive()) return HType.STRING;
    if (other is HBoundedPotentialPrimitiveString) {
      return other.canBeNull() ? HType.STRING_OR_NULL : HType.STRING;
    }
    return HType.CONFLICTING;
  }
}

class HStringType extends HIndexablePrimitiveType {
  const HStringType();
  bool isString() => true;
  String toString() => "String";

  Type computeType(Compiler compiler) {
    return compiler.stringClass.computeType(compiler);
  }

  HType union(HType other) {
    if (other.isUnknown()) return HType.STRING;
    if (other.isString()) return HType.STRING;
    if (other.isStringOrNull()) return HType.STRING_OR_NULL;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    if (other is HBoundedPotentialPrimitiveString) return other;
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
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

  Type computeType(Compiler compiler) {
    return compiler.listClass.computeType(compiler);
  }

  HType union(HType other) {
    if (other.isUnknown()) return HType.READABLE_ARRAY;
    if (other.isReadableArray()) return HType.READABLE_ARRAY;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    if (other is HBoundedPotentialPrimitiveArray) return other;
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
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

  HType union(HType other) {
    if (other.isUnknown()) return HType.MUTABLE_ARRAY;
    if (other.isMutableArray()) return HType.MUTABLE_ARRAY;
    if (other.isReadableArray()) return HType.READABLE_ARRAY;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    if (other is HBoundedPotentialPrimitiveArray) return other;
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
    if (other.isUnknown()) return HType.MUTABLE_ARRAY;
    if (other.isMutableArray()) return other;
    if (other.isString()) return HType.CONFLICTING;
    if (other.isIndexablePrimitive()) return HType.MUTABLE_ARRAY;
    if (other is HBoundedPotentialPrimitiveArray) return HType.MUTABLE_ARRAY;
    return HType.CONFLICTING;
  }
}

class HExtendableArrayType extends HMutableArrayType {
  const HExtendableArrayType();
  bool isExtendableArray() => true;
  String toString() => "extendable array";

  HType union(HType other) {
    if (other.isUnknown()) return HType.EXTENDABLE_ARRAY;
    if (other.isExtendableArray()) return HType.EXTENDABLE_ARRAY;
    if (other.isMutableArray()) return HType.MUTABLE_ARRAY;
    if (other.isReadableArray()) return HType.READABLE_ARRAY;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    if (other is HBoundedPotentialPrimitiveArray) return other;
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
    if (other.isUnknown()) return HType.EXTENDABLE_ARRAY;
    if (other.isExtendableArray()) return HType.EXTENDABLE_ARRAY;
    if (other.isString()) return HType.CONFLICTING;
    if (other.isIndexablePrimitive()) return HType.EXTENDABLE_ARRAY;
    if (other is HBoundedPotentialPrimitiveArray) return HType.EXTENDABLE_ARRAY;
    return HType.CONFLICTING;
  }
}

class HBoundedType extends HType {
  final Type type;
  final bool _canBeNull;

  bool canBeNull() => _canBeNull;

  const HBoundedType(Type this.type, [bool this._canBeNull = false]);
  String toString() => type.toString();

  Type computeType(Compiler compiler) => type;

  HType combine(HType other) {
    if (other is HBoundedType) {
      HBoundedType temp = other;
      // Return [other] in case it is an exact type.
      if (this.type === temp.type) return other;
    }
    if (other.isUnknown()) return this;
    return HType.CONFLICTING;
  }

  // As long as we don't keep track of super/sub types for non-primitive types
  // the intersection and union is the same.
  HType intersection(HType other) => combine(other);
  HType union(HType other) => combine(other);
}

class HExactType extends HBoundedType {
  const HExactType(Type type) : super(type);
  bool isExact() => true;

  Element lookupMember(SourceString name) {
    ClassElement classElement = type.element;
    return classElement.lookupMember(name);
  }

  HType combine(HType other) {
    if (other.isExact()) {
      HExactType concrete = other;
      if (this.type === concrete.type) return this;
    }
    if (other.isUnknown()) return this;
    return HType.CONFLICTING;
  }
}

class HBoundedPotentialPrimitiveType extends HBoundedType {
  const HBoundedPotentialPrimitiveType(Type type, bool canBeNull)
      : super(type, canBeNull);
  bool canBePrimitive() => true;
}

class HBoundedPotentialPrimitiveArray extends HBoundedPotentialPrimitiveType {
  const HBoundedPotentialPrimitiveArray(Type type, bool canBeNull)
      : super(type, canBeNull);

  HType union(HType other) {
    if (other.isString()) return HType.CONFLICTING;
    if (other.isReadableArray()) return this;
    // TODO(ngeoffray): implement union types.
    if (other.isIndexablePrimitive()) return HType.CONFLICTING;
    return super.union(other);
  }

  HType intersection(HType other) {
    if (other.isString()) return HType.CONFLICTING;
    if (other.isReadableArray()) return other;
    if (other.isIndexablePrimitive()) return HType.READABLE_ARRAY;
    return super.intersection(other);
  }
}

class HBoundedPotentialPrimitiveString extends HBoundedPotentialPrimitiveType {
  const HBoundedPotentialPrimitiveString(Type type, bool canBeNull)
      : super(type, canBeNull);

  HType union(HType other) {
    if (other.isString()) return this;
    if (other.isStringOrNull()) {
      if (canBeNull()) {
        return this;
      } else {
        return new HBoundedPotentialPrimitiveString(type, true);
      }
    }
    // TODO(ngeoffray): implement union types.
    if (other.isIndexablePrimitive()) return HType.CONFLICTING;
    return super.union(other);
  }

  HType intersection(HType other) {
    if (other.isString()) return HType.STRING;
    if (other.isStringOrNull()) {
      return canBeNull() ? HType.STRING_OR_NULL : HType.STRING;
    }
    if (other.isReadableArray()) return HType.CONFLICTING;
    if (other.isIndexablePrimitive()) return HType.STRING;
    return super.intersection(other);
  }
}
